import CoreGraphics
import Foundation

/// A colour ramp indexed by cell age.
public enum LifePalette: String, CaseIterable, Codable, Sendable {
    case rainbow
    case ember
    case ocean
    case forest
    case monochrome

    public var displayName: String {
        switch self {
        case .rainbow: return "Rainbow"
        case .ember: return "Ember"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .monochrome: return "Monochrome"
        }
    }

    /// RGB stops, evenly spaced from newborn (first) to oldest (last).
    var stops: [(r: Double, g: Double, b: Double)] {
        switch self {
        case .rainbow:
            return [(1, 0, 0), (1, 0.5, 0), (1, 1, 0), (0, 1, 0), (0, 0, 1), (0.5, 0, 0.5)]
        case .ember:
            return [(0.55, 0.05, 0.02), (0.9, 0.25, 0.05), (1, 0.6, 0.1), (1, 0.9, 0.5), (1, 1, 0.9)]
        case .ocean:
            return [(0.05, 0.15, 0.5), (0.05, 0.45, 0.75), (0.1, 0.75, 0.8), (0.6, 0.95, 0.95)]
        case .forest:
            return [(0.05, 0.3, 0.1), (0.15, 0.6, 0.2), (0.55, 0.85, 0.25), (0.95, 0.95, 0.5)]
        case .monochrome:
            return [(0.45, 0.45, 0.5), (1, 1, 1)]
        }
    }

    /// One colour per possible age, so `colorTable[age]` is valid for `0...LifeBoard.maxAge`.
    /// Index 0 (a dead cell) is never drawn but is filled so the table can be indexed by age directly.
    public var colorTable: [CGColor] {
        Self.tables[self]!
    }

    private static let tables: [LifePalette: [CGColor]] = {
        var result: [LifePalette: [CGColor]] = [:]
        for palette in LifePalette.allCases {
            result[palette] = palette.makeTable()
        }
        return result
    }()

    private func makeTable() -> [CGColor] {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let stops = self.stops
        let maxAge = Int(LifeBoard.maxAge)
        return (0...maxAge).map { age in
            // Age 1 is the first stop, maxAge the last; age 0 reuses the first stop.
            let t = maxAge > 1 ? Double(max(age, 1) - 1) / Double(maxAge - 1) : 0
            let scaled = t * Double(stops.count - 1)
            let index = min(Int(scaled), stops.count - 2)
            let fraction = scaled - Double(index)
            let a = stops[index], b = stops[index + 1]
            let components: [CGFloat] = [
                CGFloat(a.r + (b.r - a.r) * fraction),
                CGFloat(a.g + (b.g - a.g) * fraction),
                CGFloat(a.b + (b.b - a.b) * fraction),
                1,
            ]
            return CGColor(colorSpace: space, components: components)!
        }
    }
}
