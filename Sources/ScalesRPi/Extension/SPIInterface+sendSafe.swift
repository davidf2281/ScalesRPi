
import Foundation
import SwiftyGPIO

extension SPIInterface {
        
    func send(safe bytes: [UInt16], speed: Hz) {
        send(safe: bytes.toUInt8, speed: speed)
    }
    
    func send(safe bytes: [UInt8], speed: Hz) {
        
        // TODO: Get system SPI's maximum message length instead of assuming 4096 bytes
        let maxMessageLength = 4096

        for chunk in bytes.split(maxMessageLength) {
            self.sendData(chunk, frequencyHz: speed)
        }
    }
}
