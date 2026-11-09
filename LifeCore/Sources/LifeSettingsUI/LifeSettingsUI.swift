import AppKit
import LifeCore

/// A form of controls for editing a `LifeSettings` value. Shared by the screen saver's
/// configure sheet and the app's preferences window.
public final class LifeSettingsView: NSView {

    public private(set) var settings: LifeSettings
    /// Called after every control change with the updated settings.
    public var onChange: ((LifeSettings) -> Void)?

    private let intervalSlider = NSSlider()
    private let intervalValue = NSTextField(labelWithString: "")
    private let cellSizeSlider = NSSlider()
    private let cellSizeValue = NSTextField(labelWithString: "")
    private let densitySlider = NSSlider()
    private let densityValue = NSTextField(labelWithString: "")
    private let palettePopUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private let wrapCheckbox = NSButton(checkboxWithTitle: "Wrap around the edges", target: nil, action: nil)

    public init(settings: LifeSettings) {
        self.settings = settings.clamped()
        super.init(frame: .zero)
        buildControls()
        updateControls()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func setSettings(_ newSettings: LifeSettings) {
        settings = newSettings.clamped()
        updateControls()
    }

    private func buildControls() {
        configure(intervalSlider, range: LifeSettings.stepIntervalRange, action: #selector(intervalChanged))
        configure(cellSizeSlider, range: LifeSettings.cellSizeRange, action: #selector(cellSizeChanged))
        cellSizeSlider.numberOfTickMarks = Int((LifeSettings.cellSizeRange.upperBound - LifeSettings.cellSizeRange.lowerBound) / 4) + 1
        cellSizeSlider.allowsTickMarkValuesOnly = true
        configure(densitySlider, range: LifeSettings.seedDensityRange, action: #selector(densityChanged))

        for palette in LifePalette.allCases {
            palettePopUp.addItem(withTitle: palette.displayName)
            palettePopUp.lastItem?.representedObject = palette.rawValue
        }
        palettePopUp.target = self
        palettePopUp.action = #selector(paletteChanged)

        wrapCheckbox.target = self
        wrapCheckbox.action = #selector(wrapChanged)

        for value in [intervalValue, cellSizeValue, densityValue] {
            value.alignment = .right
            value.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            value.widthAnchor.constraint(equalToConstant: 56).isActive = true
        }

        let grid = NSGridView(views: [
            [label("Generation every:"), intervalSlider, intervalValue],
            [label("Cell size:"), cellSizeSlider, cellSizeValue],
            [label("Initial density:"), densitySlider, densityValue],
            [label("Colours:"), palettePopUp, NSGridCell.emptyContentView],
            [NSGridCell.emptyContentView, wrapCheckbox, NSGridCell.emptyContentView],
        ])
        grid.rowSpacing = 10
        grid.columnSpacing = 8
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).width = 220
        grid.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: trailingAnchor),
            grid.topAnchor.constraint(equalTo: topAnchor),
            grid.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func configure(_ slider: NSSlider, range: ClosedRange<Double>, action: Selector) {
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.isContinuous = true
        slider.target = self
        slider.action = action
    }

    private func label(_ text: String) -> NSTextField {
        NSTextField(labelWithString: text)
    }

    private func updateControls() {
        intervalSlider.doubleValue = settings.stepInterval
        cellSizeSlider.doubleValue = settings.cellSize
        densitySlider.doubleValue = settings.seedDensity
        palettePopUp.selectItem(at: LifePalette.allCases.firstIndex(of: settings.palette) ?? 0)
        wrapCheckbox.state = settings.wrapsEdges ? .on : .off
        updateValueLabels()
    }

    private func updateValueLabels() {
        intervalValue.stringValue = String(format: "%.2f s", settings.stepInterval)
        cellSizeValue.stringValue = "\(Int(settings.cellSize)) pt"
        densityValue.stringValue = "\(Int((settings.seedDensity * 100).rounded()))%"
    }

    private func publish() {
        updateValueLabels()
        onChange?(settings)
    }

    @objc private func intervalChanged() {
        settings.stepInterval = (intervalSlider.doubleValue * 20).rounded() / 20
        publish()
    }

    @objc private func cellSizeChanged() {
        settings.cellSize = cellSizeSlider.doubleValue.rounded()
        publish()
    }

    @objc private func densityChanged() {
        settings.seedDensity = (densitySlider.doubleValue * 100).rounded() / 100
        publish()
    }

    @objc private func paletteChanged() {
        if let raw = palettePopUp.selectedItem?.representedObject as? String, let palette = LifePalette(rawValue: raw) {
            settings.palette = palette
        }
        publish()
    }

    @objc private func wrapChanged() {
        settings.wrapsEdges = wrapCheckbox.state == .on
        publish()
    }
}

/// A modal-style window wrapping `LifeSettingsView` with OK and Cancel buttons, for use as a
/// screen saver configure sheet.
public final class LifeSettingsSheet: NSObject {

    public let window: NSWindow
    private let form: LifeSettingsView
    private let completion: (LifeSettings?) -> Void

    /// `completion` receives the new settings on OK, or nil on Cancel, after the window has been dismissed.
    public init(settings: LifeSettings, completion: @escaping (LifeSettings?) -> Void) {
        form = LifeSettingsView(settings: settings)
        self.completion = completion
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
                          styleMask: [.titled], backing: .buffered, defer: false)
        super.init()

        window.title = "Gaucho Life Options"
        window.isReleasedWhenClosed = false

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        cancel.keyEquivalent = "\u{1b}"
        let ok = NSButton(title: "OK", target: self, action: #selector(accept(_:)))
        ok.keyEquivalent = "\r"
        let buttons = NSStackView(views: [cancel, ok])
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.spacing = 12

        let stack = NSStackView(views: [form, buttons])
        stack.orientation = .vertical
        stack.alignment = .trailing
        stack.spacing = 20
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            form.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 20),
        ])
        window.contentView = content
        window.setContentSize(content.fittingSize)
        window.defaultButtonCell = ok.cell as? NSButtonCell
    }

    @objc private func accept(_ sender: Any?) {
        dismiss(with: form.settings)
    }

    @objc private func cancel(_ sender: Any?) {
        dismiss(with: nil)
    }

    private func dismiss(with result: LifeSettings?) {
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            window.orderOut(nil)
        }
        completion(result)
    }
}
