
import Foundation
import ScalesCore
import SwiftyGPIO

class DS18B20Sensor: ScalesCore.Sensor {
    
    typealias T = Float

    weak var delegate: (any SensorDelegate<T>)?

    private let onewire: OneWireInterface
    
    public init(onewire: OneWireInterface) {
        self.onewire = onewire
        
        for slave in onewire.getSlaves() {
            print("Slave: " + slave)
            print("------------------------------------")
            for data in onewire.readData(slave) {
                print(data)
            }
        }
    }
    
    func start() {
        // TODO: Implement me
    }
}
