
import Foundation
import ScalesCore

final class BME280Sensor: ScalesCore.Sensor {
    
    typealias T = Float
    
    var id: String {
        "BME280-ID\(self.slaveID)"
    }
    
    let location: ScalesCore.SensorLocation
    let outputType: ScalesCore.SensorOutputType = .barometricPressure(unit: .hPa)
    
    private let slaveID: Int = 0x67
    private let minUpdateInterval: TimeInterval

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
    
    init(location: ScalesCore.SensorLocation, minUpdateInterval: TimeInterval) {
        self.location = location
        self.minUpdateInterval = minUpdateInterval
    }
    
    private func getReading() -> Result<Reading<T>, Error> {
        return .success(self.sensorReading())
    }
    
    private func sensorReading() -> Reading<T> {
        return Reading(outputType: self.outputType, value: 0)
    }
}
