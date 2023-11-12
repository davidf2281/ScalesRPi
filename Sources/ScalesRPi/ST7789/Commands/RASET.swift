
import Foundation

struct RASET: ST7789ParameterizedCommand {
    
    let commandByte: ST7789.CommandByte = .raset
    let parameters: [RASET.Parameter]
    
    init(startY: Int, endY: Int) {
        self.parameters = {
            let startMSB = UInt8(startY >> 8)
            let startLSB = UInt8(startY & 0xFF)
            let endMSB = UInt8(endY >> 8)
            let endLSB = UInt8(endY & 0xFF)
            return [.init(rawValue: startMSB), .init(rawValue: startLSB),
                    .init(rawValue: endMSB), .init(rawValue: endLSB)]
        }()
    }
    
    struct Parameter: ScalesRPi.Parameter {
        
        let rawValue: UInt8
        
        // TODO: Adapt for variable screen resolution
        static var full: [Self] = {
            let fullRange = 239
            let msb = UInt8(fullRange >> 8)
            let lsb = UInt8(fullRange & 0xFF)
            return [.init(rawValue: 0x0), .init(rawValue: 0x0),
                    .init(rawValue: msb), .init(rawValue: lsb)]
        }()
    }
}
