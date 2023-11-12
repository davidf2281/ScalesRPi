
import Foundation

struct CASET: ST7789ParameterizedCommand {
    static var full: Self { .init(Parameter.full) }
    
    let commandByte: ST7789.CommandByte = .caset
    let parameters: [CASET.Parameter]
    
    init(_ parameters: [CASET.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        
        let rawValue: UInt8
        
        // TODO: Adapt for variable screen resolution
        static var full: [Self] = {
            let fullRange = 319
            let msb = UInt8(fullRange >> 8)
            let lsb = UInt8(fullRange & 0xFF)
            return [.init(rawValue: 0x0), .init(rawValue: 0x0),
                    .init(rawValue: msb), .init(rawValue: lsb)]
        }()
    }
}
