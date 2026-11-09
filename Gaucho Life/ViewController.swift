//
//  ViewController.swift
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

class ViewController: NSViewController, LifeViewDelegate, NSMenuItemValidation {

    private let model = LifeModel(settings: AppSettings.shared.settings)
    private var lifeView: LifeView? { view as? LifeView }

    private var timer: Timer?
    private var settingsObserver: NSObjectProtocol?
    private(set) var isPaused = false

    deinit {
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        lifeView?.delegate = self
        settingsObserver = NotificationCenter.default.addObserver(forName: AppSettings.didChange, object: nil, queue: .main) { [weak self] _ in
            self?.applySettings()
        }
        applySettings()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        startTimer()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopTimer()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        if model.resizeIfNeeded(for: view.bounds.size) {
            refresh()
        }
    }

    // MARK: Settings

    private func applySettings() {
        let settings = AppSettings.shared.settings
        let intervalChanged = settings.stepInterval != model.settings.stepInterval
        model.settings = settings
        model.resizeIfNeeded(for: view.bounds.size)
        if intervalChanged, timer != nil {
            stopTimer()
            startTimer()
        }
        refresh()
    }

    // MARK: Menu actions

    /// File > New Board.
    @IBAction func newDocument(_ sender: Any?) {
        model.reset()
        refresh()
    }

    @IBAction func togglePause(_ sender: Any?) {
        isPaused.toggle()
    }

    @IBAction func stepForward(_ sender: Any?) {
        model.step()
        refresh()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(togglePause(_:)) {
            menuItem.title = isPaused ? "Resume" : "Pause"
        }
        return true
    }

    // MARK: Timer

    private func startTimer() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: model.settings.stepInterval, repeats: true) { [weak self] _ in
            guard let self, !self.isPaused else { return }
            self.model.step()
            self.refresh()
        }
        // Common modes keep the simulation running while menus are open or the window is being resized.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        lifeView?.display(board: model.board, palette: model.settings.palette, cellSize: model.settings.cellSize)
    }

    // MARK: LifeViewDelegate

    func lifeView(_ view: LifeView, setCellAtX x: Int, y: Int, alive: Bool) {
        model.setCell(x: x, y: y, alive: alive)
        refresh()
    }
}
