//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

// TODO: fix weird tvOS icon rendering
struct MainTabView: View {

    @InjectedObject(\.userSessionManager)
    private var userSessionManager

    @StateObject
    private var tabCoordinator: TabCoordinator

    init() {
        _tabCoordinator = StateObject(wrappedValue: Self.defaultTabCoordinator)
    }

    private static var defaultTabCoordinator: TabCoordinator {
        #if os(iOS)
        TabCoordinator {
            TabItem.contentGroup(provider: DefaultContentGroupProvider())
            TabItem.search
            TabItem.media
        }
        #else
        TabCoordinator {
            TabItem.cinemaCollection
            TabItem.cinemaFilms
            TabItem.cinemaSeries
            TabItem.cinemaPeople
            TabItem.cinemaCollections
            TabItem.settings
        }
        #endif
    }

    private func routePendingDeepLink(_ deepLink: DeepLink?) {
        guard let deepLink else { return }

        Task { @MainActor in
            let route = deepLink.route()
            await tabCoordinator.route(to: route)
        }
    }

    private func tabRoot(_ tab: TabCoordinator.TabData) -> some View {
        NavigationInjectionView(coordinator: tab.coordinator) {
            tab.item
                .content
                .withViewContext(.isTabRoot)
                #if os(iOS)
                .if(tabCoordinator.tabs.first?.item.id == tab.item.id) { view in
                    view.topBarTrailing {
                        FirstTabSettingsBarButton()
                    }
                }
                #endif
        }
        .environmentObject(tabCoordinator)
        .environment(\.tabItemSelected, tab.publisher)
    }

    private func tabView() -> some View {
        TabView(selection: $tabCoordinator.selectedTabID) {
            ForEach(tabCoordinator.tabs, id: \.item.id) { tab in
                Tab(
                    value: tab.item.id,
                    role: tab.item.id == TabItem.search.id ? .search : nil
                ) {
                    #if os(tvOS)
                    GeometryReader { _ in
                        tabRoot(tab)
                    }
                    .trackingFrame(for: .tabView)
                    #else
                    tabRoot(tab)
                    #endif
                } label: {
                    Label(
                        tab.item.displayTitle,
                        systemImage: tab.item.systemImage
                    )
                    .symbolRenderingMode(.monochrome)
                }
            }
        }
    }

    private func tabContent() -> some View {
        #if os(tvOS)
        CinemaShellView(tabCoordinator: tabCoordinator) { tab in
            GeometryReader { _ in
                tabRoot(tab)
            }
            .trackingFrame(for: .tabView)
            .eraseToAnyView()
        }
        #else
        tabView()
            .tabViewStyle(.sidebarAdaptable)
        #endif
    }

    var body: some View {
        tabContent()
            .onChange(of: userSessionManager.pendingDeepLink) {
                routePendingDeepLink(userSessionManager.consumePendingDeepLink())
            }
            .onReceive(userSessionManager.routePublisher) { route in
                Task { @MainActor in
                    await tabCoordinator.route(to: route)
                }
            }
    }
}

#if os(iOS)
private struct FirstTabSettingsBarButton: View {

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    var body: some View {
        if router.isRootOfPath,
           let userSession
        {
            SettingsBarButton(userSession: userSession) {
                router.route(to: .settings)
            }
        }
    }
}
#endif
