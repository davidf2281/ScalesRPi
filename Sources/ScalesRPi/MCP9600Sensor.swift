
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
        
        i2c.writeByte(deviceAddress, command: configPointer, value: 0b00000000)
        
        i2c.writeByte(deviceAddress, value: revisionPointer)
        let deviceIDByte = i2c.readByte(deviceAddress)
        let deviceRevisionByte = i2c.readByte(deviceAddress)
        print("Device ID byte: \(deviceIDByte)")
        print("Device revision byte: \(deviceRevisionByte)")

    }
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if let self {
                self.delegate?.didGetReading(getReading())
            }
        }
    }
    
    private func getReading() -> Float {
        // Writing register 0 of the device with address 0x68
        i2c.writeByte(deviceAddress, value: tCPointer)
        let upperByte = i2c.readByte(deviceAddress, command: tCPointer)
        let lowerByte = i2c.readByte(deviceAddress, command: tCPointer)
        print("Upper byte: \(upperByte), lower byte: \(lowerByte)")
        let signedTempValue: Int16 = Int16((upperByte << 8) + lowerByte)
        
        let temperature: Float = Float(signedTempValue) * 0.0625
        
        return temperature
    }
    
    /*
     //Convert the temperature data
     if ((UpperByte & 0x80) == 0x80) { // Temperature < 0°C
        Temperature = (UpperByte x 16 + LowerByte / 16) - 4096;
     }  else {//Temperature >= 0°C
        Temperature = (UpperByte x 16 + LowerByte / 16);
     }
     */
}

extension Float: SensorOutput {
    public typealias T = Self
    public var stringValue: String {
        String(format: "%.1f", self)
    }
}
