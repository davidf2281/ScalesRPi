
import Foundation
import ScalesCore
import SwiftyGPIO

enum OversampleSetting {
    case singleShot
    case oversample(iterations: Int)
}

final class DS18B20Sensor: ScalesCore.Sensor {
    
    public enum DS18B20Error: Error {
        case updateIntervalTooShort
        case readOneWireError
        case noSlavesFound
    }
    
    typealias T = Float
    
    var id: String {
        "DS18B20-ID" + self.slaveID
    }
    
    let location: ScalesCore.SensorLocation
    
    private let onewire: OneWireInterface
    private let slaveID: String
    private let minUpdateInterval: TimeInterval
    private let oversampleSetting: OversampleSetting
    
    private(set) lazy var readings = AsyncStream<Result<[Reading<T>], Error>> { [weak self] continuation in
        
        guard let self else { return }
        
        let task = Task {
            while(Task.isNotCancelled) {
                let readingResult = self.getReading()
                continuation.yield(readingResult)
                switch readingResult {
                    case .failure(let error):
                        print("DS1820 error: \(error.localizedDescription)")
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
    
    public init(onewire: OneWireInterface, location: ScalesCore.SensorLocation, minUpdateInterval: TimeInterval, oversampleSetting: OversampleSetting = .oversample(iterations: 16)) throws {
        
        switch oversampleSetting {
            case .singleShot:
                if minUpdateInterval < 0.75 { // DS18B20 max sample time is 0.75s
                    throw DS18B20Error.updateIntervalTooShort
                }
            case .oversample(iterations: let iterations):
                let timeForAllIterations = TimeInterval(Float(iterations) * 0.75)
                if minUpdateInterval < timeForAllIterations {
                    throw DS18B20Error.updateIntervalTooShort
                }
        }
        
        self.oversampleSetting = oversampleSetting
        self.onewire = onewire
        self.minUpdateInterval = minUpdateInterval
        self.location = location
        
        // Assume sensor is first device on the bus
        guard let slaveID = try onewire.getSlaves().first else {
            throw DS18B20Error.noSlavesFound
        }
        
        self.slaveID = slaveID
    }
    
    private func getReading() -> Result<[Reading<Float>], Error> {
        
        do {
            let reading: Float
            switch self.oversampleSetting {
                    
                case .singleShot:
                    reading = try sensorReading()
                    
                case .oversample(let iterations):
                    var outputAccumulator: Float = 0.0
                    for _ in 0..<iterations {
                        let sensorReading = try sensorReading()
                        outputAccumulator += sensorReading
                    }
                    reading = outputAccumulator / Float(iterations)
            }
            return .success([Reading(outputType: .temperature(unit: .celsius), sensorLocation: self.location, sensorID: self.id, value: reading / 1000)])
        } catch {
            return .failure(error)
        }
    }
    
    private func sensorReading() throws -> Float {
        let dataLines = try onewire.readData(self.slaveID)
        
        /*
         The DS18B20 linux driver produces two text output lines of the form:
         
         5c 01 4b 46 7f ff 04 10 a1 : crc=a1 YES
         5c 01 4b 46 7f ff 04 10 a1 t=21750
         
         ...the 't=' param is the temperature in Celsius, multiplied by 1000
         */
        
        guard let dataline = dataLines[safe: 1] else {
            throw OneWireInterfaceError.readError
        }
        
        let readingComponent = dataline.components(separatedBy: .whitespaces).last
        
        guard let readingString = readingComponent?.replacingOccurrences(of: "t=", with: ""),
              let reading = Float(readingString) else {
            throw OneWireInterfaceError.readError
        }
        
        return reading
    }
}
