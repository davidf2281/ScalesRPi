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

makeSignalSource(SIGTERM)
makeSignalSource(SIGINT)

// If the application is running on balena,
// start the main run loop so that the application doesn't quit.
//
// Otherwise the container will be repeatedly restarted by balena.
// https://www.balena.io/docs/learn/develop/runtime
//if ProcessInfo.processInfo.environment["BALENA"] == "1" {
//    RunLoop.main.run()
//}

RunLoop.main.run()


let thing = MainThing()

struct MainThing {
    let readingsProvider = RPiReadingProvider()
    let display = RPiDisplay(width: 320, height: 240)
    let readingProcessor: ScalesCore.ReadingProcessor
    init() {
        print("Main thing")
        self.readingProcessor = ScalesCore.ReadingProcessor(readingProvider: readingsProvider, display: display)
        readingsProvider.start()
    }
}

class RPiReadingProvider: ScalesCore.ReadingProvider {
    var delegate: ScalesCore.ReadingProviderDelegate?
    
    private var timer: Timer?
    
    func start() {
        print("Reading provider starting.")
        self.delegate?.didGetReading(0.0)
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.delegate?.didGetReading(0.0)
        }
    }
}

struct RPiDisplay: ScalesCore.Display {
    
    init(width: CGFloat, height: CGFloat) {
        // TODO: Implement me
    }
    
    var font: ScalesCore.Font?
    
    func drawText(_ text: String, x: CGFloat, y: CGFloat) {
        print("Something tried to draw some text")
    }
}

