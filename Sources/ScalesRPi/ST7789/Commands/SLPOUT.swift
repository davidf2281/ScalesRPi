
import Foundation

struct SLPOUT: ST7789Command {
    let commandByte: ST7789.CommandByte = .slpout
    let postCommandDelay: TimeInterval? = 0.005
}

