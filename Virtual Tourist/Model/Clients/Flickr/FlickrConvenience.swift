//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import Foundation
import MapKit

extension FlickrClient {
    
    // MARK: - Get Photos Method
    
    func getPhotosFromCoordinates(_ coordinates: CLLocationCoordinate2D, completionHandler: @escaping (_ success: Bool, _ errorDescription: String?)->Void) {
        let methodParameters = parametersFromCoordinates(coordinates)
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completionHandler(false, error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode <= 299) else {
                completionHandler(false, "Your request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                completionHandler(false, "No data was returned.")
                return
            }
            
            var parsedResult: [String:Any]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            } catch {
                completionHandler(false, "Could not parse the data as JSON.")
                return
            }
            
            // check if Flickr returned an error
            guard let flickrStatus = parsedResult[FlickrResponseKeys.Status] as? String, flickrStatus == FlickrResponseValues.OKStatus else {
                completionHandler(false, "Flickr API returned an error.")
                return
            }
            
            guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:Any] else {
                completionHandler(false, "Could not find key \(FlickrResponseKeys.Photos).")
                return
            }
            
            guard let photoArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String:Any]] else {
                completionHandler(false, "Could not find key \(FlickrResponseKeys.Photo).")
                return
            }
            
            if photoArray.count == 0 {
                completionHandler(false, "No photos were found for these coordinates.")
                return
            }
            
            print(photoArray)
            
            /*
            let photoDictionary = photoArray[randomPhotoIndex]
            
            guard let imageURLString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                print("Could not find key \(Constants.FlickrResponseKeys.MediumURL).")
                return
            }
            
            guard let imageTitleString = photoDictionary[Constants.FlickrResponseKeys.Title] as? String else {
                print("Could not find key \(Constants.FlickrResponseKeys.Title).")
                return
            }
            
            let imageURL = URL(string: imageURLString)!
            guard let imageData = try? Data(contentsOf: imageURL) else {
                print("Could not get image data.")
                return
            }
            */
            
            completionHandler(true, nil)
        }
        
        task.resume()
    }
    
}
