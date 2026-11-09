//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// The application shell: a persistent navigation bar above the selected tab.
///
/// Tabs keep their own navigation coordinators, so routing, deep links and
/// playback behave exactly as they do with the system tab bar. A tab's view
/// is created the first time it is selected and then kept alive, so returning
/// to it restores its scroll position and selection without reloading.
struct CinemaShellView: View {

    /// The focus identifier of the bar's search button, and the identifier of
    /// the settings tab, which matches the one declared on `TabItem.settings`.
    static let searchTabID = "search"
    static let settingsTabID = "settings"

    private static let utilityTabIDs: Set<String> = [searchTabID, settingsTabID]

    @FocusState
    private var focusedNavigationItem: String?

    @State
    private var visitedTabIDs: Set<String> = []

    @ObservedObject
    var tabCoordinator: TabCoordinator

    let tabRoot: (TabCoordinator.TabData) -> AnyView

    private var primaryItems: [TabItem] {
        tabCoordinator.tabs
            .map(\.item)
            .filter { !Self.utilityTabIDs.contains($0.id) }
    }

    private var utilityItems: [TabItem] {
        tabCoordinator.tabs
            .map(\.item)
            .filter { Self.utilityTabIDs.contains($0.id) }
    }

    private func isSelected(_ tab: TabCoordinator.TabData) -> Bool {
        tab.item.id == tabCoordinator.selectedTabID
    }

    private func markSelectedTabVisited() {
        guard let id = tabCoordinator.selectedTabID else { return }

        visitedTabIDs.insert(id)
    }

    var body: some View {
        VStack(spacing: 0) {
            CinemaNavigationBar(
                items: primaryItems,
                utilityItems: utilityItems,
                selection: $tabCoordinator.selectedTabID,
                focus: $focusedNavigationItem
            ) {
                Task { await tabCoordinator.route(to: .cinemaSearch) }
            }

            ZStack {
                ForEach(tabCoordinator.tabs, id: \.item.id) { tab in
                    if visitedTabIDs.contains(tab.item.id) {
                        let isSelected = isSelected(tab)

                        tabRoot(tab)
                            .opacity(isSelected ? 1 : 0)
                            .disabled(!isSelected)
                            .allowsHitTesting(isSelected)
                            .accessibilityHidden(!isSelected)
                            .zIndex(isSelected ? 1 : 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onExitCommand {
                focusedNavigationItem = tabCoordinator.selectedTabID
            }
        }
        .background {
            Cinema.Palette.background
                .ignoresSafeArea()
        }
        .onAppear(perform: markSelectedTabVisited)
        .onChange(of: tabCoordinator.selectedTabID) {
            markSelectedTabVisited()
        }
    }
}
