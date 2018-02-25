//
//  PlacesViewController.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController {
    
    // MARK: - Properties
    
    var pinLatitude: CLLocationDegrees!
    var pinLongitude: CLLocationDegrees!
    
    // sets the latitudinal and longitudinal distances (for setting map region)
    let latitudinalDist: CLLocationDistance = 5000   // represents 5 thousand meters, or 5 kilometers
    let longitudinalDist: CLLocationDistance = 5000  // represents 5 thousand meters, or 5 kilometers
    
    let titlesArray = ["title 1", "title 2", "title 3", "title 4"]
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var table: UITableView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        table.dataSource = self
        table.delegate = self
        
        // makes the map "static"
        map.isZoomEnabled = false
        map.isScrollEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let regionLocation = CLLocationCoordinate2DMake(pinLatitude, pinLongitude)
        map.setRegion(MKCoordinateRegionMakeWithDistance(regionLocation, latitudinalDist, longitudinalDist), animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(pinLatitude, pinLongitude)
        map.removeAnnotations(map.annotations)
        map.addAnnotation(annotation)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
        if let detailVC = segue.destination as? DetailViewController {
            
        }
        */
    }
    
}

// MARK: - Table View Data Source

extension PlacesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titlesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! PlaceTableViewCell
        
        cell.titleLabel.text = titlesArray[indexPath.row]
        
        return cell
    }
    
}

// MARK: - Table View Delegate

extension PlacesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // set selected cell
        performSegue(withIdentifier: "placesToDetailSegue", sender: self)
    }
    
}
