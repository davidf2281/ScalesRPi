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
    let readingsProvider = RPiReadingProvider()
    let display = RPiDisplay(width: 320, height: 240)
    let readingProcessor: ScalesCore.ReadingProcessor
    init() {
        self.readingProcessor = ScalesCore.ReadingProcessor(readingProvider: readingsProvider, display: display)
        readingsProvider.start()
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
