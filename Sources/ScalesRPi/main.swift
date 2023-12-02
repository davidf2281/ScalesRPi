//
//  main.swift
//
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation
import ScalesCore
import SwiftyGPIO

let main = Main()

// Setup shutdown handlers to handle SIGINT and SIGTERM
let signalQueue = DispatchQueue(label: "shutdown")
makeSignalSource(SIGTERM, backlightPin: main.lcdBacklightPin)
makeSignalSource(SIGINT, backlightPin: main.lcdBacklightPin)

RunLoop.main.run()

struct Main {
    
    let sensor: DS18B20Sensor
    let display: ST7789Display
    let coordinator: ScalesCore.Coordinator<DS18B20Sensor>
    let lcdBacklightPin: GPIO?
    let buttonAPin: GPIO
    
    init() {
        
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
        
        self.buttonAPin = gpios[.P5]!
        buttonAPin.direction = .IN
        buttonAPin.onChange({ buttonAPin in
            print("Button A changed")
        })
        
        let dcPin = gpios[.P9]!
        dcPin.direction = .OUT
        let spi1 = SwiftyGPIO.hardwareSPIs(for: zero2W)![1]
        self.display = ST7789Display(spi: spi1, dc: dcPin)
        
        let i2c = SwiftyGPIO.hardwareI2Cs(for: zero2W)![1]
//        self.sensor = MCP9600Sensor(i2c: i2c)
        
        let onewire = SwiftyGPIO.hardware1Wires(for: zero2W)![0]
        
        self.sensor = DS18B20Sensor(onewire: onewire)
        
        self.coordinator = ScalesCore.Coordinator(sensor: sensor, display: display)
    }
}

func makeSignalSource(_ code: Int32, backlightPin: GPIO?) {
    let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
    source.setEventHandler {
        source.cancel()
        print()
        backlightPin?.value = 0
        print("Goodbye")
        exit(0)
    }
    source.resume()
    signal(code, SIG_IGN)
}
