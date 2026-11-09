//
//  AppDelegate.swift
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

import Foundation
import LifeCore

/// The app's single source of truth for user settings. Persists to `UserDefaults` and
/// broadcasts changes so the simulation can apply them live.
final class AppSettings {
    static let shared = AppSettings()
    static let didChange = Notification.Name("AppSettingsDidChange")

    private let store = LifeSettingsStore(defaults: .standard)

    var settings: LifeSettings {
        didSet {
            guard settings != oldValue else { return }
            store.save(settings)
            NotificationCenter.default.post(name: Self.didChange, object: self)
        }
    }

    private init() {
        settings = store.load()
    }
}
