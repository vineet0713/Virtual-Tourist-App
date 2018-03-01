//
//  PhotosViewController.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotosViewController: UIViewController {
    
    // MARK: - Properties
    
    // sets the latitudinal and longitudinal distances (for setting map region)
    let latitudinalDist: CLLocationDistance = 5000   // represents 5 thousand meters, or 5 kilometers
    let longitudinalDist: CLLocationDistance = 5000  // represents 5 thousand meters, or 5 kilometers
    
    var pin: Pin!
    var photos: [Photo] = []
    var photosAreLoading: Bool!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collection: UICollectionView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // makes the map "static"
        map.isZoomEnabled = false
        map.isScrollEnabled = false
        
        // the CollectionView's delegate and dataSource are set to 'self' using Storyboard
        
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        
        photosAreLoading = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupMap()
        
        makeFetchRequest()
        
        if photos.count == 0 {
            refresh()
        }
    }
    
    // MARK: - Helper Functions
    
    func setupMap() {
        let latitude = CLLocationDegrees(pin.latitude)
        let longitude = CLLocationDegrees(pin.longitude)
        
        let regionLocation = CLLocationCoordinate2DMake(latitude, longitude)
        map.setRegion(MKCoordinateRegionMakeWithDistance(regionLocation, latitudinalDist, longitudinalDist), animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        
        map.removeAnnotations(map.annotations)
        map.addAnnotation(annotation)
    }
    
    func makeFetchRequest() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        // order doesn't matter, so no need to use NSSortDescriptors
        fetchRequest.sortDescriptors = []
        
        if let result = try? DataController.sharedInstance().viewContext.fetch(fetchRequest) {
            photos = result
            collection.reloadData()
            print("collection has reloaded from fetch request")
        } else {
            fatalError("The fetch could not be performed.")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Selector Functions
    
    @objc func refresh() {
        for photo in photos {
            print("for photo in photos")
            DataController.sharedInstance().viewContext.delete(photo)
            guard DataController.sharedInstance().saveViewContext() else {
                showAlert(title: "Save Failed", message: "Unable to remove the pin.")
                return
            }
        }
        print("end of for loop")
        photosAreLoading = true
        print("set photosAreLoading to \(photosAreLoading)")
        
        collection.reloadData()
        print("collection has reloaded from refresh")
        
        FlickrClient.sharedInstance().getPhotosFromPin(pin) { (success, error) in
            self.photosAreLoading = false
            performUIUpdatesOnMain {
                if success {
                    self.makeFetchRequest()
                } else {
                    self.showAlert(title: "Load Failed", message: error!)
                }
            }
        }
    }
    
}

// MARK: - Collection View Data Source

extension PhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("photos are loading: \(photosAreLoading)")
        if photosAreLoading {
            print("\(FlickrClient.FlickrParameterValues.PerPage)")
            return FlickrClient.FlickrParameterValues.PerPage
        } else {
            print("\(photos.count)")
            return photos.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cell for item at index path \(indexPath.row)")
        let cell = collection.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        
        if photosAreLoading {
            cell.photoImageView.image = nil
            cell.activityIndicator.isHidden = false
        } else {
            cell.activityIndicator.isHidden = true
            
            let photo = photos[indexPath.row]
            if let imageData = photo.image {
                cell.photoImageView.image = UIImage(data: imageData)
            }
        }
        
        return cell
    }
    
}

// MARK: - Collection View Delegate

extension PhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = photos.remove(at: indexPath.row)
        DataController.sharedInstance().viewContext.delete(photoToDelete)
        guard DataController.sharedInstance().saveViewContext() else {
            self.showAlert(title: "Save Failed", message: "Unable to remove the pin.")
            return
        }
        collection.reloadData()
    }
    
}
