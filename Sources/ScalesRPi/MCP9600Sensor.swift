
import Foundation
import ScalesCore
import SwiftyGPIO

class MCP9600Sensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    var id: String {
        self.name
    }
    
    let outputType: ScalesCore.SensorOutputType = .temperature(unit: .celsius)
    let location: ScalesCore.SensorLocation = .indoor(location: nil) // TODO: Set in init
    let name: String
    
    weak var delegate: (any SensorDelegate<T>)?

    private var timer: Timer?
    private let i2c: I2CInterface
    
    // I2C config
    private let deviceAddress: Int = 0x67
    private let configPointer: UInt8 = 0b00000110
    private let tCPointer: UInt8 = 0x02
    private let revisionPointer: UInt8 = 0b00100000
    
    init(i2c: I2CInterface, name: String) {
        self.i2c = i2c
        self.name = name
        
        // Write all zeroes to the config register to make sure device is powered up
        i2c.writeByte(deviceAddress, command: configPointer, value: 0b00000000)
    }
    
    func start(minUpdateInterval: TimeInterval) {
        self.timer = Timer.scheduledTimer(withTimeInterval: minUpdateInterval, repeats: true) { [weak self] timer in
            if let self {
                Task {
                    await self.delegate?.didGetReading(self.getReading())
                }
            }
        }
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
