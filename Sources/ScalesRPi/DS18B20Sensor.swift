
import Foundation
import ScalesCore
import SwiftyGPIO

class DS18B20Sensor: ScalesCore.Sensor {
    
    typealias T = Float

    var id: String {
        self.name
    }
    
    let name: String
    
    let outputType: ScalesCore.SensorOutputType = .temperature(unit: .celsius)
    let location: ScalesCore.SensorLocation = .indoor(location: nil) // TODO: Set in init
    weak var delegate: (any SensorDelegate<T>)?
    
    private var timer: Timer?
    private let onewire: OneWireInterface
    private let slaveID: String
    
    public init?(onewire: OneWireInterface, name: String) {
        
        self.onewire = onewire
        self.name = name
        // Assume sensor is first device on the bus
        guard let slaveID = onewire.getSlaves().first else {
            return nil
        }
        
        self.slaveID = slaveID
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if let self {
//                guard let reading = getReading() else {
//                    return
//                }
                
                Task {
                    await self.delegate?.didGetReading(0.2)
                }
            }
        }
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
