//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

/// The compact global navigation bar: wordmark, primary destinations, search and profile.
struct CinemaNavigationBar: View {

    @Injected(\.currentUserSession)
    private var userSession

    let items: [TabItem]
    let utilityItems: [TabItem]
    @Binding
    var selection: String?
    let focus: FocusState<String?>.Binding

    private var brand: some View {
        HStack(spacing: Cinema.Spacing.s12) {
            Image(systemName: "play")
                .font(.system(size: 26, weight: .regular))

            // swiftlint:disable:next hard_coded_display_string
            Text("jellyfin cinema")
                .font(Cinema.Typography.brand)
        }
        .foregroundStyle(Cinema.Palette.primaryText)
        .accessibilityElement(children: .combine)
    }

    private func navigationButton(_ item: TabItem) -> some View {
        Button(item.displayTitle) {
            selection = item.id
        }
        .buttonStyle(CinemaUnderlineButtonStyle(isSelected: selection == item.id, fillsHeight: true))
        .focused(focus, equals: item.id)
        .accessibilityAddTraits(selection == item.id ? .isSelected : [])
    }

    private func utilityButton(_ item: TabItem) -> some View {
        Button {
            selection = item.id
        } label: {
            if item.id == CinemaShellView.settingsTabID, let userSession {
                // The server client builds the public image URL without touching
                // the keychain, which the authenticated client would do.
                UserProfileImage(
                    userID: userSession.user.id,
                    source: userSession.user.profileImageSource(client: userSession.server.client)
                )
                .frame(width: 52, height: 52)
            } else {
                Image(systemName: item.systemImage)
            }
        }
        .buttonStyle(CinemaIconButtonStyle(isBordered: false))
        .focused(focus, equals: item.id)
        .accessibilityLabel(item.displayTitle)
        .accessibilityAddTraits(selection == item.id ? .isSelected : [])
    }

    var body: some View {
        ZStack {
            HStack {
                brand
                Spacer()
            }

            HStack(spacing: Cinema.Spacing.s4) {
                ForEach(items, id: \.id) { item in
                    navigationButton(item)
                }
            }

            HStack(spacing: Cinema.Spacing.s8) {
                Spacer()

                ForEach(utilityItems, id: \.id) { item in
                    utilityButton(item)
                }
            }
        }
        .padding(.horizontal, Cinema.Layout.edgePadding)
        .frame(height: Cinema.Layout.navigationBarHeight)
        .frame(maxWidth: .infinity)
        .background(Cinema.Palette.background)
        .overlay(alignment: .bottom) {
            CinemaDivider()
        }
        .focusSection()
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}
