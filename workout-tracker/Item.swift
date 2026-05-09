//
//  Item.swift
//  workout-tracker
//
//  Created by Sedat Bilece on 9.05.2026.
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
