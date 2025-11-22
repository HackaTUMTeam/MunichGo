//
//  LocationService.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//

import SwiftyH3

var Cells: Set<H3Cell> = []

func updateCells(lat: Double, lng: Double){
    guard let cell = try? h3FromPos(lat: lat, lng: lng) else {
        return
    }
    Cells.insert(cell)
}
