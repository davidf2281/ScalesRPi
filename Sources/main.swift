//
//  main.swift
//
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation
import ScalesCore

MainThing.doThing()

struct MainThing {
    static func doThing() {
        print("Environment: \(ProcessInfo.processInfo.environment)")
        
        let readingsProvider = RPiReadingProvider()
        let readingProcessor = ScalesCore.ReadingProcessor(readingProvider: readingsProvider, display: RPiDisplay(width: 320, height: 240))
        readingsProvider.start()
    }
}

class RPiReadingProvider: ScalesCore.ReadingProvider {
    var delegate: ScalesCore.ReadingProviderDelegate?
    
    func start() {
        self.delegate?.didGetReading(0.0)
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
if ProcessInfo.processInfo.environment["BALENA"] == "1" {
    RunLoop.main.run()
}
