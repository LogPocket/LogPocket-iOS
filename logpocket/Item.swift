//
//  Item.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
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
