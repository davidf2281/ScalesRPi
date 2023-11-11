
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
        COLMOD.bpp16,
//        VCOMS.v1475,
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

protocol ST7789Command {
    var commandByte: ST7789.CommandByte { get }
    var postCommandDelay: TimeInterval? { get }
}

extension ST7789Command {
    var postCommandDelay: TimeInterval? { nil }
}

protocol ST7789ParameterizedCommand: ST7789Command {
    associatedtype T: ScalesRPi.Parameter
    var parameters: [T] { get }
}

extension ST7789 {
    
    struct SWRESET: ST7789Command {
        let commandByte: CommandByte = .swreset
        let postCommandDelay: TimeInterval? = 0.150
    }
    
    struct MADCTL: ST7789ParameterizedCommand {
        
        static var `default`: Self { .init([.default]) }
        
        let commandByte: CommandByte = .madctl
        let parameters: [MADCTL.Parameter]
        
        init(_ parameters: [MADCTL.Parameter]) {
            self.parameters = parameters
        }
        
        struct Parameter: ScalesRPi.Parameter {
            
            static var `default`: Self = .init(rawValue: 0)
            
            let rawValue: UInt8
            
            static let my =  Parameter(rawValue: 1 << 7) // Page Address Order
            static let mx =  Parameter(rawValue: 1 << 6) // Column Address Order
            static let mv =  Parameter(rawValue: 1 << 5) // Page/Column Order
            static let ml =  Parameter(rawValue: 1 << 4) // Line Address Order
            static let rgb = Parameter(rawValue: 1 << 3) // RGB/BGR Order
            static let mh =  Parameter(rawValue: 1 << 2) // Display Data Latch Order
        }
    }
    
    struct COLMOD: ST7789ParameterizedCommand {
        
        static var bpp16: Self { .init([.bpp16]) }
        
        let commandByte: CommandByte = .colmod
        let parameters: [COLMOD.Parameter]
        
        init(_ parameters: [COLMOD.Parameter]) {
            self.parameters = parameters
        }
        
        struct Parameter: ScalesRPi.Parameter {
            static var bpp16: Self = .init(rawValue: 0x05)
            let rawValue: UInt8
        }
    }
    
    struct VCOMS: ST7789ParameterizedCommand {
        
        static var v1475: Self { .init([.v1475]) }
        
        let commandByte: CommandByte = .vcoms
        let parameters: [VCOMS.Parameter]
        
        init(_ parameters: [VCOMS.Parameter]) {
            self.parameters = parameters
        }
        
        struct Parameter: ScalesRPi.Parameter {
            static var v1475: Self = .init(rawValue: 0x37)
            let rawValue: UInt8
        }
    }
    
    struct SLPOUT: ST7789Command {
        let commandByte: CommandByte = .slpout
        let postCommandDelay: TimeInterval? = 0.005
    }
    
    struct DISPON: ST7789Command {
        let commandByte: CommandByte = .dispon
        // TODO: The datasheet doesn't mention the need for a delay after this command. Try without.
        let postCommandDelay: TimeInterval? = 0.1
    }
    
    struct CASET: ST7789ParameterizedCommand {
        static var full: Self { .init(Parameter.full) }
        
        let commandByte: CommandByte = .caset
        let parameters: [CASET.Parameter]
        
        init(_ parameters: [CASET.Parameter]) {
            self.parameters = parameters
        }
        
        struct Parameter: ScalesRPi.Parameter {
            
            let rawValue: UInt8
            
            // TODO: Adapt for variable screen resolution
            static var full: [Self] = {
                let fullRange = 239
                let msb = UInt8(fullRange >> 8)
                let lsb = UInt8(fullRange & 0xFF)
                return [.init(rawValue: 0x0), .init(rawValue: 0x0),
                        .init(rawValue: msb), .init(rawValue: lsb)]
            }()
        }
    }
    
    struct RASET: ST7789ParameterizedCommand {
        static var full: Self { .init(Parameter.full) }
        
        let commandByte: CommandByte = .raset
        let parameters: [RASET.Parameter]
        
        init(_ parameters: [RASET.Parameter]) {
            self.parameters = parameters
        }
        
        struct Parameter: ScalesRPi.Parameter {
            
            let rawValue: UInt8
            
            // TODO: Adapt for variable screen resolution
            static var full: [Self] = {
                let fullRange = 319
                let msb = UInt8(fullRange >> 8)
                let lsb = UInt8(fullRange & 0xFF)
                return [.init(rawValue: 0x0), .init(rawValue: 0x0),
                        .init(rawValue: msb), .init(rawValue: lsb)]
            }()
        }
    }
    
    struct RAMWR: ST7789Command {
        let commandByte: CommandByte = .ramwr
    }
}

protocol Parameter: OptionSet {
    var rawValue: UInt8 { get }
}

struct None: Parameter {
    static var none = None()
    init() { self.init(rawValue: 0) }
    init(rawValue: UInt8) {}
    var rawValue: UInt8 { 0 }
}

extension Array<ScalesRPi.Parameter> {
    var asBytes: [UInt8] {
        self.map { $0.rawValue }
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
        case vrhs = 0xc3
        case vdvs = 0xc4
        case vmctr1 = 0xC5
        case frctrl2 = 0xC6
        case cabcctrl = 0xC7
        
        case rdid1 = 0xDA
        case rdid2 = 0xDB
        case rdid3 = 0xDC
        case rdid4 = 0xDD
        
        case gmctrp1 = 0xE0
        case gmctrn1 = 0xE1
        
        case pwctr6 = 0xFC
    }
}
