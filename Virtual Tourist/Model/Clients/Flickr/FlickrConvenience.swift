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
    
    // MARK: - Get Photo Count Method
    
    func getPhotoCountForPin(_ pin: Pin, completionHandler: @escaping (_ success: Bool, _ errorDescription: String?)->Void) {
        let bboxString = getBBoxString(latitude: pin.latitude, longitude: pin.longitude)
        let methodParameters = generateParameters(with: bboxString)
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
            
            completionHandler(true, nil)
        }
        
        task.resume()
    }
    
    // MARK: - Get Photos Method
    
    func getPhotoFromPin(_ pin: Pin, completionHandler: @escaping (_ success: Bool, _ errorDescription: String?)->Void) {
        let bboxString = getBBoxString(latitude: pin.latitude, longitude: pin.longitude)
        let methodParameters = generateParameters(with: bboxString)
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
            
            let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let photo = photoArray[randomIndex]
            
            guard let imageURLString = photo[FlickrResponseKeys.MediumURL] as? String else {
                completionHandler(false, "Could not find key \(FlickrResponseKeys.MediumURL).")
                return
            }
            
            guard let imageTitleString = photo[FlickrResponseKeys.Title] as? String else {
                completionHandler(false, "Could not find key \(FlickrResponseKeys.Title).")
                return
            }
            
            let imageURL = URL(string: imageURLString)!
            guard let imageData = try? Data(contentsOf: imageURL) else {
                completionHandler(false, "Could not get image data.")
                return
            }
            
            let pinId = pin.objectID
            DataController.sharedInstance().backgroundContext.perform {
                // should not access any UI elements, since UIKit is NOT thread-safe!
                
                // initializes the new Photo
                let newPhoto = Photo(context: DataController.sharedInstance().backgroundContext)
                newPhoto.image = imageData
                newPhoto.title = imageTitleString
                
                // since we can't access any objects associated with viewContext in this perform block (like pin),
                // we need a matching Pin instance associated with the BACKGROUND context
                let backgroundPin = DataController.sharedInstance().backgroundContext.object(with: pinId) as! Pin
                newPhoto.pin = backgroundPin
                
                // tries to save the Photo to Core Data
                guard DataController.sharedInstance().saveBackgroundContext() else {
                    completionHandler(false, "Could not save the Photo to Core Data.")
                    return
                }
            }
            
            completionHandler(true, nil)
        }
        
        task.resume()
    }
    
}
