
import Foundation
import SwiftyGPIO

struct ST7789: DisplayChipset {
    
    typealias Hz = UInt
    
    let speed: Hz
    let bpp: BitsPerPixel
    let spi: SPIInterface
    let dc: GPIO
    let width: Int
    let height: Int
    
    public init(speed: Hz, bpp: BitsPerPixel, spi: SPIInterface, dc: GPIO, width: Int, height: Int) {
        self.speed = speed
        self.bpp = bpp
        self.spi = spi
        self.dc = dc
        self.width = width
        self.height = height
    }
    
    func initializeDisplay() throws {
        try self.sendCommands([
            SWRESET(),
            COLMOD(bpp: self.bpp),
            MADCTL([.my]),
            INVON(),
            SLPOUT(),
            DISPON()
        ])
    }
    
    func displayBuffer(_ buffer: [UInt16]) throws {
                
        // Set window to full display
        try self.sendCommand(CASET(startX: 0, endX: width - 1))
        try self.sendCommand(RASET(startY: 0, endY: height - 1))
        
        // Send RAM-write command
        try self.sendCommand(RAMWR())
                
        // Send the frame
        try self.sendData(buffer.toUInt8)
    }
    
    private func sendCommands(_ commands: [any ST7789Command]) throws {
        for command in commands {
            try self.sendCommand(command)
        }
    }
    
    private func sendCommand(_ command: any ST7789Command) throws {
        
        dc.level = .low
        try spi.send(safe: [command.commandByte.rawValue], speed: speed)
        
        if let command = command as? (any ST7789ParameterizedCommand) {
            try self.sendData(command.parameters.asBytes)
        }
        
        if let delay = command.postCommandDelay {
            Thread.sleep(forTimeInterval: delay)
        }
    }
    
    private func sendData(_ bytes: [UInt8]) throws {
        dc.level = .high
        try spi.send(safe: bytes, speed: speed)
    }
}

extension ST7789 {
    
    enum CommandByte: UInt8 {
        
        case nop = 0x00
        case swreset = 0x01
        case rddid = 0x04
        case rddst = 0x09
        
        case slpin = 0x10
        case slpout = 0x11
        case ptlon = 0x12
        case noron = 0x13
        
        case invoff = 0x20
        case invon = 0x21
        case dispoff = 0x28
        case dispon = 0x29
        
        case caset = 0x2A
        case raset = 0x2B
        case ramwr = 0x2C
        case ramrd = 0x2E
        
        case ptlar = 0x30
        case madctl = 0x36
        case colmod = 0x3A
        
        case frmctr1 = 0xB1
        case frmctr2 = 0xB2
        case frmctr3 = 0xB3
        case invctr = 0xB4
        case disset5 = 0xB6
        
        case gctrl = 0xB7
        case gtadj = 0xB8
        case vcoms = 0xBB
        
        case lcmctrl = 0xC0
        case idset = 0xC1
        case vdvvrhen = 0xC2
        case vrhs = 0xC3
        case vdvs = 0xC4
        case vmctr1 = 0xC5
        case frctrl2 = 0xC6
        case cabcctrl = 0xC7
        
        case rdddim = 0xD0
        case rdid1 = 0xDA
        case rdid2 = 0xDB
        case rdid3 = 0xDC
        case rdid4 = 0xDD
        
        case gmctrp1 = 0xE0
        case gmctrn1 = 0xE1
        
        case pwctr6 = 0xFC
    }
}
