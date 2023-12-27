
import Foundation
import ScalesCore
import SwiftyGPIO

final class BME280Sensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    var id: String {
        "BME280-ID\(self.slaveID)"
    }
    
    let location: ScalesCore.SensorLocation
    let outputType: ScalesCore.SensorOutputType = .barometricPressure(unit: .hPa)
    
    private let slaveID: Int = 0x67
    private let minUpdateInterval: TimeInterval
    private let i2c: I2CInterface
    
    private(set) lazy var readings = AsyncStream<Result<Reading<T>, Error>> { [weak self] continuation in
        guard let self else { return }
        
        let task = Task {
            while(true) {
                let readingResult = self.getReading()
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
    }
    
    private func getReading() -> Result<Reading<T>, Error> {
        return .success(self.sensorReading())
    }
    
    private func sensorReading() -> Reading<T> {
        // Set Mode[1:0] = 11 to enable force-measurement mode
        // Enable pressure, humidity, temperature
        // The humidity measurement is controlled by the osrs_h[2:0] setting
        // The pressure measurement is controlled by the osrs_p[2:0] setting
        // The temperature measurement is controlled by the osrs_t[2:0] setting
        // To read out data after a conversion, it is strongly recommended to use a burst read and not address every register individually.
        // Data readout is done by starting a burst read from 0xF7 to 0xFC (temperature and pressure) or from 0xF7 to 0xFE (temperature, pressure and humidity). The data are read out in an unsigned 20-bit format both for pressure and for temperature and in an unsigned 16-bit format for humidity. It is strongly recommended to use the BME280 API, available from Bosch Sensortec, for readout and compensation. For details on memory map and interfaces, please consult chapters 5 and 6 respectively.
        
        return Reading(outputType: self.outputType, value: 0)
    }
}

/*
 // Returns temperature in DegC, resolution is 0.01 DegC. Output value of “5123” equals 51.23
 DegC.
 // t_fine carries fine temperature as global value
 BME280_S32_t t_fine;
 BME280_S32_t BME280_compensate_T_int32(BME280_S32_t adc_T)
 {
 BME280_S32_t var1, var2, T;
 var1 = ((((adc_T>>3) – ((BME280_S32_t)dig_T1<<1))) * ((BME280_S32_t)dig_T2)) >> 11;
 var2 = (((((adc_T>>4) – ((BME280_S32_t)dig_T1)) * ((adc_T>>4) – ((BME280_S32_t)dig_T1))) >> 12) * ((BME280_S32_t)dig_T3)) >> 14;
 t_fine = var1 + var2;
 T = (t_fine * 5 + 128) >> 8;
 return T;
 }
 
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
