
import Foundation
import ScalesCore
import SwiftyGPIO
import ScalesRPiC

final class BME280Sensor: ScalesCore.Sensor {
    
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
    
    enum BME280RegisterAddress: UInt8 {
        case id = 0xD0
        case reset = 0xE0
        case ctrlHum = 0xF2
        case ctrlMeas = 0xF4
        case pressureData = 0xF7
        case temperatureData = 0xFA
    }
    
    typealias T = Float
    
    var id: String {
        "BME280-ID\(self.slaveID)"
    }
    
    let location: ScalesCore.SensorLocation
    
    private let slaveID: Int = 0x76
//    private let idRegisterAddress: UInt8 = 0xD0
//    private let resetRegisterAddress: UInt8 = 0xE0
//    private let ctrlHumRegisterAddress: UInt8 = 0xF2
//    private let ctrlMeasRegisterAddress: UInt8 = 0xF4
//    private let temperatureReadoutBaseAddress: UInt8 = 0xFA
    private let minUpdateInterval: TimeInterval
    private let i2c: I2CInterface
    
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
        
        i2c.writeByte(slaveID, value: BME280RegisterAddress.id.rawValue)
        let sensorID = i2c.readByte(slaveID)
        
        print("BME280 sensor id: \(sensorID)")
        
        // Reset the device:
        i2c.writeByte(slaveID, command: BME280RegisterAddress.reset.rawValue, value: 0xB6)
        Thread.sleep(forTimeInterval: 1.0)
        
        // Read the calibration compensation values from device non-volatile memory
        
        // Read pressure compensation values
        let p1baseAddress: BME280RegisterBaseAddress = .digP1
        let p1 = i2c.readWord(slaveID, command: p1baseAddress.rawValue)
        print("p1: \(p1)")
        
        let p2baseAddress: BME280RegisterBaseAddress = .digP2
        let p2 = Int16(bitPattern: i2c.readWord(slaveID, command: p2baseAddress.rawValue))
        print("p2: \(p2)")
        
        let p3baseAddress: BME280RegisterBaseAddress = .digP3
        let p3 = Int16(bitPattern: i2c.readWord(slaveID, command: p3baseAddress.rawValue))
        print("p3: \(p3)")
        
        let p4baseAddress: BME280RegisterBaseAddress = .digP4
        let p4 = Int16(bitPattern: i2c.readWord(slaveID, command: p4baseAddress.rawValue))
        print("p4: \(p4)")
        
        let p5baseAddress: BME280RegisterBaseAddress = .digP5
        let p5 = Int16(bitPattern: i2c.readWord(slaveID, command: p5baseAddress.rawValue))
        print("p5: \(p5)")
        
        let p6baseAddress: BME280RegisterBaseAddress = .digP6
        let p6 = Int16(bitPattern: i2c.readWord(slaveID, command: p6baseAddress.rawValue))
        print("p6: \(p6)")
        
        let p7baseAddress: BME280RegisterBaseAddress = .digP7
        let p7 = Int16(bitPattern: i2c.readWord(slaveID, command: p7baseAddress.rawValue))
        print("p7: \(p7)")
        
        let p8baseAddress: BME280RegisterBaseAddress = .digP8
        let p8 = Int16(bitPattern: i2c.readWord(slaveID, command: p8baseAddress.rawValue))
        print("p8: \(p8)")
        
        let p9baseAddress: BME280RegisterBaseAddress = .digP9
        let p9 = Int16(bitPattern: i2c.readWord(slaveID, command: p9baseAddress.rawValue))
        print("p9: \(p9)")
        
        // Read temperature compensation values
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
        i2c.writeByte(slaveID, command: BME280RegisterAddress.ctrlHum.rawValue, value: humidityConfig)
        
        // Write measurement config, which should kick off a measurement
        let ctrlMeasConfig: UInt8 = 0b01101110 // 4x temperature oversampling, 4x pressure oversample, sensor to forced mode.
        i2c.writeByte(slaveID, command: BME280RegisterAddress.ctrlMeas.rawValue, value: ctrlMeasConfig)

        // Wait for measurement
        // TODO: Get rid of this
        Thread.sleep(forTimeInterval: 0.1)
        
        // Read pressure
        let pressureByte1 = i2c.readByte(slaveID, command: BME280RegisterAddress.pressureData.rawValue) // MSB
        print("Raw pressure byte 1: \(pressureByte1)")
        
        let pressureByte2 = i2c.readByte(slaveID, command: BME280RegisterAddress.pressureData.rawValue + 1)
        print("Raw pressure byte 2: \(pressureByte2)")

        let pressureByte3 = i2c.readByte(slaveID, command: BME280RegisterAddress.pressureData.rawValue + 2) // LSB (top four bits only)
        print("Raw pressure byte 3: \(pressureByte3)")
        
        // Pressure readout is the top 20 bits of the three bytes
        let pressure20BitUnsignedRepresentation: UInt32 = (UInt32(pressureByte1) << 12) | (UInt32(pressureByte2) << 4) | (UInt32(pressureByte3) >> 4)
        
        // Read temperature
        let temperatureByte1 = i2c.readByte(slaveID, command: BME280RegisterAddress.temperatureData.rawValue) // MSB
        print("Raw temperature byte 1: \(temperatureByte1)")
        
        let temperatureByte2 = i2c.readByte(slaveID, command: BME280RegisterAddress.temperatureData.rawValue + 1)
        print("Raw temperature byte 2: \(temperatureByte2)")

        let temperatureByte3 = i2c.readByte(slaveID, command: BME280RegisterAddress.temperatureData.rawValue + 2) // LSB (top four bits only)
        print("Raw temperature byte 3: \(temperatureByte3)")

        // Temperature readout is the top 20 bits of the three bytes
        let temp20BitUnsignedRepresentation: UInt32 = (UInt32(temperatureByte1) << 12) | (UInt32(temperatureByte2) << 4) | (UInt32(temperatureByte3) >> 4)
        
        print("Raw temperature output: \(temp20BitUnsignedRepresentation)")
        
        let uncompData = bme280_uncomp_data(pressure: pressure20BitUnsignedRepresentation, temperature: temp20BitUnsignedRepresentation, humidity: 0)
        
        var calibData = bme280_calib_data(dig_t1: t1, dig_t2: t2, dig_t3: t3, dig_p1: p1, dig_p2: p2, dig_p3: p3, dig_p4: p4, dig_p5: p5, dig_p6: p6, dig_p7: p7, dig_p8: p8, dig_p9: p9, dig_h1: 0, dig_h2: 0, dig_h3: 0, dig_h4: 0, dig_h5: 0, dig_h6: 0, t_fine: 0)
        
        let temperatureAndPressure: (temperature: Double, pressure: Double) = withUnsafePointer(to: uncompData) { uncompPtr in
            withUnsafeMutablePointer(to: &calibData) { calibDataPtr in
                // Note: compensate_temperature() must be called before compensate_pressure()
                // because it calculates and sets t_fine in the calibData struct
                let temperature = compensate_temperature(uncompPtr, calibDataPtr)
                let pressure = compensate_pressure(uncompPtr, calibDataPtr)
                return (temperature: temperature, pressure: pressure)
            }
        }

        print("t_fine (which should be non-zero): \(calibData.t_fine)")
        print("Temperature: \(temperatureAndPressure.temperature)C")
        print("Pressure: \(temperatureAndPressure.pressure)hPa")
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
