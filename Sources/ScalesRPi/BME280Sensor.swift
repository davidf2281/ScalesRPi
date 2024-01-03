
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
        case digT2 = 0x8A
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
        let t1 = i2c.readWord(slaveID, command: t1baseAddress.rawValue)
        print("t1: \(t1)")
        
        let t2baseAddress: BME280RegisterBaseAddress = .digT2
        let t2 = Int16(bitPattern: i2c.readWord(slaveID, command: t2baseAddress.rawValue))
        print("t2: \(t2)")
                
        let t3baseAddress: BME280RegisterBaseAddress = .digT3
        let t3 = Int16(bitPattern: i2c.readWord(slaveID, command: t3baseAddress.rawValue))
        print("t3: \(t3)")
        
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
        let temperatureByte1 = i2c.readByte(slaveID, command: temperatureReadoutBaseAddress) // MSB
        print("Raw temperature byte 1: \(temperatureByte1)")
        
        let temperatureByte2 = i2c.readByte(slaveID, command: temperatureReadoutBaseAddress + 1)
        print("Raw temperature byte 2: \(temperatureByte2)")

        let temperatureByte3 = i2c.readByte(slaveID, command: temperatureReadoutBaseAddress + 2) // LSB (top four bits only)
        print("Raw temperature byte 3: \(temperatureByte3)")

        // Temperature readout is the top 20 bits of the three bytes
        let temp20BitUnsignedRepresentation: UInt32 = (UInt32(temperatureByte1) << 12) | (UInt32(temperatureByte2) << 4) | (UInt32(temperatureByte3) >> 4)
        
        print("Raw temperature output: \(temp20BitUnsignedRepresentation)")
        
        let uncompData = bme280_uncomp_data(pressure: 0, temperature: temp20BitUnsignedRepresentation, humidity: 0)
        
        var calibData = bme280_calib_data(dig_t1: t1, dig_t2: t2, dig_t3: t3, dig_p1: 0, dig_p2: 0, dig_p3: 0, dig_p4: 0, dig_p5: 0, dig_p6: 0, dig_p7: 0, dig_p8: 0, dig_p9: 0, dig_h1: 0, dig_h2: 0, dig_h3: 0, dig_h4: 0, dig_h5: 0, dig_h6: 0, t_fine: 0)
        
        withUnsafePointer(to: uncompData) { uncompPtr in
            withUnsafeMutablePointer(to: &calibData) { calibDataPtr in
                let newShinyTemperature = compensate_temperature(uncompPtr, calibDataPtr)
                print("Or maybe: \(newShinyTemperature)C")
            }
        }
        
//        let newShinyTemperature = compensate_temperature(uncompData, calibData)
        
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
