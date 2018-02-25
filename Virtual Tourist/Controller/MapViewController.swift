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
    
    // MARK: - IBActions
    
    @IBAction func editPressed(_ sender: Any) {
        editingMode = !editingMode
        if editingMode {
            self.title = "Edit Annotation Pins"
            editButton.title = "Done"
            editButton.style = .done
        } else {
            self.title = "Virtual Tourist"
            editButton.title = "Edit"
            editButton.style = .plain
        }
    }
    
    // this the IBAction for the Long Press Gesture Recognizer
    @IBAction func addPin(_ sender: Any) {
        let location = (sender as! UILongPressGestureRecognizer).location(in: map)
        let coordinates = map.convert(location, toCoordinateFrom: map)
        
        let annotation = PinAnnotation(title: "test", coordinate: coordinates)
        
        map.addAnnotation(annotation)
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
        if let mapPin = view.annotation as? PinAnnotation {
            selectedPin = mapPin
        }
        performSegue(withIdentifier: "pinTappedSegue", sender: self)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if editingMode {
            let alert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to remove this annotation pin?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .`default`, handler: { (action) in
                // TODO: removing the pin doesn't work!
                if let mapPin = view.annotation as? PinAnnotation {
                    self.map.removeAnnotation(mapPin)
                }
                // update Core Data!
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
}

