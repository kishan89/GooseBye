//
//  Mission.swift
//  GooseBye
//
//  Created by Kishan Patel on 11/11/16.
//  Copyright © 2016 Kishan Patel. All rights reserved.
//

import UIKit
import MapKit

class Mission: NSObject, NSCoding {
    
    var name: String?
    var sensitivity: String?
    var rect: CGRect?
    
    var latitude: Double?
    var longitude: Double?
    
    var deltaLatitude: Double?
    var deltaLongitude: Double?
    
    var x1: Double?
    var y1: Double?
    
    var x2: Double?
    var y2: Double?
    
    var angle: Double?
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("missions")
    
    struct PropertyKey {
        static let nameKey = "name"
        static let sensitivityKey = "sensitivity"
        static let rectKey = "rect"
        static let latitudeKey = "latitude"
        static let longitudeKey = "longitude"
        static let deltaLatitudeKey = "deltaLatitude"
        static let deltaLongitudeKey = "deltaLongitude"
        static let x1Key = "x1"
        static let y1Key = "y1"
        static let x2Key = "x2"
        static let y2Key = "y2"
        static let angleKey = "angle"
    }
    
    init?(name: String?, sensitivity: String?, rect: CGRect?, latitude: Double?, longitude: Double?, deltaLatitude: Double?, deltaLongitude: Double?, x1: Double?, y1: Double?, x2: Double?, y2: Double?, angle: Double?) {
        self.name = name
        self.sensitivity = sensitivity
        self.rect = rect
        self.latitude = latitude
        self.longitude = longitude
        self.deltaLatitude = deltaLatitude
        self.deltaLongitude = deltaLongitude
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.angle = angle
        super.init()
        
//        if (name.isEmpty) || (sensitivity.isEmpty) {
//            return nil
//        }
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(sensitivity, forKey: PropertyKey.sensitivityKey)
        aCoder.encode(rect, forKey: PropertyKey.rectKey)
        aCoder.encode(latitude, forKey: PropertyKey.latitudeKey)
        aCoder.encode(longitude, forKey: PropertyKey.longitudeKey)
        aCoder.encode(deltaLatitude, forKey: PropertyKey.deltaLatitudeKey)
        aCoder.encode(deltaLongitude, forKey: PropertyKey.deltaLongitudeKey)
        aCoder.encode(x1, forKey: PropertyKey.x1Key)
        aCoder.encode(y1, forKey: PropertyKey.y1Key)
        aCoder.encode(x2, forKey: PropertyKey.x2Key)
        aCoder.encode(y2, forKey: PropertyKey.y2Key)
        aCoder.encode(angle, forKey: PropertyKey.angleKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as? String
        let sensitivity = aDecoder.decodeObject(forKey: PropertyKey.sensitivityKey) as? String
        let rect = aDecoder.decodeObject(forKey: PropertyKey.rectKey) as? CGRect
        let latitude = aDecoder.decodeObject(forKey: PropertyKey.latitudeKey) as? Double
        let longitude = aDecoder.decodeObject(forKey: PropertyKey.longitudeKey) as? Double
        let deltaLatitude = aDecoder.decodeObject(forKey: PropertyKey.deltaLatitudeKey) as? Double
        let deltaLongitude = aDecoder.decodeObject(forKey: PropertyKey.deltaLongitudeKey) as? Double
        let x1 = aDecoder.decodeObject(forKey: PropertyKey.x1Key) as? Double
        let y1 = aDecoder.decodeObject(forKey: PropertyKey.y1Key) as? Double
        let x2 = aDecoder.decodeObject(forKey: PropertyKey.x2Key) as? Double
        let y2 = aDecoder.decodeObject(forKey: PropertyKey.y2Key) as? Double
        let angle = aDecoder.decodeObject(forKey: PropertyKey.angleKey) as? Double


        self.init(name: name, sensitivity: sensitivity, rect: rect, latitude: latitude, longitude: longitude, deltaLatitude: deltaLatitude, deltaLongitude: deltaLongitude, x1: x1, y1: y1, x2: x2, y2: y2, angle: angle)
    }
}


