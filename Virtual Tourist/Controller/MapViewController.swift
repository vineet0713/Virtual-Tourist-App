//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController {
    
    // MARK: - Properties
    
    var listOfPins: [MKPointAnnotation:Pin] = [:]
    var selectedPin: Pin!
    
    var editingMode: Bool!
    var userWantsPinOnCurrentLocation: Bool! = false
    
    var locationManager: CLLocationManager!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var map: MKMapView!
    
    var doneBarButton: UIBarButtonItem!
    var locationBarButton: MKUserTrackingBarButtonItem!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        map.delegate = self
        setMapState()
        setupLocationManager()
        
        doneBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePressed))
        locationBarButton = MKUserTrackingBarButtonItem(mapView: map)
        
        editingMode = false
        updateToolbarItems()
        
        makeFetchRequest()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        makeFetchRequest()
    }
    
    // MARK: - Helper Functions
    
    func makeFetchRequest() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        // order doesn't matter, so no need to use NSSortDescriptors
        fetchRequest.sortDescriptors = []
        
        if let result = try? DataController.sharedInstance().viewContext.fetch(fetchRequest) {
            updateMap(pins: result)
        } else {
            fatalError("The fetch could not be performed.")
        }
    }
    
    func setMapState() {
        let regionCenterLat = CLLocationDegrees(UserDefaults.standard.float(forKey: "Region Center Latitude"))
        let regionCenterLong = CLLocationDegrees(UserDefaults.standard.float(forKey: "Region Center Longitude"))
        let regionSpanLatDelta = CLLocationDegrees(UserDefaults.standard.float(forKey: "Region Span Latitude Delta"))
        let regionSpanLongDelta = CLLocationDegrees(UserDefaults.standard.float(forKey: "Region Span Longitude Delta"))
        
        let regionLocation = CLLocationCoordinate2DMake(regionCenterLat, regionCenterLong)
        map.setRegion(MKCoordinateRegion.init(center: regionLocation, span: MKCoordinateSpan.init(latitudeDelta: regionSpanLatDelta, longitudeDelta: regionSpanLongDelta)), animated: true)
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func updateMap(pins: [Pin]) {
        map.removeAnnotations(map.annotations)
        listOfPins.removeAll()
        
        for pin in pins {
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            map.addAnnotation(annotation)
            
            listOfPins[annotation] = pin
        }
    }
    
    func updateToolbarItems() {
        if editingMode {
            self.title = "Edit Annotation Pins"
            
            navigationItem.leftBarButtonItem?.title = "Clear All"
            navigationItem.rightBarButtonItem = doneBarButton
        } else {
            self.title = "Virtual Tourist"
            
            navigationItem.leftBarButtonItem?.title = "Edit"
            navigationItem.rightBarButtonItem = locationBarButton
        }
    }
    
    func mapContainsPinWith(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Bool {
        for pin in listOfPins.keys {
            if latitude == pin.coordinate.latitude && longitude == pin.coordinate.longitude {
                print("will return true!")
                return true
            }
        }
        print("will return false!")
        return false
    }
    
    func addPin(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        self.map.addAnnotation(annotation)
        
        // initializes the new Pin
        let newPin = Pin(context: DataController.sharedInstance().viewContext)
        newPin.latitude = Double(coordinates.latitude)
        newPin.longitude = Double(coordinates.longitude)
        
        // tries to save the Pin to Core Data
        guard DataController.sharedInstance().saveViewContext() else {
            showAlert(title: "Save Failed", message: "Unable to save the pin.")
            return
        }
        
        listOfPins[annotation] = newPin
        
        FlickrClient.sharedInstance().getPhotoCountForPin(newPin, completionHandler: { (success, error) in
            performUIUpdatesOnMain {
                if success == false {
                    // this means that either an error happened, or there are 0 photos for these coordinates
                    self.map.removeAnnotation(annotation)
                    self.deletePin(annotationToDelete: annotation)
                    self.showAlert(title: "Load Failed", message: error!)
                }
            }
        })
    }
    
    func clearPins() {
        if listOfPins.isEmpty {
            showAlert(title: "No Pins", message: "You don't have any pins to clear.")
            return
        }
        
        var alertMessage: String!
        if listOfPins.count > 1 {
            alertMessage = "Are you sure you want to clear all \(listOfPins.count) pins and their associated photos?"
        } else {
            alertMessage = "Are you sure you want to clear the pin and its associated photos?"
        }
        
        let alert = UIAlertController(title: "Confirm Clear", message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
            performUIUpdatesOnMain {
                self.map.removeAnnotations(self.map.annotations)
            }
            // update Core Data
            for annotation in self.map.annotations {
                if let pointAnnotation = annotation as? MKPointAnnotation {
                    self.deletePin(annotationToDelete: pointAnnotation)
                } else {
                    // This is a MKUserLocation, which is also included in the map's annotations!
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func deletePin(annotationToDelete: MKPointAnnotation) {
        let pinToDelete = self.listOfPins.removeValue(forKey: annotationToDelete)
        DataController.sharedInstance().viewContext.delete(pinToDelete!)
        guard DataController.sharedInstance().saveViewContext() else {
            self.showAlert(title: "Save Failed", message: "Unable to remove the pin.")
            return
        }
    }
    
    func saveMapState() {
        let regionCenter = map.region.center
        UserDefaults.standard.set(Float(regionCenter.latitude), forKey: "Region Center Latitude")
        UserDefaults.standard.set(Float(regionCenter.longitude), forKey: "Region Center Longitude")
        
        let regionSpan = map.region.span
        UserDefaults.standard.set(Float(regionSpan.latitudeDelta), forKey: "Region Span Latitude Delta")
        UserDefaults.standard.set(Float(regionSpan.longitudeDelta), forKey: "Region Span Longitude Delta")
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - IBActions
    
    @IBAction func editOrClearPressed(_ sender: Any) {
        if editingMode {
            clearPins()
        } else {
            editingMode = !editingMode
            updateToolbarItems()
        }
    }
    
    @IBAction func wantsToAddPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began && editingMode == false {
            let location = sender.location(in: map)
            let pinCoordinates = map.convert(location, toCoordinateFrom: map)
            addPin(coordinates: pinCoordinates)
        }
    }
    
    // MARK: - Selector Functions
    
    @objc func donePressed() {
        editingMode = !editingMode
        updateToolbarItems()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? UITabBarController {
            if let photosVC = tabBarController.viewControllers![0] as? PhotosViewController {
                photosVC.pin = selectedPin
            }
            if let placesVC = tabBarController.viewControllers![1] as? PlacesViewController {
                placesVC.pin = selectedPin
            }
        }
    }
}

// MARK: - MKMapView Delegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        map.setUserTrackingMode(.none, animated: true)
        saveMapState()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if editingMode {
            let alert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to remove this pin?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .`default`, handler: { (action) in
                performUIUpdatesOnMain {
                    self.map.removeAnnotation(view.annotation!)
                }
                // update Core Data
                self.deletePin(annotationToDelete: view.annotation! as! MKPointAnnotation)
            }))
            present(alert, animated: true, completion: nil)
        } else {
            if let selectedAnnotation = view.annotation! as? MKPointAnnotation {
                selectedPin = listOfPins[selectedAnnotation]
                performSegue(withIdentifier: "pinTappedSegue", sender: self)
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // if the user wants pin on current location (in other words, user changed the tracking mode to follow)
        if userWantsPinOnCurrentLocation {
            print("userWantsPinOnCurrentLocation!")
            // if there isn't a pin on the Map for the user's location, then request to add it
            if mapContainsPinWith(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude) == false {
                let alert = UIAlertController(title: "Add Pin", message: "Do you want to add a pin to your current location?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Yes", style: .`default`, handler: { (action) in
                    self.addPin(coordinates: (self.map.userLocation.location?.coordinate)!)
                }))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        userWantsPinOnCurrentLocation = (mode == .follow)
    }
    
}
