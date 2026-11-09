import LifeCore

/// Deterministic generator so tests that seed random boards are repeatable.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Builds a board from rows of text, top row first. `#` is alive, anything else is dead.
func board(_ rows: [String], wrapsEdges: Bool = false) -> LifeBoard {
    let height = rows.count
    let width = rows[0].count
    var alive = [Bool](repeating: false, count: width * height)
    for (rowIndex, row) in rows.enumerated() {
        // Row 0 in the text is the top of the picture, which is the highest y on the board.
        let y = height - 1 - rowIndex
        for (x, ch) in row.enumerated() where ch == "#" {
            alive[y * width + x] = true
        }
    }
    return LifeBoard(width: width, height: height, alive: alive, wrapsEdges: wrapsEdges)!
}

func picture(_ board: LifeBoard) -> [String] {
    (0..<board.height).reversed().map { y in
        String((0..<board.width).map { x in board[x, y] ? "#" : "." })
    }
}
