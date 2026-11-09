import Foundation

/// User-adjustable parameters shared by the screen saver and the windowed app.
public struct LifeSettings: Equatable, Codable, Sendable {
    /// Seconds between generations.
    public var stepInterval: Double
    /// Edge length of one cell, in points.
    public var cellSize: Double
    public var palette: LifePalette
    /// Fraction of cells alive in a freshly seeded board.
    public var seedDensity: Double
    /// Whether the board is a torus (edges wrap) or has hard walls.
    public var wrapsEdges: Bool

    public static let stepIntervalRange: ClosedRange<Double> = 0.05...2.0
    public static let cellSizeRange: ClosedRange<Double> = 4...64
    public static let seedDensityRange: ClosedRange<Double> = 0.02...0.6

    public init(stepInterval: Double = 0.75,
                cellSize: Double = 24,
                palette: LifePalette = .rainbow,
                seedDensity: Double = 0.125,
                wrapsEdges: Bool = false) {
        self.stepInterval = stepInterval
        self.cellSize = cellSize
        self.palette = palette
        self.seedDensity = seedDensity
        self.wrapsEdges = wrapsEdges
    }

    /// A copy with every numeric value pulled into its supported range.
    public func clamped() -> LifeSettings {
        var copy = self
        copy.stepInterval = min(max(stepInterval, Self.stepIntervalRange.lowerBound), Self.stepIntervalRange.upperBound)
        copy.cellSize = min(max(cellSize, Self.cellSizeRange.lowerBound), Self.cellSizeRange.upperBound)
        copy.seedDensity = min(max(seedDensity, Self.seedDensityRange.lowerBound), Self.seedDensityRange.upperBound)
        return copy
    }
}

/// Reads and writes `LifeSettings` in a `UserDefaults` instance. `ScreenSaverDefaults` is a
/// `UserDefaults` subclass, so the saver and the app share this code.
public final class LifeSettingsStore {
    public enum Key {
        public static let stepInterval = "stepInterval"
        public static let cellSize = "cellSize"
        public static let palette = "palette"
        public static let seedDensity = "seedDensity"
        public static let wrapsEdges = "wrapsEdges"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func load() -> LifeSettings {
        let fallback = LifeSettings()
        var settings = LifeSettings(
            stepInterval: defaults.object(forKey: Key.stepInterval) as? Double ?? fallback.stepInterval,
            cellSize: defaults.object(forKey: Key.cellSize) as? Double ?? fallback.cellSize,
            palette: (defaults.string(forKey: Key.palette)).flatMap(LifePalette.init(rawValue:)) ?? fallback.palette,
            seedDensity: defaults.object(forKey: Key.seedDensity) as? Double ?? fallback.seedDensity,
            wrapsEdges: defaults.object(forKey: Key.wrapsEdges) as? Bool ?? fallback.wrapsEdges
        )
        settings = settings.clamped()
        return settings
    }

    public func save(_ settings: LifeSettings) {
        let s = settings.clamped()
        defaults.set(s.stepInterval, forKey: Key.stepInterval)
        defaults.set(s.cellSize, forKey: Key.cellSize)
        defaults.set(s.palette.rawValue, forKey: Key.palette)
        defaults.set(s.seedDensity, forKey: Key.seedDensity)
        defaults.set(s.wrapsEdges, forKey: Key.wrapsEdges)
        defaults.synchronize()
    }
}
