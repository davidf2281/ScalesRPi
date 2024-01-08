
import Foundation
import ScalesCore
import SwiftyGPIO

let signalQueue: DispatchQueue
let main: Main
var coordinator: ScalesCore.Coordinator<Float>?
let logger = Logger(name: "ScalesRPi main")

do {
    main = try Main()
} catch {
    fatalError("Could not create main")
}

// Configure shutdown handlers to handle SIGINT and SIGTERM
signalQueue = DispatchQueue(label: "shutdown")
makeSignalSource(SIGTERM, backlightPin: main.lcdBacklightPin)
makeSignalSource(SIGINT, backlightPin: main.lcdBacklightPin)

RunLoop.main.run()

struct Main {
    
    let display: ST7789Display
    let lcdBacklightPin: GPIO?
    private let buttonAPin: GPIO
    
    init() throws {
        
        print("ScalesRPi: Starting")
        
        let zero2W: SupportedBoard = .RaspberryPiZero2
        let gpios = SwiftyGPIO.GPIOs(for: zero2W)
        
        let redLEDPin = gpios[.P17]
        let greenLEDPin = gpios[.P27]
        let blueLEDPin = gpios[.P22]
        let ledPins = [redLEDPin, greenLEDPin, blueLEDPin]
        for pin in ledPins {
            pin?.direction = .OUT
            pin?.value = 1
        }
        
        self.lcdBacklightPin = gpios[.P13]
        self.lcdBacklightPin?.direction = .OUT
        self.lcdBacklightPin?.value = 1
        
        let dcPin = gpios[.P9]!
        dcPin.direction = .OUT
        let spi1 = SwiftyGPIO.hardwareSPIs(for: zero2W)![1]
        try self.display = ST7789Display(spi: spi1, dc: dcPin)
        
        let onewire = SwiftyGPIO.hardware1Wires(for: zero2W)![0]
        let outdoorTempSensor = try DS18B20Sensor(onewire: onewire, location: .outdoor(location: nil), minUpdateInterval: 60.0).erasedToAnySensor
        
        let i2c = SwiftyGPIO.hardwareI2Cs(for: zero2W)![1]
        let indoorTempPressureHumiditySensor = try BME280Sensor(i2c: i2c, location: .indoor(location: nil), minUpdateInterval: 60.0).erasedToAnySensor
        
        self.buttonAPin = gpios[.P5]!
        buttonAPin.direction = .IN
        buttonAPin.bounceTime = 0.25
        let buttonHandler = RPiButtonHandler(button: buttonAPin)
        
        coordinator = try ScalesCore.Coordinator(sensors: [outdoorTempSensor, indoorTempPressureHumiditySensor], display: display, buttonHandler: buttonHandler)
    }
}

func makeSignalSource(_ code: Int32, backlightPin: GPIO?) {
    let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
    source.setEventHandler {
        Task {
            print()
            print("Flushing data to disk")
            let result = await coordinator?.flushAllToDisk()
            if case .failure(let error) = result {
                for errorString in error.errorDescriptions {
                    print(errorString)
                }
            }
            source.cancel()
            backlightPin?.value = 0
            print("Exiting ScalesRPi")
            exit(0)
        }
    }
    source.resume()
    signal(code, SIG_IGN)
}

class RPiButtonHandler: ButtonHandler {
    let button: GPIO
    var buttonPushHandler: ((ButtonPress) -> Void)?

    init(button: GPIO) {
        self.button = button
        button.onRaising { [weak self] button in
            logger.log("Button press")
            if let buttonPushHandler = self?.buttonPushHandler {
                buttonPushHandler(ButtonPress())
            }
        }
    }
    
    func startMonitoring() {}
    func stopMonitoring() {}

    var buttonPresses: AsyncStream<ButtonPress> {
        AsyncStream { continuation in
            let monitor = RPiButtonHandler(button: self.button)
            monitor.buttonPushHandler = { buttonPress in
                continuation.yield(buttonPress)
            }
            continuation.onTermination = { @Sendable _ in
                 monitor.stopMonitoring()
            }
            monitor.startMonitoring()
        }
    }
}

