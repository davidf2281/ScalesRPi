
import Foundation
import ScalesCore

class RPiSensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    weak var delegate: (any SensorDelegate<T>)?
    
    private var timer: Timer?
    private var output: Float = 0
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if let self {
                self.delegate?.didGetReading(self.output)
                self.output += 0.1
            }
        }
    }
}

extension Float: SensorOutput {
    public typealias T = Self
    public var stringValue: String {
        String(self)
    }
}
