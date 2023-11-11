
import Foundation

struct GCTRL: ST7789ParameterizedCommand {
    
    static var `default`: Self { .init([.default]) }
    
    let commandByte: ST7789.CommandByte = .gctrl
    let parameters: [GCTRL.Parameter]
    
    init(_ parameters: [GCTRL.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var `default`: Self = .init(rawValue: 0x14)
        let rawValue: UInt8
    }
}
