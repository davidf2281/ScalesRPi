
import Foundation
import ScalesCore
import SwiftyGPIO

class DS18B20Sensor: ScalesCore.Sensor {
    
    typealias T = Float

    weak var delegate: (any SensorDelegate<T>)?
    
    private var timer: Timer?
    private let onewire: OneWireInterface
    private let slaveID: String
    
    public init?(onewire: OneWireInterface) {
        self.onewire = onewire
        
        guard let slaveID = onewire.getSlaves().first else {
            return nil
        }
        
        self.slaveID = slaveID
    }
    
    func start() {
        func start() {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if let self {
                    guard let reading = getReading() else {
                        return
                    }
                    self.delegate?.didGetReading(reading)
                }
            }
        }
    }
    
    private func getReading() -> Float? {
        
        let dataLines = onewire.readData(self.slaveID)
        
        guard dataLines.count == 2 else {
            return nil
        }

        let dataline = dataLines[1]
        
        let readingComponent = dataline.components(separatedBy: .whitespaces).last
        
        guard let readingString = readingComponent?.replacingOccurrences(of: "t=", with: ""),
        let reading = Float(readingString) else {
            return nil
        }
        
        // DS18B20 output is an integer representing temp in celsius * 1000
        return reading / 1000
    }
}
