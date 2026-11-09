import XCTest
@testable import LifeCore

final class LifeSettingsTests: XCTestCase {

    func testDefaultsMatchOriginalScreenSaverBehaviour() {
        let s = LifeSettings()
        XCTAssertEqual(s.stepInterval, 0.75)
        XCTAssertEqual(s.cellSize, 24)
        XCTAssertEqual(s.palette, .rainbow)
        XCTAssertEqual(s.seedDensity, 0.125)
        XCTAssertFalse(s.wrapsEdges)
    }

    func testClampedPullsValuesIntoRange() {
        var s = LifeSettings()
        s.stepInterval = 0
        s.cellSize = 1000
        s.seedDensity = -1
        let c = s.clamped()
        XCTAssertEqual(c.stepInterval, LifeSettings.stepIntervalRange.lowerBound)
        XCTAssertEqual(c.cellSize, LifeSettings.cellSizeRange.upperBound)
        XCTAssertEqual(c.seedDensity, LifeSettings.seedDensityRange.lowerBound)
    }

    func testStoreRoundTripsThroughUserDefaults() throws {
        let suite = "LifeCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = LifeSettingsStore(defaults: defaults)
        XCTAssertEqual(store.load(), LifeSettings(), "empty defaults yield the defaults")

        var s = LifeSettings()
        s.stepInterval = 0.2
        s.cellSize = 12
        s.palette = .ocean
        s.seedDensity = 0.3
        s.wrapsEdges = true
        store.save(s)
        XCTAssertEqual(store.load(), s)
    }

    func testStoreClampsCorruptValues() throws {
        let suite = "LifeCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(-5.0, forKey: LifeSettingsStore.Key.cellSize)
        defaults.set("no-such-palette", forKey: LifeSettingsStore.Key.palette)
        let loaded = LifeSettingsStore(defaults: defaults).load()
        XCTAssertEqual(loaded.cellSize, LifeSettings.cellSizeRange.lowerBound)
        XCTAssertEqual(loaded.palette, .rainbow)
    }

    func testEveryPaletteHasOneColorPerAge() {
        for palette in LifePalette.allCases {
            XCTAssertEqual(palette.colorTable.count, Int(LifeBoard.maxAge) + 1, "\(palette)")
            XCTAssertFalse(palette.displayName.isEmpty)
        }
    }

    func testRainbowRunsFromRedToPurple() {
        let table = LifePalette.rainbow.colorTable
        let first = table[1].components!
        let last = table[Int(LifeBoard.maxAge)].components!
        XCTAssertEqual(first[0], 1, accuracy: 0.01)
        XCTAssertEqual(first[1], 0, accuracy: 0.01)
        XCTAssertGreaterThan(last[2], 0.4)
        XCTAssertGreaterThan(last[0], last[1])
    }
}
