//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Moves focus to the first element of a collection grid on request.
///
/// Grid cells live in their own hosting views and are created after the
/// data arrives, so a focus state set while a cell is being inserted is
/// ignored by the focus system. Each request carries a token; the first
/// cell takes it either when the token changes or, if the cell is created
/// after the request, when it appears. It clears its focus before taking
/// it, which guarantees a transition the focus system acts on.
@MainActor
final class CinemaGridFocus: ObservableObject {

    @Published
    private(set) var token: UUID?

    private(set) var consumedToken: UUID?

    var hasPendingRequest: Bool {
        guard let token else { return false }

        return token != consumedToken
    }

    func requestFirstElement() {
        token = UUID()
    }

    func consume() {
        consumedToken = token
    }
}

private struct CinemaFirstElementFocusModifier: ViewModifier {

    @EnvironmentObject
    private var gridFocus: CinemaGridFocus

    @FocusState
    private var isFocused: Bool

    private func takeFocus() {
        gridFocus.consume()
        isFocused = false

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            isFocused = true
        }
    }

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: gridFocus.token) {
                takeFocus()
            }
            .onAppear {
                if gridFocus.hasPendingRequest {
                    takeFocus()
                }
            }
    }
}

extension View {

    /// Marks the first element of a grid as the target of `CinemaGridFocus` requests.
    func cinemaFirstElementFocus() -> some View {
        modifier(CinemaFirstElementFocusModifier())
    }
}
