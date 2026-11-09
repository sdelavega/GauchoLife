import CoreGraphics
import Foundation

/// Where a board's cells land inside a view, centred with equal margins.
public struct LifeLayout: Equatable {
    public let origin: CGPoint
    public let cellSize: CGFloat
    public let columns: Int
    public let rows: Int

    public init(board: LifeBoard, cellSize: CGFloat, bounds: CGRect) {
        self.cellSize = cellSize
        columns = board.width
        rows = board.height
        let used = CGSize(width: CGFloat(board.width) * cellSize, height: CGFloat(board.height) * cellSize)
        origin = CGPoint(x: bounds.minX + ((bounds.width - used.width) / 2).rounded(.down),
                         y: bounds.minY + ((bounds.height - used.height) / 2).rounded(.down))
    }

    public func rect(forX x: Int, y: Int) -> CGRect {
        CGRect(x: origin.x + CGFloat(x) * cellSize, y: origin.y + CGFloat(y) * cellSize, width: cellSize, height: cellSize)
    }

    /// The cell under a point in the same coordinate space as `bounds`, or nil if the point is in the margin.
    public func cell(at point: CGPoint) -> (x: Int, y: Int)? {
        let fx = (point.x - origin.x) / cellSize
        let fy = (point.y - origin.y) / cellSize
        guard fx >= 0, fy >= 0 else { return nil }
        let x = Int(fx.rounded(.down)), y = Int(fy.rounded(.down))
        guard x < columns, y < rows else { return nil }
        return (x, y)
    }
}

public enum LifeRenderer {
    public static let backgroundColor = CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                                components: [0.08, 0.08, 0.123, 1])!

    /// Fills `bounds` with the background and draws every live cell as a disc coloured by age.
    public static func draw(_ board: LifeBoard, palette: LifePalette, cellSize: CGFloat, in context: CGContext, bounds: CGRect) {
        context.saveGState()
        defer { context.restoreGState() }

        context.setFillColor(backgroundColor)
        context.fill(bounds)

        let layout = LifeLayout(board: board, cellSize: cellSize, bounds: bounds)
        let table = palette.colorTable
        var currentAge: UInt8 = 0
        for y in 0..<board.height {
            let row = y * board.width
            for x in 0..<board.width where board.alive[row + x] {
                let age = board.age[row + x]
                if age != currentAge {
                    context.setFillColor(table[Int(age)])
                    currentAge = age
                }
                context.fillEllipse(in: layout.rect(forX: x, y: y))
            }
        }
    }
}
