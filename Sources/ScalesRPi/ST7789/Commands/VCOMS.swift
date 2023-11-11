
import Foundation

struct VCOMS: ST7789ParameterizedCommand {
    
    static var v1475: Self { .init([.v1475]) }
    
    let commandByte: ST7789.CommandByte = .vcoms
    let parameters: [VCOMS.Parameter]
    
    init(_ parameters: [VCOMS.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var v1475: Self = .init(rawValue: 0x37)
        let rawValue: UInt8
    }
}
