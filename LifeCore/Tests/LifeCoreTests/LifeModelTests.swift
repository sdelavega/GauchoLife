import XCTest
@testable import LifeCore

final class LifeModelTests: XCTestCase {

    private func model(_ rows: [String], wraps: Bool = false) -> LifeModel {
        var settings = LifeSettings()
        settings.wrapsEdges = wraps
        let m = LifeModel(settings: settings)
        m.load(board(rows, wrapsEdges: wraps))
        return m
    }

    func testBoardSizeForViewUsesCellSize() {
        let m = LifeModel(settings: LifeSettings(cellSize: 24))
        let size = m.boardSize(for: CGSize(width: 640, height: 480))
        XCTAssertEqual(size?.width, 26)
        XCTAssertEqual(size?.height, 20)
        XCTAssertNil(m.boardSize(for: CGSize(width: 10, height: 480)))
    }

    func testResizeIfNeededCreatesThenKeepsBoard() {
        let m = LifeModel(settings: LifeSettings(cellSize: 10))
        XCTAssertNil(m.board)
        XCTAssertTrue(m.resizeIfNeeded(for: CGSize(width: 100, height: 50)))
        XCTAssertEqual(m.board?.width, 10)
        XCTAssertEqual(m.board?.height, 5)
        XCTAssertFalse(m.resizeIfNeeded(for: CGSize(width: 105, height: 59)))
        XCTAssertTrue(m.resizeIfNeeded(for: CGSize(width: 200, height: 50)))
        XCTAssertEqual(m.board?.width, 20)
    }

    func testChangingCellSizeInSettingsForcesResizeOnNextCheck() {
        let m = LifeModel(settings: LifeSettings(cellSize: 10))
        m.resizeIfNeeded(for: CGSize(width: 100, height: 100))
        m.settings.cellSize = 20
        XCTAssertTrue(m.resizeIfNeeded(for: CGSize(width: 100, height: 100)))
        XCTAssertEqual(m.board?.width, 5)
    }

    func testResetSeedsWithConfiguredDensity() {
        var settings = LifeSettings()
        settings.seedDensity = 0.5
        let m = LifeModel(settings: settings)
        m.reset(width: 100, height: 100)
        let fraction = Double(m.board!.population) / 10_000
        XCTAssertEqual(fraction, 0.5, accuracy: 0.05)
        XCTAssertEqual(m.generation, 0)
    }

    func testStepAdvancesGeneration() {
        let m = model([
            ".#......",
            "..#.....",
            "###.....",
            "........",
            "........",
            "........",
            "........",
            "........",
        ])
        XCTAssertEqual(m.generation, 0)
        XCTAssertNil(m.step())
        XCTAssertEqual(m.generation, 1)
    }

    func testExtinctBoardResetsImmediately() {
        let m = model(["...", ".#.", "..."])
        XCTAssertEqual(m.step(), .extinct)
        XCTAssertEqual(m.generation, 0)
        XCTAssertEqual(m.board?.width, 3)
    }

    func testStillLifeIsDetectedAsStagnantAfterOneRepeat() {
        let m = model([
            "....",
            ".##.",
            ".##.",
            "....",
        ])
        XCTAssertEqual(m.step(), .stagnant)
    }

    func testPeriodTwoOscillatorIsDetectedAsStagnant() {
        let m = model([
            ".....",
            "..#..",
            "..#..",
            "..#..",
            ".....",
        ])
        XCTAssertNil(m.step())
        XCTAssertEqual(m.step(), .stagnant)
    }

    func testGliderOnTorusRunsUntilGenerationLimit() {
        let m = model([
            "........",
            "........",
            "........",
            ".#......",
            "..#.....",
            "###.....",
            "........",
            "........",
        ], wraps: true)
        m.generationLimit = 40
        var reasons: [LifeModel.ResetReason] = []
        for _ in 0..<40 {
            if let r = m.step() { reasons.append(r) }
        }
        XCTAssertEqual(reasons, [.generationLimit])
    }

    func testUserEditClearsStagnationHistory() {
        // A blinker is period two. After one step the model remembers phase A; if the user then
        // edits the board, the next generation must not be compared against that stale memory.
        let m = model([
            ".......",
            ".......",
            "...#...",
            "...#...",
            "...#...",
            ".......",
            ".......",
        ])
        XCTAssertNil(m.step())
        m.toggle(x: 0, y: 0)          // lone cell far from the blinker, dies next step
        XCTAssertNil(m.step(), "board equals phase A again, but only because of the edit")
        XCTAssertNil(m.step())
        XCTAssertEqual(m.step(), .stagnant, "with history rebuilt, the oscillation is detected")
    }

    func testToggleOnModelWithoutBoardIsIgnored() {
        let m = LifeModel()
        m.toggle(x: 0, y: 0)
        XCTAssertNil(m.board)
    }

    func testSettingsWrapChangeAppliesToLiveBoard() {
        let m = model(["#..", "...", "..#"])
        XCTAssertEqual(m.board?.wrapsEdges, false)
        m.settings.wrapsEdges = true
        XCTAssertEqual(m.board?.wrapsEdges, true)
    }
}
