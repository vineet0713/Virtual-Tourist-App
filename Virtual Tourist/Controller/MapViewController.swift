//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    // MARK: - Properties
    
    let centerAmericaLat: CLLocationDegrees = 39.8283
    let centerAmericaLong: CLLocationDegrees = -98.5795
    
    // sets the latitudinal and longitudinal distances (for setting map region)
    let latitudinalDist: CLLocationDistance = 5000000   // represents 5 million meters, or 5 thousand kilometers
    let longitudinalDist: CLLocationDistance = 5000000  // represents 5 million meters, or 5 thousand kilometers
    
    var selectedPin: PinAnnotation!
    
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
    }
    
    // MARK: - Helper Functions
    
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
            // update Core Data!
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // this the IBAction for the Long Press Gesture Recognizer
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: map)
            let coordinates = map.convert(location, toCoordinateFrom: map)
            
            FlickrClient.sharedInstance().getPhotosFromCoordinates(coordinates) { (success, error) in
                performUIUpdatesOnMain {
                    if success {
                        let annotation = PinAnnotation(title: "test", coordinate: coordinates)
                        self.map.addAnnotation(annotation)
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
                photosVC.pinLatitude = selectedPin!.coordinate.latitude
                photosVC.pinLongitude = selectedPin!.coordinate.longitude
            }
            if let placesVC = tabBarController.viewControllers![1] as? PlacesViewController {
                placesVC.pinLatitude = selectedPin!.coordinate.latitude
                placesVC.pinLongitude = selectedPin!.coordinate.longitude
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
        selectedPin = view.annotation as! PinAnnotation
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
                // update Core Data!
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
}
