
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
    
    private let slaveID: Int = 0x67
    private let sensorIDRegisterAddress: UInt8 = 0xD0
    
    private let minUpdateInterval: TimeInterval
    private let i2c: I2CInterface
    enum BME280RegisterBaseAddress: Int {
        
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
        
        var lowerAddress: Int {
            return self.rawValue
        }
        
        var upperAddress: Int {
            return self.rawValue + 1
        }
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
        
        let sensorID = i2c.readByte(slaveID, command: sensorIDRegisterAddress)
        
        print("BME280 sensor id: \(sensorID)")
        
        // TODO: Read the calibration compensation values from device non-volatile memory
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

 /*
 // Returns pressure in Pa as unsigned 32 bit integer in Q24.8 format (24 integer bits and 8
 fractional bits).
 // Output value of “24674867” represents 24674867/256 = 96386.2 Pa = 963.862 hPa
 BME280_U32_t BME280_compensate_P_int64(BME280_S32_t adc_P)
 {
 BME280_S64_t var1, var2, p;
 var1 = ((BME280_S64_t)t_fine) – 128000;
 var2 = var1 * var1 * (BME280_S64_t)dig_P6;
 var2 = var2 + ((var1*(BME280_S64_t)dig_P5)<<17);
 var2 = var2 + (((BME280_S64_t)dig_P4)<<35);
 var1 = ((var1 * var1 * (BME280_S64_t)dig_P3)>>8) + ((var1 * (BME280_S64_t)dig_P2)<<12);
 var1 = (((((BME280_S64_t)1)<<47)+var1))*((BME280_S64_t)dig_P1)>>33;
 if (var1 == 0)
 {
 return 0; // avoid exception caused by division by zero
 }
 p = 1048576-adc_P;
 p = (((p<<31)-var2)*3125)/var1;
 var1 = (((BME280_S64_t)dig_P9) * (p>>13) * (p>>13)) >> 25;
 var2 = (((BME280_S64_t)dig_P8) * p) >> 19;
 p = ((p + var1 + var2) >> 8) + (((BME280_S64_t)dig_P7)<<4);
 return (BME280_U32_t)p;
 }
 
 // Returns humidity in %RH as unsigned 32 bit integer in Q22.10 format (22 integer and 10
 fractional bits).
 // Output value of “47445” represents 47445/1024 = 46.333 %RH
 BME280_U32_t bme280_compensate_H_int32(BME280_S32_t adc_H)
 {
 BME280_S32_t v_x1_u32r;
 v_x1_u32r = (t_fine – ((BME280_S32_t)76800));
 Bosch Sensortec | BME280 Data sheet 26 | 60
 Modifications reserved | Data subject to change without notice Document number: BST-BME280-DS001-23 Revision_1.23_012022
 v_x1_u32r = (((((adc_H << 14) – (((BME280_S32_t)dig_H4) << 20) – (((BME280_S32_t)dig_H5) * v_x1_u32r)) + ((BME280_S32_t)16384)) >> 15) * (((((((v_x1_u32r * ((BME280_S32_t)dig_H6)) >> 10) * (((v_x1_u32r * ((BME280_S32_t)dig_H3)) >> 11) + ((BME280_S32_t)32768))) >> 10) + ((BME280_S32_t)2097152)) * ((BME280_S32_t)dig_H2) + 8192) >> 14));
 v_x1_u32r = (v_x1_u32r – (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) * ((BME280_S32_t)dig_H1)) >> 4));
 v_x1_u32r = (v_x1_u32r < 0 ? 0 : v_x1_u32r);
 v_x1_u32r = (v_x1_u32r > 419430400 ? 419430400 : v_x1_u32r);
 return (BME280_U32_t)(v_x1_u32r>>12);
 }
 */
