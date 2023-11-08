//
//  main.swift
//
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation
import ScalesCore
import SwiftyGPIO

// Setup shutdown handlers to handle SIGINT and SIGTERM
// https://www.balena.io/docs/reference/base-images/base-images/#how-the-images-work-at-runtime
let signalQueue = DispatchQueue(label: "shutdown")

makeSignalSource(SIGTERM)
makeSignalSource(SIGINT)

let thing = MainThing()

RunLoop.main.run()

struct MainThing {
    let sensor = RPiSensor()
    let display = RPiDisplay()
    let coordinator: ScalesCore.Coordinator<RPiSensor>
    init() {
        print("ScalesRPi: Starting")
//        let config: LinuxSPI.spi_config_t = .init(mode: 0, bits_per_word: 8, speed: 6000000, delay: 0)
//                
//        let spifd = LinuxSPI.spi_open("/dev/spidev2.0", config)
//        LinuxSPI.spi_close(spifd)
//        print("Opened and closed SPI. Possibly.")
//        print("pigpio start result: \(pi)")
        
//        let spi = SwiftyGPIO.hardwareSPIs(for: .RaspberryPiZero2)![0]
        
        let zero2W: SupportedBoard = .RaspberryPiZero2
        
        let gpios = SwiftyGPIO.GPIOs(for: zero2W)
        let redLEDPin = gpios[.P11]
        let greenLEDPin = gpios[.P13]
        let blueLEDPin = gpios[.P15]

        let pins = [redLEDPin, greenLEDPin, blueLEDPin]
        
        for pin in pins {
            pin?.direction = .OUT
            pin?.value = 0
        }
        
        self.coordinator = ScalesCore.Coordinator(sensor: sensor, graphicsContext: GraphicsContext(display: display))
        sensor.start()
    }
}

func makeSignalSource(_ code: Int32) {
    let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
    source.setEventHandler {
        source.cancel()
        print()
        print("Goodbye")
        exit(0)
    }
    source.resume()
    signal(code, SIG_IGN)
}
