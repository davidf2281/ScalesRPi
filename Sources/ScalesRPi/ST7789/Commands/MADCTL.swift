
import Foundation

struct MADCTL: ST7789ParameterizedCommand {
    
    static var `default`: Self { .init([.default]) }
    
    let commandByte: ST7789.CommandByte = .madctl
    let parameters: [MADCTL.Parameter]
    
    init(_ parameters: [MADCTL.Parameter]) {
        self.parameters = parameters
    }
    
    struct Parameter: ScalesRPi.Parameter {
        
        static var `default`: Self = .init(rawValue: 0x70)
        
        let rawValue: UInt8
        
        static let my =  Parameter(rawValue: 1 << 7) // Page Address Order
        static let mx =  Parameter(rawValue: 1 << 6) // Column Address Order
        static let mv =  Parameter(rawValue: 1 << 5) // Page/Column Order
        static let ml =  Parameter(rawValue: 1 << 4) // Line Address Order
        static let rgb = Parameter(rawValue: 1 << 3) // RGB/BGR Order
        static let mh =  Parameter(rawValue: 1 << 2) // Display Data Latch Order
    }
}
