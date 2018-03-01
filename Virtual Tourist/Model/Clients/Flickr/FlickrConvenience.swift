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
        let methodParameters = generateParameters(bboxString)
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
    
    func getPhotosFromPin(_ pin: Pin, completionHandler: @escaping (_ success: Bool, _ errorDescription: String?)->Void) {
        
        // START OF BROKEN CODE
        // This code calls the 'getPhotoFromPin' function, which loads 1 randomized image from Flickr.
        // The function is called 10 times due to the for-loop.
        
//        let bboxString = getBBoxString(latitude: pin.latitude, longitude: pin.longitude)
//
//        for _ in 0..<FlickrParameterValues.PerPage {
//            getPhotoFromPin(pin, bboxString, pageNumber: nil, innerCompletionHandler: { (success, error) in
//                if success == false {
//                    print("false!")
//                    completionHandler(false, error)
//                }
//                print("iteration")
//            })
//        }
//
//        completionHandler(true, nil)
        
        // END OF BROKEN CODE
        
        // START OF WORKING CODE
        // This code loads 10 (unrandomized) images from Flickr.
        
        let bboxString = getBBoxString(latitude: pin.latitude, longitude: pin.longitude)
        let methodParameters = generateParameters(bboxString)
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

            for photo in photoArray {
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

                // initializes the new Photo
                let newPhoto = Photo(context: DataController.sharedInstance().viewContext)
                newPhoto.image = imageData
                newPhoto.title = imageTitleString
                newPhoto.pin = pin

                // tries to save the Photo to Core Data
                guard DataController.sharedInstance().saveViewContext() else {
                    completionHandler(false, "Could not save the Photo to Core Data.")
                    return
                }
            }

            completionHandler(true, nil)
        }

        task.resume()
        
        // END OF WORKING CODE
    }
    
    func getPhotoFromPin(_ pin: Pin, _ bboxString: String, pageNumber: Int?, innerCompletionHandler: @escaping (_ success: Bool, _ errorDescription: String?)->Void) {
        var methodParameters = generateParameters(bboxString)
        if pageNumber != nil {
            methodParameters[FlickrParameterKeys.Page] = pageNumber
        }
        
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                innerCompletionHandler(false, error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode <= 299) else {
                innerCompletionHandler(false, "Your request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                innerCompletionHandler(false, "No data was returned.")
                return
            }
            
            var parsedResult: [String:Any]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            } catch {
                innerCompletionHandler(false, "Could not parse the data as JSON.")
                return
            }
            
            // check if Flickr returned an error
            guard let flickrStatus = parsedResult[FlickrResponseKeys.Status] as? String, flickrStatus == FlickrResponseValues.OKStatus else {
                innerCompletionHandler(false, "Flickr API returned an error.")
                return
            }
            
            guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:Any] else {
                innerCompletionHandler(false, "Could not find key \(FlickrResponseKeys.Photos).")
                return
            }
            
            if pageNumber == nil {
                guard let pages = photosDictionary[FlickrResponseKeys.Pages] as? Int else {
                    innerCompletionHandler(false, "Could not find key \(FlickrResponseKeys.Pages).")
                    return
                }
                
                // because Twitter's API only allows us to choose from the first 40 pages:
                let truncatedPages = min(pages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(truncatedPages)))
                self.getPhotoFromPin(pin, bboxString, pageNumber: randomPage, innerCompletionHandler: innerCompletionHandler)
            } else {
                guard let photoArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String:Any]] else {
                    innerCompletionHandler(false, "Could not find key \(FlickrResponseKeys.Photo).")
                    return
                }
                
                if photoArray.count == 0 {
                    innerCompletionHandler(false, "No photos were found for these coordinates.")
                    return
                }
                
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                
                let photo = photoArray[randomPhotoIndex]
                
                guard let imageURLString = photo[FlickrResponseKeys.MediumURL] as? String else {
                    innerCompletionHandler(false, "Could not find key \(FlickrResponseKeys.MediumURL).")
                    return
                }
                
                guard let imageTitleString = photo[FlickrResponseKeys.Title] as? String else {
                    innerCompletionHandler(false, "Could not find key \(FlickrResponseKeys.Title).")
                    return
                }
                
                let imageURL = URL(string: imageURLString)!
                guard let imageData = try? Data(contentsOf: imageURL) else {
                    innerCompletionHandler(false, "Could not get image data.")
                    return
                }
                
                // initializes the new Photo
                let newPhoto = Photo(context: DataController.sharedInstance().viewContext)
                newPhoto.image = imageData
                newPhoto.title = imageTitleString
                newPhoto.pin = pin
                
                // tries to save the Photo to Core Data
                guard DataController.sharedInstance().saveViewContext() else {
                    innerCompletionHandler(false, "Could not save the Photo to Core Data.")
                    return
                }
                
                innerCompletionHandler(true, nil)
            }
        }
        
        task.resume()
    }
    
}
