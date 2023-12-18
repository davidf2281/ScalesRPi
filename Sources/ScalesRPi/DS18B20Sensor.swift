
import Foundation
import ScalesCore
import SwiftyGPIO

final class DS18B20Sensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    var id: String {
        self.name
    }
    
    let name: String
    
    let outputType: ScalesCore.SensorOutputType = .temperature(unit: .celsius)
    let location: ScalesCore.SensorLocation = .indoor(location: nil) // TODO: Set in init
    
    private let onewire: OneWireInterface
    private let slaveID: String
    private let minUpdateInterval: TimeInterval
    
    lazy var readings = AsyncStream<T> { [weak self] continuation in
        guard let self else { return }
        
        let task = Task {
            while(true) {
                if let reading = self.getReading() {
                    continuation.yield(reading)
                }
                try await Task.sleep(for: .seconds(self.minUpdateInterval))
            }
        }
        
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
    }
    
    public init?(onewire: OneWireInterface, name: String, minUpdateInterval: TimeInterval) {
        
        self.onewire = onewire
        self.name = name
        self.minUpdateInterval = minUpdateInterval
        
        // Assume sensor is first device on the bus
        guard let slaveID = onewire.getSlaves().first else {
            return nil
        }
        
        self.slaveID = slaveID
    }
    
    private func getReading() -> Float? {
        
        let dataLines = onewire.readData(self.slaveID)
        
        /*
         The DS18B20 linux driver produces two text output lines of the form:
         
         5c 01 4b 46 7f ff 04 10 a1 : crc=a1 YES
         5c 01 4b 46 7f ff 04 10 a1 t=21750
         
         ...the 't=' param is the temperature in C, multiplied by 1000
         */
        
        guard dataLines.count == 2 else {
            return nil
        }
        
        let dataline = dataLines[1]
        
        let readingComponent = dataline.components(separatedBy: .whitespaces).last
        
        guard let readingString = readingComponent?.replacingOccurrences(of: "t=", with: ""),
              let reading = Float(readingString) else {
            return nil
        }
        
        return reading / 1000
    }
}
