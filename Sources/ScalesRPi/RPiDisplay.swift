
import Foundation
import ScalesCore
import SwiftyGPIO

struct RPiDisplay: ScalesCore.Display {
    let width: Int = 320
    let height: Int = 240
    
    private let spi: SPIInterface
    private let dc: GPIO
    private let st7789: ST7789
    
    init(spi: SPIInterface, dc: GPIO) {
        self.spi = spi
        self.dc = dc
        self.st7789 = ST7789(speed: 1000000, bpp: .bpp16, spi: spi, dc: dc, width: width, height: height)
        self.st7789.initializeDisplay()
    }
    
    func showFrame(_ frameBuffer: FrameBuffer) {
        let packedPixels = pixelsPacked565(pixels24: frameBuffer.pixels)
        
        var testBuffer: [UInt16] = .init(repeating: 0, count: 76800)
        testBuffer[38400] = 0xFF
        self.st7789.displayBuffer(testBuffer)
    }
    
    private func pixelsPacked565(pixels24: [Color24]) -> [UInt16] {
        pixels24.map { $0.packed565 }
    }
}
