
import Foundation
struct VDVVRHEN: ST7789ParameterizedCommand {
    
    static var `default`: Self { .init([.default]) }
    
    let commandByte: ST7789.CommandByte = .vdvvrhen
    let parameters: [VDVVRHEN.Parameter]
    
    init(_ parameters: [VDVVRHEN.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var `default`: Self = .init(rawValue: 0x01)
        let rawValue: UInt8
    }
}

