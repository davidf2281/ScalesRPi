
import Foundation
import ScalesCore
import SwiftyGPIO

final class MCP9600Sensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    var id: String {
        "MCP9600-" + String(deviceAddress)
    }
    
    let outputType: ScalesCore.SensorOutputType = .temperature(unit: .celsius)
    let location: ScalesCore.SensorLocation = .indoor(location: nil) // TODO: Set in init
    
    private let i2c: I2CInterface
    private let minUpdateInterval: TimeInterval
    // I2C config
    private let deviceAddress: Int = 0x67
    private let configPointer: UInt8 = 0b00000110
    private let tCPointer: UInt8 = 0x02
    private let revisionPointer: UInt8 = 0b00100000
        
    lazy var readings = AsyncStream<T> { [weak self] continuation in
        guard let self else { return }
        
        let task = Task {
            while(true) {
                continuation.yield(self.getReading())
                try await Task.sleep(for: .seconds(self.minUpdateInterval))
            }
        }
        
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
    }
    
    init(i2c: I2CInterface, minUpdateInterval: TimeInterval) {
        self.i2c = i2c
        self.minUpdateInterval = minUpdateInterval
        
        // Write all zeroes to the config register to make sure device is powered up
        i2c.writeByte(deviceAddress, command: configPointer, value: 0b00000000)
    }
    
    private func getReading() -> Float {
        i2c.writeByte(deviceAddress, value: tCPointer)
        let temperatureWord = i2c.readWord(deviceAddress, command: tCPointer).byteSwapped
        
        // Our reading comes back as an unsigned int, but it represents
        // a signed int so we need to convert accordingly
        let signedValue = Int16(bitPattern: temperatureWord)
        
        // Default resolution of the MCP9600 is 0.0625C per lsb
        let finalTemperature = Float(signedValue) * 0.0625
        
        return finalTemperature
    }
}

extension MCP9600Sensor: Equatable {
    static func == (lhs: MCP9600Sensor, rhs: MCP9600Sensor) -> Bool {
        lhs.id == rhs.id
    }
}


extension Float: SensorOutput {
    public typealias T = Self
    public var stringValue: String {
        String(format: "%.1f", self)
    }
}
