
import Foundation
import ScalesCore
import SwiftyGPIO
import ScalesRPiC

final class BME280Sensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    var id: String {
        "BME280-ID\(self.slaveID)"
    }
    
    let location: ScalesCore.SensorLocation
    
    private let slaveID: Int = 0x76
    private let IDRegisterAddress: UInt8 = 0xD0
    private let resetRegisterAddress: UInt8 = 0xE0
    private let ctrlHumRegisterAddress: UInt8 = 0xF2
    private let ctrlMeasRegisterAddress: UInt8 = 0xF4
    private let temperatureReadoutBaseAddress: UInt8 = 0xFA
    private let minUpdateInterval: TimeInterval
    private let i2c: I2CInterface
    enum BME280RegisterBaseAddress: UInt8 {
        
        case digT1 = 0x88
        case digT2 = 0xBA
        case digT3 = 0x8C
        
        case digP1 = 0x8E
        case digP2 = 0x90
        case digP3 = 0x92
        case digP4 = 0x94
        case digP5 = 0x96
        case digP6 = 0x98
        case digP7 = 0x9A
        case digP8 = 0x9C
        case digP9 = 0x9E
        
        case digH1 = 0xA1
        case digH2 = 0xE1
        case digH3 = 0xE3
        case digH4 = 0xE4
        case digH5 = 0xE5
        case digH6 = 0xE7
    }
    
    struct BME280CompensationParameters {
        
        // C / Swift equivalents:
        // signed short: Int16
        // unsigned short: UInt16
        // signed char: Int8
        // unsigned char: UInt8
        
        let digT1: UInt16
        let digT2: Int16
        let digT3: Int16
    
        let digP1: UInt16
        let digP2: Int16
        let digP3: Int16
        let digP4: Int16
        let digP5: Int16
        let digP6: Int16
        let digP7: Int16
        let digP8: Int16
        let digP9: Int16
    
        let digH1: UInt8
        let digH2: Int16
        let digH3: UInt8
        let digH4: Int16
        let digH5: Int16
        let digH6: Int8
    }
    
    private(set) lazy var readings = AsyncStream<Result<[Reading<T>], Error>> { [weak self] continuation in
        
        guard let self else { return }
        
        let task = Task {
            while(Task.isNotCancelled) {
                let readingResult = self.getReadings()
                continuation.yield(readingResult)
                try await Task.sleep(for: .seconds(self.minUpdateInterval))
            }
        }
        
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
    }
    
    init(i2c: I2CInterface, location: ScalesCore.SensorLocation, minUpdateInterval: TimeInterval) {
        self.i2c = i2c
        self.location = location
        self.minUpdateInterval = minUpdateInterval
        
        i2c.writeByte(slaveID, value: IDRegisterAddress)
        let sensorID = i2c.readByte(slaveID)
        
        print("BME280 sensor id: \(sensorID)")
        
        // Reset the device:
        i2c.writeByte(slaveID, command: resetRegisterAddress, value: 0xB6)
        Thread.sleep(forTimeInterval: 1.0)
        
        // Read the calibration compensation values from device non-volatile memory
        
        // Read t1 compensation value
        let t1baseAddress: BME280RegisterBaseAddress = .digT1
        i2c.writeByte(slaveID, value: t1baseAddress.rawValue)
        let t1low = i2c.readByte(slaveID)
        let t1high = i2c.readByte(slaveID)
        
        let t1 = (UInt16(t1high) << 8) | UInt16(t1low)
        
        print("t1: \(t1) (\(t1high), \(t1low))")
        
        let altT1 = i2c.readWord(slaveID, command: t1baseAddress.rawValue)
        
        print("Alt t1: \(altT1)")
        
        let t2baseAddress: BME280RegisterBaseAddress = .digT2
        i2c.writeByte(slaveID, value: t2baseAddress.rawValue)
        let t2low = i2c.readByte(slaveID)
        let t2high = i2c.readByte(slaveID)
        
        let t2 = (Int16(bitPattern: UInt16(t2high)) << 8) | Int16(bitPattern: UInt16(t2low))
        
        print("t2: \(t2) (\(t2high), \(t2low))")
        
        let t3baseAddress: BME280RegisterBaseAddress = .digT3
        i2c.writeByte(slaveID, value: t3baseAddress.rawValue)
        let t3low = i2c.readByte(slaveID)
        let t3high = i2c.readByte(slaveID)
        
        let t3 = (Int16(bitPattern: UInt16(t3high)) << 8) | Int16(bitPattern: UInt16(t3low))
        
        print("t3: \(t3) (\(t3high), \(t3low))")
        
        // Write humidity config, which apparently must be done before writing measurement config
        let humidityConfig: UInt8 = 0 // Skip humidity measurement
        i2c.writeByte(slaveID, command: ctrlHumRegisterAddress, value: humidityConfig)
        
        // Write measurement config, which should kick off a measurement
        let ctrlMeasConfig: UInt8 = 0b01101110 // 4x temperature oversampling, 4x pressure oversample, sensor to forced mode.
        i2c.writeByte(slaveID, command: ctrlMeasRegisterAddress, value: ctrlMeasConfig)

        // Wait for measurement
        // TODO: Get rid of this
        Thread.sleep(forTimeInterval: 0.1)
        
        // Read temperature
//        i2c.writeByte(slaveID, value: temperatureReadoutBaseAddress)
        
//        let readout = i2c.readData(slaveID, command: temperatureReadoutBaseAddress)
//        
//        for (index, byte) in readout.enumerated() {
//            print("Temperature byte\(index): \(byte)")
//        }
        
//        let temperatureByte1 = i2c.readByte(slaveID) // MSB
        let temperatureByte1 = i2c.readByte(slaveID, command: temperatureReadoutBaseAddress)
        
//        i2c.writeByte(slaveID, value: temperatureReadoutBaseAddress + 1)
        let temperatureByte2 = i2c.readByte(slaveID, command: temperatureReadoutBaseAddress + 1)
        
//        i2c.writeByte(slaveID, value: temperatureReadoutBaseAddress + 2)
        let temperatureByte3 = i2c.readByte(slaveID, command: temperatureReadoutBaseAddress + 2) // LSB (top four bits only)
        
        // Temperature readout is the top 20 bits of the three bytes
        let temp20BitUnsignedRepresentation: UInt32 = (UInt32(temperatureByte1) << 13) + (UInt32(temperatureByte2) << 4) + (UInt32(temperatureByte3) >> 4)
        
        print("Raw temperature output: \(temp20BitUnsignedRepresentation)")
        
        let tFine = t_fine(Int32(temp20BitUnsignedRepresentation), t1, t2, t3)
        
        let temperature = Float(BME280_compensate_T_int32(tFine)) / 100
        
        print("Temperature, possibly: \(temperature)C")
    }
    
    private func getReadings() -> Result<[Reading<T>], Error> {
        return .success(self.sensorReadings())
    }
    
    private func sensorReadings() -> [Reading<T>] {
              
        // Set Mode[1:0] = 11 to enable force-measurement mode
        // Enable pressure, humidity, temperature
        // The humidity measurement is controlled/enabled by the osrs_h[2:0] setting
        // The pressure measurement is controlled/enabled by the osrs_p[2:0] setting
        // The temperature measurement is controlled/enabled by the osrs_t[2:0] setting
        // To read out data after a conversion, it is strongly recommended to use a burst read and not address every register individually.
        // Data readout is done by starting a burst read from 0xF7 to 0xFC (temperature and pressure) or from 0xF7 to 0xFE (temperature, pressure and humidity). The data are read out in an unsigned 20-bit format both for pressure and for temperature and in an unsigned 16-bit format for humidity. It is strongly recommended to use the BME280 API, available from Bosch Sensortec, for readout and compensation. For details on memory map and interfaces, please consult chapters 5 and 6 respectively.
        // After the uncompensated values for pressure, temperature and humidity ‘ut’, ‘up’ and ‘uh’ have been
        // read, the actual humidity, pressure and temperature needs to be calculated using the compensation
        // parameters stored in the device.
        
        return [Reading(outputType: .temperature(unit: .celsius), sensorLocation: self.location, sensorID: self.id, value: 0)]
    }
}
