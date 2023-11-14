
import XCTest
@testable import ScalesRPi

final class ArrayExtensionTests: XCTestCase {

    func testArraySplit() throws {
        let mockData: [UInt8] = .init(repeating: 128, count: 9000)
        let result = mockData.split(4096)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].count, 4096)
        XCTAssertEqual(result[1].count, 4096)
        XCTAssertEqual(result[2].count, 808)
    }
    
    func testToUInt8() throws {
        let mockData: [UInt16] = [0xC4F9]
        let result = mockData.toUInt8
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], 0xC4)
        XCTAssertEqual(result[1], 0xF9)
    }
}
