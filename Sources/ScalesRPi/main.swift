//
//  main.swift
//
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation
import ScalesCore
import LinuxSPI

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
        let pi = LinuxSPI.startPigpio()
        print("pigpio start result: \(pi)")
        
        
        
        if pi >= 0 {
            print("Stopping pigpio")
            LinuxSPI.stopPigpio(pi: pi)
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
