//
//  LifeView.swift
//  Gaucho Life
//
//  Created by Mike Piatek-Jimenez on 9/10/18.
//  Copyright © 2018 Gaucho Software, LLC.
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

import Cocoa
import LifeCore

protocol LifeViewDelegate: AnyObject {
    func lifeView(_ view: LifeView, setCellAtX x: Int, y: Int, alive: Bool)
}

/// Draws a board and lets the user paint cells with the mouse.
public class LifeView: NSView {

    weak var delegate: LifeViewDelegate?

    private var board: LifeBoard?
    private var palette: LifePalette = .rainbow
    private var cellSize: CGFloat = 24

    /// The state being painted during the current drag, decided by the cell under the initial click.
    private var paintingAlive: Bool?

    func display(board: LifeBoard?, palette: LifePalette, cellSize: Double) {
        self.board = board
        self.palette = palette
        self.cellSize = CGFloat(cellSize)
        needsDisplay = true
    }

    public override var isOpaque: Bool { true }
    public override var acceptsFirstResponder: Bool { true }

    /// Let a click on an inactive window paint straight away instead of only activating the window.
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    public override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        if let board {
            LifeRenderer.draw(board, palette: palette, cellSize: cellSize, in: context, bounds: bounds)
        } else {
            context.setFillColor(LifeRenderer.backgroundColor)
            context.fill(bounds)
        }
    }

    // MARK: Mouse painting

    public override func mouseDown(with event: NSEvent) {
        guard let board, let cell = cell(for: event) else { return }
        let alive = !board[cell.x, cell.y]
        paintingAlive = alive
        delegate?.lifeView(self, setCellAtX: cell.x, y: cell.y, alive: alive)
    }

    public override func mouseDragged(with event: NSEvent) {
        guard let board, let paintingAlive, let cell = cell(for: event), board[cell.x, cell.y] != paintingAlive else { return }
        delegate?.lifeView(self, setCellAtX: cell.x, y: cell.y, alive: paintingAlive)
    }

    public override func mouseUp(with event: NSEvent) {
        paintingAlive = nil
    }

    private func cell(for event: NSEvent) -> (x: Int, y: Int)? {
        guard let board else { return nil }
        let point = convert(event.locationInWindow, from: nil)
        return LifeLayout(board: board, cellSize: cellSize, bounds: bounds).cell(at: point)
    }

    // MARK: Keyboard

    /// The Simulation menu's key equivalents normally handle these first; this covers the case
    /// where the key reaches the view directly.
    public override func keyDown(with event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers, let scalar = characters.unicodeScalars.first else {
            return super.keyDown(with: event)
        }
        switch Int(scalar.value) {
        case 0x20:
            NSApp.sendAction(Selector(("togglePause:")), to: nil, from: self)
        case NSRightArrowFunctionKey:
            NSApp.sendAction(Selector(("stepForward:")), to: nil, from: self)
        default:
            super.keyDown(with: event)
        }
    }
}
