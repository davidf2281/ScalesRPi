//
//  File.swift
//  
//
//  Created by David Fearon on 12/11/2023.
//

import Foundation

struct LCMCTRL: ST7789ParameterizedCommand {
    
    static var `default`: Self { .init([.default]) }
    
    let commandByte: ST7789.CommandByte = .lcmctrl
    let parameters: [LCMCTRL.Parameter]
    
    init(_ parameters: [LCMCTRL.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var `default`: Self = .init(rawValue: 0x2C)
        let rawValue: UInt8
    }
}

