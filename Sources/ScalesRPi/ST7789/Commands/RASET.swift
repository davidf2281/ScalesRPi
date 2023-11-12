
import Foundation

struct RASET: ST7789ParameterizedCommand {
    static var full: Self { .init(Parameter.full) }
    
    let commandByte: ST7789.CommandByte = .raset
    let parameters: [RASET.Parameter]
    
    init(_ parameters: [RASET.Parameter]) {
        self.parameters = parameters
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
