//
//  PlacesViewController.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PlacesViewController: UIViewController {
    
    // MARK: - Properties
    
    // sets the latitudinal and longitudinal distances (for setting map region)
    let latitudinalDist: CLLocationDistance = 5000   // represents 5 thousand meters, or 5 kilometers
    let longitudinalDist: CLLocationDistance = 5000  // represents 5 thousand meters, or 5 kilometers
    
    var pin: Pin!
    var photos: [Photo] = []
    var selectedPhoto: Photo!
    var photosAreLoading: Bool!
    
    var refreshControl: UIRefreshControl!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var table: UITableView!
    
    // MARK: - IBActions
    
    @IBAction func refreshTapped(_ sender: Any) {
        refresh()
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // makes the map "static"
        map.isZoomEnabled = false
        map.isScrollEnabled = false
        
        // the CollectionView's delegate and dataSource are set to 'self' using Storyboard
                
        setupRefreshControl()
        
        photosAreLoading = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupMap()
        
        makeFetchRequest()
        
        if photos.count == 0 {
            refresh()
        }
        table.reloadData()
    }
    
    // MARK: - Helper Functions
    
    func setupMap() {
        let latitude = CLLocationDegrees(pin.latitude)
        let longitude = CLLocationDegrees(pin.longitude)
        
        let regionLocation = CLLocationCoordinate2DMake(latitude, longitude)
        map.setRegion(MKCoordinateRegion.init(center: regionLocation, latitudinalMeters: latitudinalDist, longitudinalMeters: longitudinalDist), animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        
        map.removeAnnotations(map.annotations)
        map.addAnnotation(annotation)
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        table.addSubview(refreshControl)
    }
    
    func makeFetchRequest() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        // order doesn't matter, so no need to use NSSortDescriptors
        fetchRequest.sortDescriptors = []
        
        if let result = try? DataController.sharedInstance().viewContext.fetch(fetchRequest) {
            photos = result
        } else {
            fatalError("The fetch could not be performed.")
        }
    }
    
    @objc func refresh() {
        for photo in photos {
            DataController.sharedInstance().viewContext.delete(photo)
            guard DataController.sharedInstance().saveViewContext() else {
                showAlert(title: "Save Failed", message: "Unable to remove the pin.")
                return
            }
        }
        photos.removeAll()
        
        photosAreLoading = true
        table.reloadData()
        
        for count in 0..<FlickrClient.FlickrParameterValues.PerPage {
            FlickrClient.sharedInstance().getPhotoFromPin(pin) { (success, error) in
                performUIUpdatesOnMain {
                    if success {
                        self.makeFetchRequest()
                    } else {
                        self.showAlert(title: "Load Failed", message: error!)
                    }
                    if count == FlickrClient.FlickrParameterValues.PerPage - 1 {
                        self.photosAreLoading = false
                    }
                    self.table.reloadData()
                }
            }
        }
        
        photosAreLoading = false
        refreshControl.endRefreshing()
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: nil))
        self.present(alert, animated: true, completion: nil)
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

// MARK: - Table View Data Source

extension PlacesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if photosAreLoading && photos.count < FlickrClient.FlickrParameterValues.PerPage {
            return FlickrClient.FlickrParameterValues.PerPage
        } else {
            return photos.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! PlaceTableViewCell
        
        if photos.count > 0 && indexPath.row < photos.count  {
            let photo = photos[indexPath.row]
            if photo.title == "" {
                cell.titleLabel.text = "[untitled]"
            } else {
                cell.titleLabel.text = photo.title
            }
        } else {
            cell.titleLabel.text = " "
        }
        
        return cell
    }
    
}

// MARK: - Table View Delegate

extension PlacesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < photos.count {
            table.deselectRow(at: indexPath, animated: false)
            selectedPhoto = photos[indexPath.row]
            performSegue(withIdentifier: "placesToDetailSegue", sender: self)
        }
    }
    
}
