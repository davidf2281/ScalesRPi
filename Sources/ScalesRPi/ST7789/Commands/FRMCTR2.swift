
import Foundation


struct FRMCTR2: ST7789ParameterizedCommand {
    static var `default`: Self { .init(Parameter.default) }
    
    let commandByte: ST7789.CommandByte = .frmctr2
    let parameters: [FRMCTR2.Parameter]
    
    init(_ parameters: [FRMCTR2.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        
        let rawValue: UInt8
        
        static var `default`: [Self] = {
            return [
                .init(rawValue:0x0C),
                .init(rawValue:0x0C),
                .init(rawValue:0x00),
                .init(rawValue:0x33),
                .init(rawValue:0x33),
            ]
        }()
    }
}
