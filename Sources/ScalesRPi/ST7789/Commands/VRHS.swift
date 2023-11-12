//
//  File.swift
//  
//
//  Created by David Fearon on 12/11/2023.
//

import Foundation

struct VRHS: ST7789ParameterizedCommand {
    
    static var `default`: Self { .init([.default]) }
    
    let commandByte: ST7789.CommandByte = .vrhs
    let parameters: [VRHS.Parameter]
    
    init(_ parameters: [VRHS.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var `default`: Self = .init(rawValue: 0x12)
        let rawValue: UInt8
    }
}


