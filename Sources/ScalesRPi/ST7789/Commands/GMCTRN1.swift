
import Foundation

struct GMCTRN1: ST7789ParameterizedCommand {
    static var `default`: Self { .init(Parameter.default) }
    
    let commandByte: ST7789.CommandByte = .gmctrn1
    let parameters: [GMCTRN1.Parameter]
    
    init(_ parameters: [GMCTRN1.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        
        let rawValue: UInt8
        
        static var `default`: [Self] = {
            return [
                .init(rawValue:0xD0),
                .init(rawValue:0x04),
                .init(rawValue:0x0C),
                .init(rawValue:0x11),
                .init(rawValue:0x13),
                .init(rawValue:0x2C),
                .init(rawValue:0x3F),
                .init(rawValue:0x44),
                .init(rawValue:0x51),
                .init(rawValue:0x2F),
                .init(rawValue:0x1F),
                .init(rawValue:0x1F),
                .init(rawValue:0x20),
                .init(rawValue:0x23),
            ]
        }()
    }
}
