//
//  main.swift
//
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation
import ScalesCore

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
