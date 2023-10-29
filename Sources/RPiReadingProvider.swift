
import Foundation
import ScalesCore

class RPiSensor: ScalesCore.Sensor {
    var delegate: ScalesCore.SensorDelegate?
    
    private var timer: Timer?
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.delegate?.didGetReading(0.0)
        }
    }
}
