
import Foundation
import ScalesCore

struct RPiDisplay: ScalesCore.Display {
    
    init(width: CGFloat, height: CGFloat) {
        // TODO: Implement me
    }
    
    var font: ScalesCore.Font?
    
    func drawText(_ text: String, x: CGFloat, y: CGFloat) {
        print("Something tried to draw some text")
    }
}

