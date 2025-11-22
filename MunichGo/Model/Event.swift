//
//  Event.swift
//  MunichGo
//
//  Created by Bent Schuetz on 22/11/25.
//
import Foundation


struct Event:Codable, Identifiable{
    let id:String
    let title:String?
    let startDate:Date
    let endDate:Date?
    let location:Location?
    let venue:String?
    let type:String?
    let reference:URL?
    let imageReference:URL?
    
    init(id: String = UUID().uuidString, title: String?, startDate: Date=Date(), endDate:Date=Date(), location: Location?=nil, venue: String?, type:String?, reference:URL?, imageReference:URL?) {
        
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.venue = venue
        self.type = type
        self.reference = reference
        self.imageReference = imageReference ?? URL(string: "https://placehold.co/500x900")!
    }
}

struct Location: Codable{
    let lat:String
    let lon:String
    let type:String?
    let name:String?
    let adresstype:String?
    let boundingbox:[String]
    let _class:String?
    let display_name:String?
    let importance:Double?
    
    init(lat: String, lon: String, type: String, name: String, adresstype: String, boundingbox: [String], _class: String, display_name: String, importance: Double) {
        self.lat = lat
        self.lon = lon
        self.type = type
        self.name = name
        self.adresstype = adresstype
        self.boundingbox = boundingbox
        self._class = _class
        self.display_name = display_name
        self.importance = importance
    }
}

