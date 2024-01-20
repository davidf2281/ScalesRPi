
import Foundation
import ScalesCore
import SwiftyGPIO
import ScalesRPiC

final class BME280Sensor: ScalesCore.Sensor {
    
    enum DeviceAddress: Int {
        case low = 0x76
        case high = 0x77
    }
    
    enum ReadError: Error {
        case readSensorFailed
    }
    
    enum ControlRegisterAddress: UInt8 {
        case deviceID = 0xD0
        case reset = 0xE0
        case ctrlHum = 0xF2
        case ctrlMeas = 0xF4
    }
    
    enum CalibrationRegisterBaseAddress: UInt8 {
        
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
    
    enum DataRegisterAddress: UInt8 {
        case pressureData = 0xF7
        case temperatureData = 0xFA
        case humidityData = 0xFD
    }
    
    typealias T = Float
    
    var id: String {
        "BME280-ID\(self.slaveID)"
    }
    
    let location: ScalesCore.SensorLocation
    
    private let slaveID: Int
    private let minUpdateInterval: TimeInterval
    private let i2c: I2CInterface
    private var calibrationData: bme280_calib_data // var because t_fine needs be mutable
    private let logger = Logger(name: "BME280")
    
    private(set) lazy var readings = AsyncStream<Result<[Reading<T>], Error>> { [weak self] continuation in
        
        guard let self else { return }
        
        let task = Task {
            while(Task.isNotCancelled) {
                let readingResult = await self.getReadings()
                continuation.yield(readingResult)
                try await Task.sleep(for: .seconds(self.minUpdateInterval))
            }
        }
        
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
    }
    
    init(i2c: I2CInterface, deviceAddress: DeviceAddress = .low, location: ScalesCore.SensorLocation, minUpdateInterval: TimeInterval) throws {
        self.i2c = i2c
        self.slaveID = deviceAddress.rawValue
        self.location = location
        self.minUpdateInterval = minUpdateInterval
        try Self.resetDevice(i2c: i2c, slaveID: slaveID)
        self.calibrationData = try Self.readCalibrationData(i2c: i2c, slaveID: slaveID)
    }
    
    private static func resetDevice(i2c: I2CInterface, slaveID: Int) throws {
        try i2c.writeByte(slaveID, command: ControlRegisterAddress.reset.rawValue, value: 0xB6)
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    private static func readCalibrationData(i2c: I2CInterface, slaveID: Int) throws -> bme280_calib_data {
        let logger = Logger(name: "BME 280 calib")
        // Read temperature compensation values
        let t1 = try i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digT1.rawValue)
        logger.log("T1 as currently used: \(t1)")
        let t1_1 = try i2c.readByte(slaveID, command: CalibrationRegisterBaseAddress.digT1.rawValue)
        let t1_2 = try i2c.readByte(slaveID, command: CalibrationRegisterBaseAddress.digT1.rawValue + 1)
        logger.log("0x88: \(t1_1), 0x89: \(t1_2)")
        logger.log("t1 assuming 0x88 is LSB: \( (UInt32(t1_2) << 8) | UInt32(t1_1) )")
        logger.log("t1 assuming 0x88 is MSB: \( (UInt32(t1_1) << 8) | UInt32(t1_2) )")

        let t2 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digT2.rawValue))
        let t3 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digT3.rawValue))
        
        // Read pressure compensation values
        let p1 = try i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP1.rawValue)
        let p2 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP2.rawValue))
        let p3 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP3.rawValue))
        let p4 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP4.rawValue))
        let p5 = try Int16(bitPattern: i2c.readWord(slaveID, command:  CalibrationRegisterBaseAddress.digP5.rawValue))
        let p6 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP6.rawValue))
        let p7 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP7.rawValue))
        let p8 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP8.rawValue))
        let p9 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP9.rawValue))
        
        // Read humidity compensation values
        let h1 = try i2c.readByte(slaveID, command: CalibrationRegisterBaseAddress.digH1.rawValue)
        let h2 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digH2.rawValue))
        let h3 = try i2c.readByte(slaveID, command: CalibrationRegisterBaseAddress.digH3.rawValue)
        // h4 is bits 11-4 of base address, bits 3:0 of base address + 1
        let h4 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digH4.rawValue))
        let h5 = try Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digH5.rawValue))
        let h6 = try Int8(bitPattern:i2c.readByte(slaveID, command: CalibrationRegisterBaseAddress.digH6.rawValue))
        
        return bme280_calib_data(dig_t1: t1,
                                 dig_t2: t2,
                                 dig_t3: t3,
                                 dig_p1: p1,
                                 dig_p2: p2,
                                 dig_p3: p3,
                                 dig_p4: p4,
                                 dig_p5: p5,
                                 dig_p6: p6,
                                 dig_p7: p7,
                                 dig_p8: p8,
                                 dig_p9: p9,
                                 dig_h1: h1,
                                 dig_h2: h2,
                                 dig_h3: h3,
                                 dig_h4: h4,
                                 dig_h5: h5,
                                 dig_h6: h6,
                                 t_fine: 0)
    }
    
    private func getReadings() async -> Result<[Reading<T>], Error> {
        do {
            let readings = try await self.sensorReadings()
            return .success(readings)
        } catch {
            return .failure(ReadError.readSensorFailed)
        }
    }
    
    private func sensorReadings() async throws -> [Reading<T>] {
              
        // Write humidity config, which acccording to the BME280 datasheet must be done before writing measurement config
        let humidityConfig: UInt8 = 0b011 // 4x humidity oversampling
        try i2c.writeByte(slaveID, command: ControlRegisterAddress.ctrlHum.rawValue, value: humidityConfig)
        
        // Write measurement config to put the device into forced mode, which will start a measurement
        let ctrlMeasConfig: UInt8 = 0b01101110 // 4x temperature oversampling, 4x pressure oversample, sensor to forced mode.
        try i2c.writeByte(slaveID, command: ControlRegisterAddress.ctrlMeas.rawValue, value: ctrlMeasConfig)
        
        // Wait for measurement
        try await Task.sleep(for: .milliseconds(100))
        
        // Read pressure
        let pressureByte1 = try i2c.readByte(slaveID, command: DataRegisterAddress.pressureData.rawValue) // MSB
        let pressureByte2 = try i2c.readByte(slaveID, command: DataRegisterAddress.pressureData.rawValue + 1)
        let pressureByte3 = try i2c.readByte(slaveID, command: DataRegisterAddress.pressureData.rawValue + 2) // LSB (top four bits only)
        
        // Pressure readout is the top 20 bits of the three bytes
        let pressure20BitUnsignedRepresentation: UInt32 = (UInt32(pressureByte1) << 12) | (UInt32(pressureByte2) << 4) | (UInt32(pressureByte3) >> 4)
        
        // Read temperature
        let temperatureByte1 = try i2c.readByte(slaveID, command: DataRegisterAddress.temperatureData.rawValue) // MSB
        let temperatureByte2 = try i2c.readByte(slaveID, command: DataRegisterAddress.temperatureData.rawValue + 1)
        let temperatureByte3 = try i2c.readByte(slaveID, command: DataRegisterAddress.temperatureData.rawValue + 2) // LSB (top four bits only)

        // Temperature readout is the top 20 bits of the three bytes
        let temp20BitUnsignedRepresentation: UInt32 = (UInt32(temperatureByte1) << 12) | (UInt32(temperatureByte2) << 4) | (UInt32(temperatureByte3) >> 4)
                
        // Read humidity (16 bits in two bytes)
        let humidityByte1 = try i2c.readByte(slaveID, command: DataRegisterAddress.humidityData.rawValue) // MSB
        let humidityByte2 = try i2c.readByte(slaveID, command: DataRegisterAddress.humidityData.rawValue + 1) // LSB
        let humidity16BitUnsignedRepresentation: UInt32 = (UInt32(humidityByte1) << 8) | UInt32(humidityByte2)
        
        logger.log("byte 1: \(humidityByte1)")
        logger.log("byte 2: \(humidityByte2)")
        logger.log("result: \(humidity16BitUnsignedRepresentation)")
        
        let uncompensatedData = bme280_uncomp_data(pressure: pressure20BitUnsignedRepresentation,
                                                   temperature: temp20BitUnsignedRepresentation,
                                                   humidity: humidity16BitUnsignedRepresentation)
        
        let readings: (temperature: Double, pressure: Double, humidity: Double) = withUnsafePointer(to: uncompensatedData) { uncompPtr in
            withUnsafeMutablePointer(to: &self.calibrationData) { calibDataPtr in
                // Note: compensate_temperature() must be called before compensate_pressure()
                // because it calculates and sets t_fine in the calibData struct
                let temperature = compensate_temperature(uncompPtr, calibDataPtr)
                let pressure = compensate_pressure(uncompPtr, calibDataPtr) / 100 // Division by 100 to convert output in Pascals to hPa / mb
                let humidity = compensate_humidity(uncompPtr, calibDataPtr)
                logger.log("Humidity: \(humidity)")
                return (temperature: temperature, pressure: pressure, humidity: humidity)
            }
        }
        
        return [
            Reading(outputType: .temperature(unit: .celsius), sensorLocation: self.location, sensorID: self.id, value: Float(readings.temperature)),
            Reading(outputType: .barometricPressure(unit: .hPa), sensorLocation: self.location, sensorID: self.id, value: Float(readings.pressure)),
            Reading(outputType: .humidity(unit: .rhd), sensorLocation: self.location, sensorID: self.id, value: Float(readings.humidity))
        ]
    }
}
