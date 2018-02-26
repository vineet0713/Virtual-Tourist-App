//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    // MARK: - Properties
    
    let centerAmericaLat: CLLocationDegrees = 39.8283
    let centerAmericaLong: CLLocationDegrees = -98.5795
    
    // sets the latitudinal and longitudinal distances (for setting map region)
    let latitudinalDist: CLLocationDistance = 5000000   // represents 5 million meters, or 5 thousand kilometers
    let longitudinalDist: CLLocationDistance = 5000000  // represents 5 million meters, or 5 thousand kilometers
    
    var listOfPins: [PinAnnotation:Pin] = [:]
    var selectedPin: Pin!
    
    var editingMode: Bool!
        
    // MARK: - IBOutlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        map.delegate = self
        setDefaultRegion()
        
        editingMode = false
        
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
    
    func updateMap(pins: [Pin]) {
        map.removeAnnotations(map.annotations)
        
        for pin in pins {
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let annotation = PinAnnotation(title: "test", coordinate: coordinates)
            map.addAnnotation(annotation)
            
            listOfPins[annotation] = pin
        }
    }
    
    func deletePin(annotationToDelete: PinAnnotation) {
        let pinToDelete = self.listOfPins[annotationToDelete]!
        DataController.sharedInstance().viewContext.delete(pinToDelete)
        guard DataController.sharedInstance().saveViewContext() else {
            self.showAlert(title: "Save Failed", message: "Unable to remove the pin.")
            return
        }
    }
    
    func setDefaultRegion() {
        let regionLocation = CLLocationCoordinate2DMake(centerAmericaLat, centerAmericaLong)
        map.setRegion(MKCoordinateRegionMakeWithDistance(regionLocation, latitudinalDist, longitudinalDist), animated: true)
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - IBActions
    
    @IBAction func editPressed(_ sender: Any) {
        editingMode = !editingMode
        if editingMode {
            self.title = "Edit Annotation Pins"
            clearButton.isEnabled = false
            editButton.title = "Done"
            editButton.style = .done
        } else {
            self.title = "Virtual Tourist"
            clearButton.isEnabled = true
            editButton.title = "Edit"
            editButton.style = .plain
        }
    }
    
    @IBAction func clearPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Clear", message: "Are you sure you want to clear all pins and their associated photos?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
            performUIUpdatesOnMain {
                self.map.removeAnnotations(self.map.annotations)
            }
            // update Core Data
            for annotation in self.map.annotations {
                self.deletePin(annotationToDelete: annotation as! PinAnnotation)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // this the IBAction for the Long Press Gesture Recognizer
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: map)
            let coordinates = map.convert(location, toCoordinateFrom: map)
            
            // initializes the new Pin
            let newPin = Pin(context: DataController.sharedInstance().viewContext)
            newPin.latitude = Double(coordinates.latitude)
            newPin.longitude = Double(coordinates.longitude)
            
            // tries to save the Pin to Core Data
            guard DataController.sharedInstance().saveViewContext() else {
                showAlert(title: "Save Failed", message: "Unable to save the pin.")
                return
            }
            
            FlickrClient.sharedInstance().getPhotosFromPin(newPin) { (success, error) in
                performUIUpdatesOnMain {
                    if success {
                        let annotation = PinAnnotation(title: "test", coordinate: coordinates)
                        self.map.addAnnotation(annotation)
                        self.listOfPins[annotation] = newPin
                    } else {
                        self.showAlert(title: "Load Failed", message: error!)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? UITabBarController {
            if let photosVC = tabBarController.viewControllers![0] as? PhotosViewController {
                /*photosVC.pinLatitude = selectedPin!.coordinate.latitude
                photosVC.pinLongitude = selectedPin!.coordinate.longitude*/
                photosVC.pin = selectedPin
            }
            if let placesVC = tabBarController.viewControllers![1] as? PlacesViewController {
                /*placesVC.pinLatitude = selectedPin!.coordinate.latitude
                placesVC.pinLongitude = selectedPin!.coordinate.longitude*/
                placesVC.pin = selectedPin
            }
        }
    }
}

// MARK: - MKMapView Delegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotationView = map.dequeueReusableAnnotationView(withIdentifier: "dropped pin") {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "dropped pin")
            annotationView.canShowCallout = true
            
            // without adding this UIButton, the 'calloutAccessoryControlTapped' method would not get called!
            let infoButton = UIButton(type: .detailDisclosure)
            annotationView.rightCalloutAccessoryView = infoButton
            
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let selectedAnnotation = view.annotation as! PinAnnotation
        selectedPin = listOfPins[selectedAnnotation]
        performSegue(withIdentifier: "pinTappedSegue", sender: self)
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
                self.deletePin(annotationToDelete: view.annotation! as! PinAnnotation)
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
}
