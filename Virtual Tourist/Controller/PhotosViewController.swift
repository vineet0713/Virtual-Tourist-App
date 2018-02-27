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
    var selectedPhoto: Photo!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // makes the map "static"
        map.isZoomEnabled = false
        map.isScrollEnabled = false
        
        collection.dataSource = self
        collection.delegate = self
        
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        
        activityIndicator.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let latitude = CLLocationDegrees(pin.latitude)
        let longitude = CLLocationDegrees(pin.longitude)
        
        let regionLocation = CLLocationCoordinate2DMake(latitude, longitude)
        map.setRegion(MKCoordinateRegionMakeWithDistance(regionLocation, latitudinalDist, longitudinalDist), animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        
        map.removeAnnotations(map.annotations)
        map.addAnnotation(annotation)
        
        makeFetchRequest()
    }
    
    // MARK: - Helper Functions
    
    func makeFetchRequest() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        // order doesn't matter, so no need to use NSSortDescriptors
        fetchRequest.sortDescriptors = []
        
        if let result = try? DataController.sharedInstance().viewContext.fetch(fetchRequest) {
            photos = result
            collection.reloadData()
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
            DataController.sharedInstance().viewContext.delete(photo)
            guard DataController.sharedInstance().saveViewContext() else {
                showAlert(title: "Save Failed", message: "Unable to remove the pin.")
                return
            }
        }
        photos.removeAll()
        
        collection.reloadData()
        activityIndicator.isHidden = false
        
        FlickrClient.sharedInstance().getPhotosFromPin(pin) { (success, error) in
            performUIUpdatesOnMain {
                if success {
                    self.makeFetchRequest()
                } else {
                    self.showAlert(title: "Load Failed", message: error!)
                }
                self.activityIndicator.isHidden = true
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailVC = segue.destination as? DetailViewController {
            detailVC.titleString = selectedPhoto.title
            if let imageData = selectedPhoto.image {
                detailVC.photo = UIImage(data: imageData)
            }
        }
    }
    
}

// MARK: - Collection View Data Source

extension PhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = photos[indexPath.row]
        let cell = collection.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        
        if let imageData = photo.image {
            cell.photoImageView.image = UIImage(data: imageData)
        }
        
        return cell
    }
    
    
    
}

// MARK: - Collection View Delegate

extension PhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPhoto = photos[indexPath.row]
        performSegue(withIdentifier: "photosToDetailSegue", sender: self)
    }
    
}
