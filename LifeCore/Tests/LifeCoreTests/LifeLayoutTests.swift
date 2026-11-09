import XCTest
@testable import LifeCore

final class LifeLayoutTests: XCTestCase {

    func testBoardIsCenteredInBounds() {
        let b = LifeBoard(width: 10, height: 5)
        let layout = LifeLayout(board: b, cellSize: 10, bounds: CGRect(x: 0, y: 0, width: 108, height: 56))
        XCTAssertEqual(layout.origin.x, 4)
        XCTAssertEqual(layout.origin.y, 3)
        XCTAssertEqual(layout.rect(forX: 0, y: 0), CGRect(x: 4, y: 3, width: 10, height: 10))
        XCTAssertEqual(layout.rect(forX: 9, y: 4), CGRect(x: 94, y: 43, width: 10, height: 10))
    }

    func testCellAtPointInvertsRect() {
        let b = LifeBoard(width: 10, height: 5)
        let layout = LifeLayout(board: b, cellSize: 10, bounds: CGRect(x: 0, y: 0, width: 108, height: 56))
        XCTAssertEqual(layout.cell(at: CGPoint(x: 5, y: 4))?.x, 0)
        XCTAssertEqual(layout.cell(at: CGPoint(x: 5, y: 4))?.y, 0)
        XCTAssertEqual(layout.cell(at: CGPoint(x: 99, y: 52))?.x, 9)
        XCTAssertEqual(layout.cell(at: CGPoint(x: 99, y: 52))?.y, 4)
        XCTAssertNil(layout.cell(at: CGPoint(x: 1, y: 1)), "margin is outside the board")
        XCTAssertNil(layout.cell(at: CGPoint(x: 105, y: 30)))
    }

    func testRendererDrawsLiveCellsWithPaletteColor() {
        let b = board(["#.", ".."])
        let width = 20, height = 20
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        LifeRenderer.draw(b, palette: .monochrome, cellSize: 10, in: ctx, bounds: CGRect(x: 0, y: 0, width: 20, height: 20))
        let data = ctx.data!.assumingMemoryBound(to: UInt8.self)
        func pixel(_ x: Int, _ y: Int) -> (UInt8, UInt8, UInt8) {
            // CGContext rows start at the top; board y == 1 is the top row.
            let row = height - 1 - y
            let i = (row * width + x) * 4
            return (data[i], data[i + 1], data[i + 2])
        }
        let live = pixel(5, 15)   // centre of cell (0,1)
        let dead = pixel(15, 5)   // centre of cell (1,0)
        XCTAssertGreaterThan(Int(live.0) + Int(live.1) + Int(live.2), 200)
        XCTAssertLessThan(Int(dead.0) + Int(dead.1) + Int(dead.2), 120)
    }
}
