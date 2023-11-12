
import Foundation
import SwiftyGPIO

struct ST7789 {
    
    enum BitsPerPixel: Int {
        case bpp16 = 0x05
        case bpp18 = 0x06
    }
    
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
    
    private var initializerCommands: [any ST7789Command] = [
        SWRESET(),
        MADCTL.default,
        FRMCTR2.default,
        COLMOD.bpp16,
        GCTRL.default,
        VCOMS.v1475,
        LCMCTRL.default,
        VDVVRHEN.default,
        VRHS.default,
        VDVS.default,
        RDDIM.default,
        FRCTRL2.default,
        GMCTRP1.default,
        GMCTRN1.default,
        INVOFF(),
        SLPOUT(),
        DISPON()
    ]
    
    func initializeDisplay() {
        print("Initializing ST7789...")
        self.sendCommands(self.initializerCommands)
        print("Done.")
    }
    
    func displayBuffer(_ buffer: [UInt16]) {
                
        // Set window to full display
        self.sendCommand(CASET.full)
        self.sendCommand(RASET.full)
        
        // Send frame-write command
        self.sendCommand(RAMWR())
        
        // Send the frame
        self.sendData(buffer.toUInt8)
    }
    
    private func sendCommands(_ commands: [any ST7789Command]) {
        for command in commands {
            self.sendCommand(command)
        }
    }
    
    private func sendCommand(_ command: any ST7789Command) {
        
        dc.level = .low
        spi.send(safe: [command.commandByte.rawValue], speed: speed)
        
        if let command = command as? (any ST7789ParameterizedCommand) {
            self.sendData(command.parameters.asBytes)
        }
        
        if let delay = command.postCommandDelay {
            Thread.sleep(forTimeInterval: delay)
        }
    }
    
    private func sendData(_ bytes: [UInt8]) {
        dc.level = .high
        spi.send(safe: bytes, speed: speed)
    }
}

/*
 Existing library used commands
 
 Initializer:
 SWRESET(0x01)
 (150ms delay)
 
 MADCTL(0x36)
 0x70
 
 FRMCTR2(0xB2)
 0x0C
 0x0C
 0x00
 0x33
 0x33
 
 COLMOD(0x3A)
 0x05
 
 GCTRL(0xB7)
 0x14
 
 VCOMS(0xBB)
 0x37
 
 LCMCTRL(0xC0)
 0x2C
 
 VDVVRHEN(0xC2)
 0x01
 
 VRHS(0xC3)
 0x12
 
 VDVS(0xC4)
 0x20
 
 RDDIM(0xD0) // Unnamed in Python implementation
 0xA4
 0xA1
 
 FRCTRL2(0xC6)
 0x0F
 
 GMCTRP1(0xE0) // Gamma, apparently
 0xD0
 0x04
 0x0D
 0x11
 0x13
 0x2B
 0x3F
 0x54
 0x4C
 0x18
 0x0D
 0x0B
 0x1F
 0x23
 
 GMCTRN1( 0xE1) // Gamma again, apparently
 0xD0
 0x04
 0x0C
 0x11
 0x13
 0x2C
 0x3F
 0x44
 0x51
 0x2F
 0x1F
 0x1F
 0x20
 0x23
 
 SLPOUT(0x11)
 (no parameters)
 
 DISPON(0x29)
 (100ms delay)
 
 
 
 Setting write window immediately prior to buffer write:
 CASET
 RASET
 RAMWR
 */
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
        case colmod = 0x3A // Sets bits per pixel
        
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
