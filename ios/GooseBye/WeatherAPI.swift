//
//  WeatherAPI.swift
//  GooseBye
//
//  Created by Kishan Patel on 11/12/16.
//  Copyright © 2016 Kishan Patel. All rights reserved.
//

import Foundation

class weatherAPI {
    static let APIKey = "d5149dd136c55362108974d2d4a41e96"
    static let baseURL = URL(string: "https://api.forecast.io/forecast/")!

    static var authenticatedBaseURL: URL {
        return baseURL.appendingPathComponent(APIKey)
    }
    
}
