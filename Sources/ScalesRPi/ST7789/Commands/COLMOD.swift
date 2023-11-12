
import Foundation

struct COLMOD: ST7789ParameterizedCommand {
        
    let commandByte: ST7789.CommandByte = .colmod
    let parameters: [COLMOD.Parameter]
    
    init(bpp: ST7789.BitsPerPixel) {
        precondition(bpp == .bpp16, "Color depths other than 16bpp not currently supported")
        self.parameters = [.init(rawValue: bpp.rawValue)]
    }
    
    struct Parameter: ScalesRPi.Parameter {
        static var bpp16: Self = .init(rawValue: 0x55)
        let rawValue: UInt8
    }
}

