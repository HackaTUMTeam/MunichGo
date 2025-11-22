//
//  Hexagon.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation
import SwiftData

@Model
final class Hexagon: Hashable {
    var identifier: String
    
    init(identifier: String) {
        self.identifier = identifier
    }
}
