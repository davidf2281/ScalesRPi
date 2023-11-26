
import Foundation
import ScalesCore
import SwiftyGPIO

class MCP9600Sensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    weak var delegate: (any SensorDelegate<T>)?

    private var timer: Timer?
    private let i2c: I2CInterface
    
    // I2C config
    private let deviceAddress: Int = 0x67
    private let configPointer: UInt8 = 0b00000110
    private let tCPointer: UInt8 = 0x02
    private let revisionPointer: UInt8 = 0b00100000
    
    init(i2c: I2CInterface) {
        self.i2c = i2c
        
        // Write all zeroes to the config register to make sure device is powered up
        i2c.writeByte(deviceAddress, command: configPointer, value: 0b00000000)
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if let self {
                self.delegate?.didGetReading(getReading())
            }
        }
    }
    
    private func getReading() -> Float {
        i2c.writeByte(deviceAddress, value: tCPointer)
        let temperatureWord = i2c.readWord(deviceAddress, command: tCPointer)

        let byteSwappedReading: UInt16 = UInt16(temperatureWord).byteSwapped
        let signedValue = Int16(bitPattern: byteSwappedReading)
        let finalTemperature = Float(signedValue) * 0.0625
        
        return finalTemperature
    }
}

extension Float: SensorOutput {
    public typealias T = Self
    public var stringValue: String {
        String(format: "%.1f", self)
    }
}
