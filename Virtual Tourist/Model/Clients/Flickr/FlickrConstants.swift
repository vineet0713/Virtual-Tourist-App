//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // MARK: - Constants
    struct Constants {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    // MARK: - Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let BoundingBox = "bbox"
        static let PerPage = "per_page"
        static let SafeSearch = "safe_search"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Page = "page"
        static let orderedValues = [Method, APIKey, BoundingBox, PerPage, SafeSearch, Extras, Format, NoJSONCallback]
    }
    
    // MARK: - Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "91106059e4adb221703c6b0a1326a5ae" /* MY API KEY */
        static let GalleryID = "5704-72157622566655097"
        static let BoundingBox = "USER_VALUE"
        static let PerPage = 10
        static let UseSafeSearch = "1"
        static let MediumURL = "url_m"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let orderedValues = [SearchMethod, APIKey, BoundingBox, "\(PerPage)", UseSafeSearch, MediumURL, ResponseFormat, DisableJSONCallback]
    }
    
    // MARK: - Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: - Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
    
}
