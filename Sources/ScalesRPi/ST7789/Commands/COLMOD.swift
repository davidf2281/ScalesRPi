
import Foundation

struct COLMOD: ST7789ParameterizedCommand {
    
    static var bpp16: Self { .init([.bpp16]) }
    
    let commandByte: ST7789.CommandByte = .colmod
    let parameters: [COLMOD.Parameter]
    
    init(_ parameters: [COLMOD.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var bpp16: Self = .init(rawValue: 0x55)
        let rawValue: UInt8
    }
}

