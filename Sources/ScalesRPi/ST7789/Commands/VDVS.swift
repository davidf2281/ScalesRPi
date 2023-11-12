//
//  File.swift
//  
//
//  Created by David Fearon on 12/11/2023.
//

import Foundation
struct VDVS: ST7789ParameterizedCommand {
    
    static var `default`: Self { .init([.default]) }
    
    let commandByte: ST7789.CommandByte = .vdvs
    let parameters: [VDVS.Parameter]
    
    init(_ parameters: [VDVS.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var `default`: Self = .init(rawValue: 0x20)
        let rawValue: UInt8
    }
}
