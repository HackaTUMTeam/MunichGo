//
//  Constants.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation

enum Constants {
    static let MUNICH_LAT = 48.137154
    static let MUNICH_LON = 11.576124
    static let ZOOM_LAT = 0.08
    static let ZOOM_LON = 0.12
    
    static let CLOSE_ZOOM_LAT = 0.04
    static let CLOSE_ZOOM_LON = 0.06
    
    static let BROAD_ZOOM_LAT = 0.16
    static let BROAD_ZOOM_LON = 0.24
    
    static let DATE_FORMAT = "yyyy-mm-dd'T'HH:mm:ss"
}

enum Endpoints {
    static let host: String = "https://dee60741050d.ngrok-free.app"
    //static let port: String = "8080"
    // API ENDPOINTS where parameters can be replaced by String(format:...)
    static let ROOT = "/"
    static let TILE = "/user/%s/h3tile"
    static let USER = "/user"
    static let ACHIEVEMENT = "/user/%s/achievements"
    static let EXPERIENCE = "/user/%s/experience"
    static let EVENT = "/event"
}

