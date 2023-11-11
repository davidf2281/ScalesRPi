
import Foundation

struct DISPON: ST7789Command {
    let commandByte: ST7789.CommandByte = .dispon
    // TODO: The datasheet doesn't mention the need for a delay after this command. Try without.
    let postCommandDelay: TimeInterval? = 0.1
}
