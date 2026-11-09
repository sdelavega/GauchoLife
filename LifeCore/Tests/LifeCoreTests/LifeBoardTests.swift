import XCTest
@testable import LifeCore

final class LifeBoardTests: XCTestCase {

    func testEmptyBoardHasRequestedSizeAndNoLife() {
        let b = LifeBoard(width: 5, height: 3)
        XCTAssertEqual(b.width, 5)
        XCTAssertEqual(b.height, 3)
        XCTAssertEqual(b.alive.count, 15)
        XCTAssertEqual(b.age.count, 15)
        XCTAssertTrue(b.isEmpty)
        XCTAssertEqual(b.population, 0)
    }

    func testInitFromAliveArrayRejectsWrongCount() {
        XCTAssertNil(LifeBoard(width: 3, height: 3, alive: [true, false]))
        XCTAssertNotNil(LifeBoard(width: 3, height: 3, alive: [Bool](repeating: false, count: 9)))
    }

    func testRandomBoardRespectsDensityApproximately() {
        var rng = SplitMix64(seed: 42)
        let b = LifeBoard(width: 200, height: 200, density: 0.125, using: &rng)
        let fraction = Double(b.population) / 40_000
        XCTAssertEqual(fraction, 0.125, accuracy: 0.01)
    }

    func testRandomBoardIsDeterministicForSameSeed() {
        var a = SplitMix64(seed: 7)
        var b = SplitMix64(seed: 7)
        XCTAssertEqual(LifeBoard(width: 20, height: 10, density: 0.3, using: &a),
                       LifeBoard(width: 20, height: 10, density: 0.3, using: &b))
    }

    func testNewbornCellsStartAtAgeOne() {
        var rng = SplitMix64(seed: 1)
        let b = LifeBoard(width: 10, height: 10, density: 0.5, using: &rng)
        for i in 0..<100 {
            XCTAssertEqual(b.age[i], b.alive[i] ? 1 : 0)
        }
    }

    func testSubscriptSetAndToggle() {
        var b = LifeBoard(width: 4, height: 4)
        b[1, 2] = true
        XCTAssertTrue(b[1, 2])
        XCTAssertEqual(b.age[2 * 4 + 1], 1)
        b.toggle(x: 1, y: 2)
        XCTAssertFalse(b[1, 2])
        XCTAssertEqual(b.age[2 * 4 + 1], 0)
        b.toggle(x: 0, y: 0)
        XCTAssertTrue(b[0, 0])
        XCTAssertEqual(b.population, 1)
    }

    func testOutOfRangeSubscriptReadsDead() {
        let b = board(["###", "###", "###"])
        XCTAssertFalse(b[-1, 0])
        XCTAssertFalse(b[3, 0])
        XCTAssertFalse(b[0, 3])
    }

    // MARK: Neighbor counting

    func testEdgeCellsDoNotSeeNeighborsOnTheOppositeSide() {
        // Regression: the original flat-index implementation let a cell at x == 0
        // count the cell at x == width - 1 on the row below as a neighbor.
        let b = board([
            "...#",
            "#...",
            "...#",
        ])
        XCTAssertEqual(b.livingNeighbors(x: 0, y: 1), 0)
        XCTAssertEqual(b.livingNeighbors(x: 3, y: 2), 0)
    }

    func testCornerCellCountsOnlyThreeInBoardNeighbors() {
        let b = board([
            "##.",
            "##.",
            "...",
        ])
        XCTAssertEqual(b.livingNeighbors(x: 0, y: 2), 3)
    }

    func testWrappedBoardSeesNeighborsAcrossEdges() {
        let b = board([
            "...#",
            "#...",
            "...#",
        ], wrapsEdges: true)
        // (0,1) wraps to see (3,2) and (3,0)
        XCTAssertEqual(b.livingNeighbors(x: 0, y: 1), 2)
    }

    func testWrappedSingleRowDoesNotDoubleCountItself() {
        let b = board(["#.."], wrapsEdges: true)
        // Height 1 with wrap: up and down both land on the same row. Neighbors must be
        // the two distinct horizontal cells only, which are both dead.
        XCTAssertEqual(b.livingNeighbors(x: 0, y: 0), 0)
    }

    // MARK: Rules

    func testBlinkerOscillatesWithPeriodTwo() {
        var b = board([
            ".....",
            "..#..",
            "..#..",
            "..#..",
            ".....",
        ])
        let start = b
        b.step()
        XCTAssertEqual(picture(b), [
            ".....",
            ".....",
            ".###.",
            ".....",
            ".....",
        ])
        b.step()
        XCTAssertEqual(b.alive, start.alive)
    }

    func testBlockIsStillLife() {
        var b = board([
            "....",
            ".##.",
            ".##.",
            "....",
        ])
        let start = b
        b.step()
        XCTAssertEqual(b.alive, start.alive)
    }

    func testGliderTranslatesByOneDiagonalEveryFourSteps() {
        var b = board([
            ".#......",
            "..#.....",
            "###.....",
            "........",
            "........",
            "........",
            "........",
            "........",
        ])
        for _ in 0..<4 { b.step() }
        XCTAssertEqual(picture(b), [
            "........",
            "..#.....",
            "...#....",
            ".###....",
            "........",
            "........",
            "........",
            "........",
        ])
    }

    func testGliderCrossesWrappedEdge() {
        var b = board([
            "........",
            "........",
            "........",
            "........",
            "........",
            "......#.",
            ".......#",
            ".....###",
        ], wrapsEdges: true)
        let population = b.population
        for _ in 0..<8 { b.step() }
        // A glider on a torus never dies.
        XCTAssertEqual(b.population, population)
        XCTAssertTrue(b[0, 7] || b[1, 7] || b[0, 6] || b[1, 6] || b[0, 0] || b[1, 0] || b[7, 0] || b[7, 1],
                      "glider should have wrapped toward the opposite corner, got \(picture(b))")
    }

    func testSurvivingCellsAgeAndCapAtMaxAge() {
        var b = board([
            "....",
            ".##.",
            ".##.",
            "....",
        ])
        for _ in 0..<(Int(LifeBoard.maxAge) + 10) { b.step() }
        XCTAssertEqual(b.age[1 * 4 + 1], LifeBoard.maxAge)
        XCTAssertEqual(b.age[0], 0)
    }

    func testDyingCellResetsAgeToZero() {
        var b = board([
            ".....",
            "..#..",
            "..#..",
            "..#..",
            ".....",
        ])
        b.step()
        // The top and bottom cells of the vertical blinker died.
        XCTAssertEqual(b.age[3 * 5 + 2], 0)
        XCTAssertEqual(b.age[1 * 5 + 2], 0)
        // The centre survived and aged.
        XCTAssertEqual(b.age[2 * 5 + 2], 2)
        // The newly born side cells are age 1.
        XCTAssertEqual(b.age[2 * 5 + 1], 1)
    }

    func testStepOnZeroSizedBoardIsHarmless() {
        var b = LifeBoard(width: 0, height: 0)
        b.step()
        XCTAssertTrue(b.isEmpty)
    }
}
