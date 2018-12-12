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
    var selectedIndex: Int!
    var selectedPhotos: [Photo] = []
    var photosAreLoading: Bool!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    
    // MARK: - IBActions
    
    @IBAction func bottomButtonTapped(_ sender: Any) {
        if selectedPhotos.count > 0 {
            removeSelectedPhotos()
        } else {
            refresh()
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupLongPress()
        
        // makes the map "static"
        map.isZoomEnabled = false
        map.isScrollEnabled = false
        
        // the CollectionView's delegate and dataSource are set to 'self' using Storyboard
        
        photosAreLoading = false
        
        displayHint()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupMap()
        
        makeFetchRequest()
        
        if photos.count == 0 {
            refresh()
        }
        collection.reloadData()
    }
    
    // MARK: - Helper Functions
    
    func displayHint() {
        if UserDefaults.standard.bool(forKey: "hasDisplayedHintBefore") == false {
            showAlert(title: "A Quick Hint", message: "To remove an image from this collection, tap and hold on the image.", action: "Got it!")
            UserDefaults.standard.set(true, forKey: "hasDisplayedHintBefore")
            UserDefaults.standard.synchronize()
        }
    }
    
    func setupLongPress() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(press:)))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        self.collection.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    // MARK: - Selector Functions
    
    @objc func handleLongPress(press: UILongPressGestureRecognizer) {
        if press.state == .began {
            let point = press.location(in: self.collection)
            // if the user long pressed on a valid cell, then select/deselect it
            if let indexPath = self.collection.indexPathForItem(at: point) {
                if indexPath.row < photos.count {
                    let photo = photos[indexPath.row]
                    if selectedPhotos.contains(photo) {
                        selectedPhotos = selectedPhotos.filter() {
                            $0 !== photo
                        }
                    } else {
                        selectedPhotos.append(photo)
                    }
                    updateBottomButtonText()
                    collection.reloadItems(at: [indexPath])
                }
            }
        }
    }
    
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
    
    func refresh() {
        for photo in photos {
            DataController.sharedInstance().viewContext.delete(photo)
            guard DataController.sharedInstance().saveViewContext() else {
                showAlert(title: "Save Failed", message: "Unable to remove the pin.")
                return
            }
        }
        photos.removeAll()
        
        photosAreLoading = true
        collection.reloadData()
        
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
                    self.collection.reloadData()
                }
            }
        }
    }
    
    func removeSelectedPhotos() {
        for photo in selectedPhotos {
            // removes the photo instance from the photos array
            photos = photos.filter() {
                $0 !== photo
            }
            // removes the photo from Core Data
            DataController.sharedInstance().viewContext.delete(photo)
        }
        
        guard DataController.sharedInstance().saveViewContext() else {
            self.showAlert(title: "Save Failed", message: "Unable to remove the pin.")
            return
        }
        
        selectedPhotos.removeAll()
        bottomButton.setTitle("New Collection", for: .normal)
        collection.reloadData()
    }
    
    func updateBottomButtonText() {
        let buttonText = (selectedPhotos.count > 0) ? "Remove Selected Pictures" : "New Collection"
        bottomButton.setTitle(buttonText, for: .normal)
    }
    
    func showAlert(title: String, message: String, action: String = "OK") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString(action, comment: "Default action"), style: .`default`, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailVC = segue.destination as? DetailViewController {
            detailVC.photos = self.photos
            detailVC.selectedIndex = self.selectedIndex
        }
    }
    
}

// MARK: - Collection View Data Source

extension PhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if photosAreLoading && photos.count < FlickrClient.FlickrParameterValues.PerPage {
            return FlickrClient.FlickrParameterValues.PerPage
        } else {
            return photos.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collection.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        
        if photos.count > 0 && indexPath.row < photos.count {
            cell.activityIndicator.isHidden = true
            cell.activityIndicator.stopAnimating()
            
            let photo = photos[indexPath.row]
            
            if let imageData = photo.image {
                cell.photoImageView.image = UIImage(data: imageData)
            }
            
            // decides whether to blur the photo (if the user has selected the photo)
            if selectedPhotos.contains(photo) {
                cell.visualEffectView.isHidden = false
                cell.visualEffectView.effect = UIBlurEffect(style: .prominent)
            } else {
                cell.visualEffectView.isHidden = true
                cell.visualEffectView.effect = nil
            }
        } else {
            // the image for this cell still has to load!
            cell.photoImageView.image = nil
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
        }
        
        return cell
    }
    
}

// MARK: - Collection View Delegate

extension PhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        if index < photos.count && selectedPhotos.contains(photos[index]) == false {
            selectedIndex = index
            performSegue(withIdentifier: "photosToDetailSegue", sender: self)
        }
    }
    
}

// MARK: - Collection View Delegate Flow Layout

extension PhotosViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        var cellsPerRow: CGFloat
        
        let orientation = UIDevice.current.orientation
        if orientation == .portrait || orientation == .portraitUpsideDown {
            cellsPerRow = 3
        } else {
            cellsPerRow = 5
        }
        
        return CGSize(width: (width - 10) / (cellsPerRow + 1), height: (width - 10) / (cellsPerRow + 1))
    }
    
}
