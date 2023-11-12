//
//  File.swift
//  
//
//  Created by David Fearon on 12/11/2023.
//

import Foundation

struct RDDIM: ST7789ParameterizedCommand {
    static var `default`: Self { .init(Parameter.default) }
    
    let commandByte: ST7789.CommandByte = .rdddim
    let parameters: [RDDIM.Parameter]
    
    init(_ parameters: [RDDIM.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        
        let rawValue: UInt8
        
        static var `default`: [Self] = {
            return [
                .init(rawValue: 0xA4),
                .init(rawValue: 0xA1)
            ]
        }()
    }
}
