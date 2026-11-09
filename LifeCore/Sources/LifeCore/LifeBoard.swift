import Foundation

/// A Game of Life grid. Cell (0, 0) is the bottom-left corner; `y` grows upward to match AppKit drawing.
public struct LifeBoard: Equatable {
    /// Ages saturate here; the palette has one colour per age up to this value.
    public static let maxAge: UInt8 = 64

    public let width: Int
    public let height: Int
    public var wrapsEdges: Bool

    public private(set) var alive: [Bool]
    /// 0 for a dead cell, otherwise the number of consecutive generations the cell has lived (capped at `maxAge`).
    public private(set) var age: [UInt8]

    private var scratch: [Bool]

    public init(width: Int, height: Int, wrapsEdges: Bool = false) {
        self.width = max(0, width)
        self.height = max(0, height)
        self.wrapsEdges = wrapsEdges
        let count = self.width * self.height
        alive = [Bool](repeating: false, count: count)
        age = [UInt8](repeating: 0, count: count)
        scratch = alive
    }

    public init<G: RandomNumberGenerator>(width: Int, height: Int, density: Double, wrapsEdges: Bool = false, using generator: inout G) {
        self.init(width: width, height: height, wrapsEdges: wrapsEdges)
        for index in alive.indices where Double.random(in: 0..<1, using: &generator) < density {
            alive[index] = true
            age[index] = 1
        }
    }

    public init(width: Int, height: Int, density: Double, wrapsEdges: Bool = false) {
        var generator = SystemRandomNumberGenerator()
        self.init(width: width, height: height, density: density, wrapsEdges: wrapsEdges, using: &generator)
    }

    public init?(width: Int, height: Int, alive: [Bool], wrapsEdges: Bool = false) {
        guard width >= 0, height >= 0, alive.count == width * height else { return nil }
        self.init(width: width, height: height, wrapsEdges: wrapsEdges)
        self.alive = alive
        age = alive.map { $0 ? 1 : 0 }
    }

    public var population: Int { alive.reduce(0) { $0 + ($1 ? 1 : 0) } }
    public var isEmpty: Bool { !alive.contains(true) }

    public subscript(x: Int, y: Int) -> Bool {
        get {
            guard contains(x: x, y: y) else { return false }
            return alive[y * width + x]
        }
        set {
            guard contains(x: x, y: y) else { return }
            let index = y * width + x
            alive[index] = newValue
            age[index] = newValue ? 1 : 0
        }
    }

    public mutating func toggle(x: Int, y: Int) {
        self[x, y] = !self[x, y]
    }

    public func contains(x: Int, y: Int) -> Bool {
        x >= 0 && x < width && y >= 0 && y < height
    }

    /// Number of live neighbours of a cell, honouring `wrapsEdges`. On boards narrower or shorter than
    /// three cells a wrapped neighbour can coincide with another neighbour or the cell itself; those
    /// positions are counted once and the cell never counts itself.
    public func livingNeighbors(x: Int, y: Int) -> Int {
        guard contains(x: x, y: y) else { return 0 }
        if width >= 3 && height >= 3 {
            return fastNeighbors(x: x, y: y)
        }
        var seen: [Int] = []
        seen.reserveCapacity(8)
        var count = 0
        for dy in -1...1 {
            for dx in -1...1 where dx != 0 || dy != 0 {
                guard let (nx, ny) = neighbor(x: x + dx, y: y + dy) else { continue }
                let index = ny * width + nx
                if (nx == x && ny == y) || seen.contains(index) { continue }
                seen.append(index)
                if alive[index] { count += 1 }
            }
        }
        return count
    }

    private func neighbor(x: Int, y: Int) -> (Int, Int)? {
        if contains(x: x, y: y) { return (x, y) }
        guard wrapsEdges else { return nil }
        return (((x % width) + width) % width, ((y % height) + height) % height)
    }

    @inline(__always)
    private func fastNeighbors(x: Int, y: Int) -> Int {
        let left = x > 0 ? x - 1 : (wrapsEdges ? width - 1 : -1)
        let right = x + 1 < width ? x + 1 : (wrapsEdges ? 0 : -1)
        let below = y > 0 ? y - 1 : (wrapsEdges ? height - 1 : -1)
        let above = y + 1 < height ? y + 1 : (wrapsEdges ? 0 : -1)
        var count = 0
        let row = y * width
        if left >= 0 && alive[row + left] { count += 1 }
        if right >= 0 && alive[row + right] { count += 1 }
        if below >= 0 {
            let r = below * width
            if alive[r + x] { count += 1 }
            if left >= 0 && alive[r + left] { count += 1 }
            if right >= 0 && alive[r + right] { count += 1 }
        }
        if above >= 0 {
            let r = above * width
            if alive[r + x] { count += 1 }
            if left >= 0 && alive[r + left] { count += 1 }
            if right >= 0 && alive[r + right] { count += 1 }
        }
        return count
    }

    /// Advances one generation using Conway's B3/S23 rules.
    public mutating func step() {
        guard width > 0, height > 0 else { return }
        let fast = width >= 3 && height >= 3
        for y in 0..<height {
            let row = y * width
            for x in 0..<width {
                let index = row + x
                let n = fast ? fastNeighbors(x: x, y: y) : livingNeighbors(x: x, y: y)
                scratch[index] = alive[index] ? (n == 2 || n == 3) : (n == 3)
            }
        }
        swap(&alive, &scratch)
        for index in age.indices {
            age[index] = alive[index] ? min(age[index] &+ 1, Self.maxAge) : 0
        }
    }

    public static func == (lhs: LifeBoard, rhs: LifeBoard) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.wrapsEdges == rhs.wrapsEdges
            && lhs.alive == rhs.alive && lhs.age == rhs.age
    }
}
