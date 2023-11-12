
import Foundation

struct FRCTRL2: ST7789ParameterizedCommand {
    
    static var `default`: Self { .init([.default]) }
    
    let commandByte: ST7789.CommandByte = .frctrl2
    let parameters: [FRCTRL2.Parameter]
    
    init(_ parameters: [FRCTRL2.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var `default`: Self = .init(rawValue: 0x0F)
        let rawValue: UInt8
    }
}
