//
//  File.swift
//  
//
//  Created by David Fearon on 11/11/2023.
//

import Foundation
import SwiftyGPIO

enum Level: Int {
    case low = 0
    case high = 1
}

extension GPIO {
    var level: Level {
        get { Level(rawValue: self.value)! }
        set { self.value = newValue.rawValue }
    }
}
