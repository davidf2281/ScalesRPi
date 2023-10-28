
import Foundation
import ScalesCore

class RPiReadingProvider: ScalesCore.ReadingProvider {
    var delegate: ScalesCore.ReadingProviderDelegate?
    
    private var timer: Timer?
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.delegate?.didGetReading(0.0)
        }
    }
}
