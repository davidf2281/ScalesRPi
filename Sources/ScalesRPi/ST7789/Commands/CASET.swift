
import Foundation

struct CASET: ST7789ParameterizedCommand {
    
    let commandByte: ST7789.CommandByte = .caset
    let parameters: [CASET.Parameter]
    
    init(startX: Int, endX: Int) {
        self.parameters = {
            let startMSB = UInt8(startX >> 8)
            let startLSB = UInt8(startX & 0xFF)
            let endMSB = UInt8(endX >> 8)
            let endLSB = UInt8(endX & 0xFF)
            return [.init(rawValue: startMSB), .init(rawValue: startLSB),
                    .init(rawValue: endMSB), .init(rawValue: endLSB)]
        }()
    }
    
    struct Parameter: ScalesRPi.Parameter {
        
        let rawValue: UInt8
    }
}
