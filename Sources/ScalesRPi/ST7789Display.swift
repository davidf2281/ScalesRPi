
import Foundation
import ScalesCore
import SwiftyGPIO

struct ST7789Display: ScalesCore.Display {

    private let spi: SPIInterface
    private let dc: GPIO
    private let st7789: ST7789
    let resolution = Size(width: 240, height: 320)
    let aspect: Aspect = .portrait
    
    init(spi: SPIInterface, dc: GPIO) throws {
        
        self.spi = spi
        self.dc = dc
     
        self.st7789 = ST7789(speed: 60000000, bpp: .bpp16, spi: spi, dc: dc, width: resolution.width, height: resolution.height)
        try self.st7789.initializeDisplay()
    }
    
    func showFrame(_ frameBuffer: FrameBuffer) throws {
        let packedPixels = pixelsPacked565(pixels24: frameBuffer.pixels)
        
        do {
            try self.st7789.displayBuffer(packedPixels)
        } catch {
            try self.st7789.initializeDisplay()
            throw error
        }
    }
    
    private func pixelsPacked565(pixels24: [Color24]) -> [UInt16] {
        pixels24.map { $0.packed565 }
    }
    
    enum ST7789DisplayError: Error {
        case unsupportedResolution
    }
}

protocol DisplayChipset {
    init(speed: Hz, bpp: BitsPerPixel, spi: SPIInterface, dc: GPIO, width: Int, height: Int)
}

enum BitsPerPixel: UInt8 {
    case bpp16 = 0x55
    case bpp18 = 0x66
}

typealias Hz = UInt
