
import Foundation

protocol ST7789Command {
    var commandByte: ST7789.CommandByte { get }
    var postCommandDelay: TimeInterval? { get }
}

extension ST7789Command {
    var postCommandDelay: TimeInterval? { nil }
}
