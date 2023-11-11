
import Foundation

protocol ST7789ParameterizedCommand: ST7789Command {
    associatedtype T: ScalesRPi.Parameter
    var parameters: [T] { get }
}

protocol Parameter: OptionSet {
    var rawValue: UInt8 { get }
}

extension Array<ScalesRPi.Parameter> {
    var asBytes: [UInt8] {
        self.map { $0.rawValue }
    }
}
