//
//  LifeSaverView.swift
//  Gaucho Life
//
//  Created by Mike Piatek-Jimenez on 11/15/22.
//  Copyright © 2022 Mike Piatek-Jimenez. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//     list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this
//     list of conditions and the following disclaimer in the documentation and/or
//     other materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors
//     may be used to endorse or promote products derived from this software without
//     specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
//  OF THE POSSIBILITY OF SUCH DAMAGE.
//

import LifeCore
import LifeSettingsUI
import ScreenSaver

/// There isn't a separate NSViewController for a ScreenSaverView, so this class performs controller actions as well.
@objc(LifeSaverView)
class LifeSaverView: ScreenSaverView {

    /// Views narrower than this are the System Settings thumbnail, where large cells leave room for only a dozen columns.
    private static let thumbnailWidthThreshold: CGFloat = 400
    private static let thumbnailCellSize: Double = 8

    private let store: LifeSettingsStore
    private let model: LifeModel
    private var storedSettings: LifeSettings {
        didSet { applySettings() }
    }
    private var sheet: LifeSettingsSheet?

    required init?(coder: NSCoder) {
        (store, storedSettings) = Self.loadSettings()
        model = LifeModel(settings: storedSettings)
        super.init(coder: coder)
        applySettings()
    }

    override init?(frame: NSRect, isPreview: Bool) {
        (store, storedSettings) = Self.loadSettings()
        model = LifeModel(settings: storedSettings)
        super.init(frame: frame, isPreview: isPreview)
        applySettings()
    }

    private static func loadSettings() -> (LifeSettingsStore, LifeSettings) {
        let module = Bundle(for: LifeSaverView.self).bundleIdentifier ?? "com.gauchosoft.Gaucho-Life"
        let defaults = ScreenSaverDefaults(forModuleWithName: module) ?? .standard
        let store = LifeSettingsStore(defaults: defaults)
        return (store, store.load())
    }

    /// Pushes the stored settings into the model, shrinking cells when the view is only a thumbnail.
    /// Cell size is decided from the view's actual size rather than `isPreview`, so the result is right
    /// even when the screen saver host reports `isPreview` inconsistently.
    private func applySettings() {
        var effective = storedSettings
        if bounds.width < Self.thumbnailWidthThreshold {
            effective.cellSize = min(effective.cellSize, Self.thumbnailCellSize)
        }
        model.settings = effective
        animationTimeInterval = effective.stepInterval
        model.resizeIfNeeded(for: bounds.size)
        needsDisplay = true
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        applySettings()
    }

    override func draw(_ rect: NSRect) {
        super.draw(rect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        if let board = model.board {
            LifeRenderer.draw(board, palette: model.settings.palette, cellSize: model.settings.cellSize, in: context, bounds: bounds)
        } else {
            context.setFillColor(LifeRenderer.backgroundColor)
            context.fill(bounds)
        }
    }

    override func animateOneFrame() {
        super.animateOneFrame()
        model.resizeIfNeeded(for: bounds.size)
        model.step()
        needsDisplay = true
    }

    // MARK: Configure sheet

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        let sheet = LifeSettingsSheet(settings: storedSettings) { [weak self] result in
            guard let self else { return }
            if let result {
                self.store.save(result)
                self.storedSettings = result
                self.model.reset()
            }
            // Release the sheet after its own dismissal has fully unwound.
            DispatchQueue.main.async { self.sheet = nil }
        }
        self.sheet = sheet
        return sheet.window
    }
}
