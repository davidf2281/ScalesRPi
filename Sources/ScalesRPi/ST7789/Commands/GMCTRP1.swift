
import Foundation

struct GMCTRP1: ST7789ParameterizedCommand {
    static var `default`: Self { .init(Parameter.default) }
    
    let commandByte: ST7789.CommandByte = .gmctrp1
    let parameters: [GMCTRP1.Parameter]
    
    init(_ parameters: [GMCTRP1.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        
        let rawValue: UInt8
        
        static var `default`: [Self] = {
            return [
                .init(rawValue:0xD0),
                .init(rawValue:0x04),
                .init(rawValue:0x0D),
                .init(rawValue:0x11),
                .init(rawValue:0x13),
                .init(rawValue:0x2B),
                .init(rawValue:0x3F),
                .init(rawValue:0x54),
                .init(rawValue:0x4C),
                .init(rawValue:0x18),
                .init(rawValue:0x0D),
                .init(rawValue:0x0B),
                .init(rawValue:0x1F),
                .init(rawValue:0x23),
            ]
        }()
    }
}

