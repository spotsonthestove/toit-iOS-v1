//
//  Item.swift
//  toit-iOS-v1
//
//  Created by Michael Melville on 08/01/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
