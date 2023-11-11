
import Foundation

extension Array where Element == UInt8 {
    
    /// Splits the receiver into a sequence of sub-arrays of at most`maxCount` elements,
    /// if the receiver has at least maxCount elements
    func split(_ maxCount: Int) -> [Self]{
        if self.count <= maxCount {
            return [self]
        }
        return stride(from: 0, to: self.count, by: maxCount).map {
            Array(self[$0 ..< Swift.min($0 + maxCount, count)])
        }
    }
}
