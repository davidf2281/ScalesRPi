
import Foundation
import ScalesCore
import SwiftyGPIO
import ScalesRPiC

final class BME280Sensor: ScalesCore.Sensor {
    
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
    }
    
    typealias T = Float
    
    var id: String {
        "BME280-ID\(self.slaveID)"
    }
    
    let location: ScalesCore.SensorLocation
    
    private let slaveID: Int = 0x76
    private let minUpdateInterval: TimeInterval
    private let i2c: I2CInterface
    private var calibrationData: bme280_calib_data // var because t_fine needs be mutable
    
    private(set) lazy var readings = AsyncStream<Result<[Reading<T>], Error>> { [weak self] continuation in
        
        guard let self else { return }
        
        let task = Task {
            while(Task.isNotCancelled) {
                let readingResult = try await self.getReadings()
                continuation.yield(readingResult)
                switch readingResult {
                    case .failure(let error):
                        print("BME280 error: \(error.localizedDescription)")
                    default:
                        break
                }
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
        Self.resetDevice(i2c: i2c, slaveID: slaveID)
        self.calibrationData = Self.readCalibrationData(i2c: i2c, slaveID: slaveID)
    }
    
    private static func resetDevice(i2c: I2CInterface, slaveID: Int) {
        i2c.writeByte(slaveID, command: ControlRegisterAddress.reset.rawValue, value: 0xB6)
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    private static func readCalibrationData(i2c: I2CInterface, slaveID: Int) -> bme280_calib_data {
        
        // Read pressure compensation values
        let p1 = i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP1.rawValue)
        let p2 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP2.rawValue))
        let p3 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP3.rawValue))
        let p4 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP4.rawValue))
        let p5 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP5.rawValue))
        let p6 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP6.rawValue))
        let p7 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP7.rawValue))
        let p8 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP8.rawValue))
        let p9 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digP9.rawValue))
        
        // Read temperature compensation values
        let t1 = i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digT1.rawValue)
        let t2 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digT2.rawValue))
        let t3 = Int16(bitPattern: i2c.readWord(slaveID, command: CalibrationRegisterBaseAddress.digT3.rawValue))
        
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
                                 dig_h1: 0,
                                 dig_h2: 0,
                                 dig_h3: 0,
                                 dig_h4: 0,
                                 dig_h5: 0,
                                 dig_h6: 0,
                                 t_fine: 0)
    }
    
    private func getReadings() async throws -> Result<[Reading<T>], Error> {
        let readings = try await self.sensorReadings()
        return .success(readings)
    }
    
    private func sensorReadings() async throws -> [Reading<T>] {
              
        // Write humidity config, which acccording to the BME280 datasheet must be done before writing measurement config
        let humidityConfig: UInt8 = 0 // Skip humidity measurement
        i2c.writeByte(slaveID, command: ControlRegisterAddress.ctrlHum.rawValue, value: humidityConfig)
        
        // Write measurement config to put the device into forced mode, which will start a measurement
        let ctrlMeasConfig: UInt8 = 0b01101110 // 4x temperature oversampling, 4x pressure oversample, sensor to forced mode.
        i2c.writeByte(slaveID, command: ControlRegisterAddress.ctrlMeas.rawValue, value: ctrlMeasConfig)
        
        // Wait for measurement
        try await Task.sleep(for: .milliseconds(100))
        
        // Read pressure
        let pressureByte1 = i2c.readByte(slaveID, command: DataRegisterAddress.pressureData.rawValue) // MSB
        let pressureByte2 = i2c.readByte(slaveID, command: DataRegisterAddress.pressureData.rawValue + 1)
        let pressureByte3 = i2c.readByte(slaveID, command: DataRegisterAddress.pressureData.rawValue + 2) // LSB (top four bits only)
        
        // Pressure readout is the top 20 bits of the three bytes
        let pressure20BitUnsignedRepresentation: UInt32 = (UInt32(pressureByte1) << 12) | (UInt32(pressureByte2) << 4) | (UInt32(pressureByte3) >> 4)
        
        // Read temperature
        let temperatureByte1 = i2c.readByte(slaveID, command: DataRegisterAddress.temperatureData.rawValue) // MSB
        let temperatureByte2 = i2c.readByte(slaveID, command: DataRegisterAddress.temperatureData.rawValue + 1)
        let temperatureByte3 = i2c.readByte(slaveID, command: DataRegisterAddress.temperatureData.rawValue + 2) // LSB (top four bits only)

        // Temperature readout is the top 20 bits of the three bytes
        let temp20BitUnsignedRepresentation: UInt32 = (UInt32(temperatureByte1) << 12) | (UInt32(temperatureByte2) << 4) | (UInt32(temperatureByte3) >> 4)
                
        let uncompensatedData = bme280_uncomp_data(pressure: pressure20BitUnsignedRepresentation, temperature: temp20BitUnsignedRepresentation, humidity: 0)
        
        let temperatureAndPressure: (temperature: Double, pressure: Double) = withUnsafePointer(to: uncompensatedData) { uncompPtr in
            withUnsafeMutablePointer(to: &self.calibrationData) { calibDataPtr in
                // Note: compensate_temperature() must be called before compensate_pressure()
                // because it calculates and sets t_fine in the calibData struct
                let temperature = compensate_temperature(uncompPtr, calibDataPtr)
                let pressure = compensate_pressure(uncompPtr, calibDataPtr) / 100 // Division by 100 to convert output in Pascals to hPa / mb
                return (temperature: temperature, pressure: pressure)
            }
        }
        
        return [
            Reading(outputType: .temperature(unit: .celsius), sensorLocation: self.location, sensorID: self.id, value: Float(temperatureAndPressure.temperature)),
            Reading(outputType: .barometricPressure(unit: .hPa), sensorLocation: self.location, sensorID: self.id, value: Float(temperatureAndPressure.pressure))
        ]
    }
}
