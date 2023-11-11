
import Foundation

struct SWRESET: ST7789Command {
    let commandByte: ST7789.CommandByte = .swreset
    let postCommandDelay: TimeInterval? = 0.150
}
