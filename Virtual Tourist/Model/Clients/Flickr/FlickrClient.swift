//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import Foundation
import MapKit

class FlickrClient: NSObject {
    
    // shared session
    var session = URLSession.shared
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: Helper Functions
    
    func getBBoxString(latitude: Double, longitude: Double) -> String {
        var bboxArray: [String] = []
        bboxArray.append("\(max(longitude - Constants.SearchBBoxHalfHeight, Constants.SearchLonRange.0))")
        bboxArray.append("\(max(latitude - Constants.SearchBBoxHalfWidth, Constants.SearchLatRange.0))")
        bboxArray.append("\(min(longitude + Constants.SearchBBoxHalfHeight, Constants.SearchLonRange.1))")
        bboxArray.append("\(min(latitude + Constants.SearchBBoxHalfWidth, Constants.SearchLatRange.1))")
        
        return bboxArray.joined(separator: ",")
    }
    
    func parametersFromCoordinates(_ coordinates: CLLocationCoordinate2D) -> [String:Any] {
        var methodParameters: [String:Any] = [:]
        
        let parameterKeys = FlickrParameterKeys.orderedValues
        let parameterValues = FlickrParameterValues.orderedValues
        
        for i in 0..<parameterKeys.count {
            if parameterValues[i] == "USER_VALUE" {
                methodParameters[parameterKeys[i]] = getBBoxString(latitude: Double(coordinates.latitude), longitude: Double(coordinates.longitude))
            } else {
                methodParameters[parameterKeys[i]] = parameterValues[i]
            }
        }
        
        return methodParameters
    }
    
    func flickrURLFromParameters(_ parameters: [String:Any]) -> URL {
        var components = URLComponents()
        components.scheme = Constants.APIScheme
        components.host = Constants.APIHost
        components.path = Constants.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
}
