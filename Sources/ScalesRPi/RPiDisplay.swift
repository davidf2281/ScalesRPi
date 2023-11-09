
import Foundation
import ScalesCore
import SwiftyGPIO

struct RPiDisplay: ScalesCore.Display {
    var width: Int { 320 }
    var height: Int { 240 }
    
    let spi: SPIInterface
    let dc: GPIO
    let cs: GPIO
    
    func showFrame(_ frameBuffer: FrameBuffer) {
        let packedPixels = pixelsPacked565(pixels24: frameBuffer.pixels)
        let uint8Pixels = packedPixels.map {
            let lsb: UInt8 = UInt8($0 & 0b11111111)
            let msb: UInt8 = UInt8($0 >> 8)
            return [lsb, msb]
        }.flatMap{ $0 }
        
        dc.value = 1
        cs.value = 0
        print("Sending frame over SPI (\(uint8Pixels.count) values)...")
        
        for _ in uint8Pixels {
            spi.sendData([0xFF])
        }
        
        print("...done.")
    }
    
    private func pixelsPacked565(pixels24: [Color24]) -> [UInt16] {
        pixels24.map { $0.packed565 }
    }
}
