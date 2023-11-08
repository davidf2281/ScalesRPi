
import Foundation
import ScalesCore

class RPiSensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    weak var delegate: (any SensorDelegate<T>)?
    
    private var timer: Timer?
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.delegate?.didGetReading(0.0)
        }
    }
}

extension Float: SensorOutput {
    public typealias T = Self
    public var stringValue: String {
        String(self)
    }
}