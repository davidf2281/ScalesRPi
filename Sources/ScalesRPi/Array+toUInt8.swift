//
//  File.swift
//  
//
//  Created by David Fearon on 11/11/2023.
//

import Foundation

extension Array where Element == UInt16 {
    var toUInt8: [UInt8] {
        self.flatMap {
            let lsb: UInt8 = UInt8($0 & 0b11111111)
            let msb: UInt8 = UInt8($0 >> 8)
            return [msb, lsb]
        }
    }
}
