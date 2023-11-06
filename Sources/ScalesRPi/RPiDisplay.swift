
import Foundation
import ScalesCore
import LinuxSPI

struct RPiDisplay: ScalesCore.Display {
    var width: Int { 320 }
    var height: Int { 240 }
    func showFrame(_ frameBuffer: FrameBuffer) {
        // TODO: Implement me
        print("Display has been instructed to show frame buffer")
    }
    
    private func pixelsPacked565(pixels24: [Color24]) -> [UInt16] {
        pixels24.map { $0.packed565 }
    }
}
