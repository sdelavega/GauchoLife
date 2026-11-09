import CoreGraphics
import Foundation

/// Owns a board and the rules for when to throw it away and start over.
public final class LifeModel {

    public enum ResetReason: Equatable {
        /// Every cell died.
        case extinct
        /// The board repeated with period one or two (still lifes and blinkers).
        case stagnant
        /// `generationLimit` was reached.
        case generationLimit
    }

    public var settings: LifeSettings {
        didSet { board?.wrapsEdges = settings.wrapsEdges }
    }

    public private(set) var board: LifeBoard?
    public private(set) var generation = 0
    /// Hard cap on generations before a reseed, so gliders and long-period patterns do not run forever.
    public var generationLimit = 500

    /// The live-cell layout of the previous one or two generations, most recent first.
    private var history: [[Bool]] = []

    public init(settings: LifeSettings = LifeSettings()) {
        self.settings = settings
    }

    /// Board dimensions that fit a view of the given size at the current cell size, or nil if not even one cell fits.
    public func boardSize(for viewSize: CGSize) -> (width: Int, height: Int)? {
        guard settings.cellSize > 0 else { return nil }
        let width = Int(viewSize.width / settings.cellSize)
        let height = Int(viewSize.height / settings.cellSize)
        guard width >= 1, height >= 1 else { return nil }
        return (width, height)
    }

    /// Reseeds when the view size or cell size no longer matches the board. Returns true if it did.
    @discardableResult
    public func resizeIfNeeded(for viewSize: CGSize) -> Bool {
        guard let size = boardSize(for: viewSize) else { return false }
        if let board, board.width == size.width, board.height == size.height { return false }
        reset(width: size.width, height: size.height)
        return true
    }

    public func reset(width: Int, height: Int) {
        board = LifeBoard(width: width, height: height, density: settings.seedDensity, wrapsEdges: settings.wrapsEdges)
        generation = 0
        history.removeAll(keepingCapacity: true)
    }

    /// Reseeds at the current size.
    public func reset() {
        guard let board else { return }
        reset(width: board.width, height: board.height)
    }

    /// Replaces the board with a specific layout (used by tests and for pasting patterns).
    public func load(_ newBoard: LifeBoard) {
        var b = newBoard
        b.wrapsEdges = settings.wrapsEdges
        board = b
        generation = 0
        history.removeAll(keepingCapacity: true)
    }

    /// Advances one generation. Returns the reason if that generation triggered a reseed.
    @discardableResult
    public func step() -> ResetReason? {
        guard board != nil else { return nil }
        let before = board!.alive
        board!.step()
        generation += 1

        let reason: ResetReason?
        if board!.isEmpty {
            reason = .extinct
        } else if board!.alive == before || (history.first.map { $0 == board!.alive } ?? false) {
            reason = .stagnant
        } else if generation >= generationLimit {
            reason = .generationLimit
        } else {
            reason = nil
        }

        if reason != nil {
            reset()
            return reason
        }

        history.insert(before, at: 0)
        if history.count > 1 { history.removeLast(history.count - 1) }
        return nil
    }

    public func toggle(x: Int, y: Int) {
        guard board != nil else { return }
        board!.toggle(x: x, y: y)
        history.removeAll(keepingCapacity: true)
    }

    public func setCell(x: Int, y: Int, alive: Bool) {
        guard board != nil else { return }
        board![x, y] = alive
        history.removeAll(keepingCapacity: true)
    }
}
