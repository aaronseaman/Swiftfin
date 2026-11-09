//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI

/// The collection screen: the selected item's panel on the left and the
/// collection grid on the right. Moving focus through the grid updates the
/// panel; pressing a poster opens the full item page.
struct CinemaCollectionView<Library: PagingLibrary>: View where Library.Element == ItemEntry {

    private enum Focus: String {

        case firstElement = "cinemaCollection-firstElement"
    }

    @FocusState
    private var isGridFocused: Bool

    @FocusedValue(\.focusedPoster)
    private var focusedPoster

    @Namespace
    private var namespace

    @Router
    private var router

    @StateObject
    private var countsViewModel: CinemaCollectionCountsViewModel
    @StateObject
    private var focusCoordinator = FocusCoordinator()
    @StateObject
    private var gridProxy = CollectionVGridProxy()
    @StateObject
    private var panelViewModel = CinemaDetailPanelViewModel()
    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    @State
    private var displayType: LibraryDisplayType = .grid
    @State
    private var hasRequestedInitialFocus = false
    @State
    private var sortOption: CinemaSortOption?

    @TabItemSelected
    private var tabItemSelected

    private let title: String
    private let initialSort: CinemaSortOption?
    private let sortOptions: [CinemaSortOption]
    private let applySort: ((PagingLibraryViewModel<Library>, CinemaSortOption) -> Void)?

    init(
        library: Library,
        title: String,
        countTypes: [BaseItemKind],
        initialSort: CinemaSortOption?,
        sortOptions: [CinemaSortOption],
        applySort: ((PagingLibraryViewModel<Library>, CinemaSortOption) -> Void)?
    ) {
        self.title = title
        self.initialSort = initialSort
        self.sortOptions = sortOptions
        self.applySort = applySort
        self._countsViewModel = StateObject(wrappedValue: CinemaCollectionCountsViewModel(kinds: countTypes))
        self._viewModel = StateObject(wrappedValue: PagingLibraryViewModel(library: library))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                CinemaDetailPanel(viewModel: panelViewModel)
                    .frame(
                        width: (geometry.size.width * Cinema.Layout.detailPanelFraction).rounded(),
                        height: geometry.size.height,
                        alignment: .top
                    )
                    .clipped()
                    .focusSection()

                CinemaDivider(axis: .vertical)

                VStack(alignment: .leading, spacing: 0) {
                    header

                    libraryContent
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .focusSection()
                .focused($isGridFocused)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .background {
            Cinema.Palette.background
                .ignoresSafeArea()
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .environmentObject(focusCoordinator)
        .errorMessage($viewModel.error)
        .onChange(of: focusedPoster) {
            updateSelection()
        }
        .onChange(of: isGridFocused) {
            updateSelection()
        }
        .onChange(of: viewModel.elements) {
            selectFirstElementIfNeeded()
        }
        .onChange(of: viewModel.environment) {
            viewModel.refreshForEnvironmentChange()
        }
        .onChange(of: displayType) {
            gridProxy.redraw()
        }
        .onReceive(tabItemSelected) { event in
            if event.isRepeat, event.isRoot {
                gridProxy.scrollToTop(animated: true)
            }
        }
        .onFirstAppear {
            sortOption = initialSort
            viewModel.refresh()
            countsViewModel.refresh()
        }
    }

    // MARK: - Header

    private var countsLine: some View {
        DotHStack {
            if let total = countsViewModel.total {
                Text(L10n.titlesWithCount(total.formatted()))
            }

            ForEach(countsViewModel.counts) { count in
                Text(count.displayTitle)
            }
        }
        .font(Cinema.Typography.meta)
        .foregroundStyle(Cinema.Palette.secondaryText)
        .lineLimit(1)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Cinema.Spacing.s24) {
            VStack(alignment: .leading, spacing: Cinema.Spacing.s8) {
                Text(title)
                    .font(Cinema.Typography.display)
                    .foregroundStyle(Cinema.Palette.primaryText)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)

                countsLine
            }

            Spacer(minLength: Cinema.Spacing.s24)

            HStack(spacing: Cinema.Spacing.s8) {
                layoutButton(.grid, systemImage: "square.grid.2x2")
                layoutButton(.list, systemImage: "list.bullet")

                if sortOptions.isNotEmpty {
                    CinemaDivider(axis: .vertical)
                        .frame(height: 32)
                        .padding(.horizontal, Cinema.Spacing.s8)

                    sortMenu
                }
            }
            .padding(.top, Cinema.Spacing.s12)
        }
        .padding(.leading, Cinema.Spacing.s48)
        .padding(.trailing, Cinema.Layout.edgePadding)
        .padding(.top, Cinema.Spacing.s32)
        .padding(.bottom, Cinema.Spacing.s24)
        .focusSection()
    }

    private func layoutButton(_ type: LibraryDisplayType, systemImage: String) -> some View {
        Button {
            displayType = type
        } label: {
            Label(type.displayTitle, systemImage: systemImage)
        }
        .buttonStyle(CinemaIconButtonStyle())
        .isSelected(displayType == type)
        .accessibilityAddTraits(displayType == type ? .isSelected : [])
    }

    private var sortMenu: some View {
        Menu {
            ForEach(sortOptions) { option in
                Button {
                    select(option)
                } label: {
                    if option == sortOption {
                        Label(option.displayTitle, systemImage: "checkmark")
                    } else {
                        Text(option.displayTitle)
                    }
                }
            }
        } label: {
            HStack(spacing: Cinema.Spacing.s8) {
                Text(sortOption?.displayTitle ?? L10n.sort)

                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .menuStyle(.button)
        .buttonStyle(CinemaTextButtonStyle())
        .accessibilityLabel(L10n.sort)
        .accessibilityValue(sortOption?.displayTitle ?? L10n.sort)
    }

    // MARK: - Library

    private var libraryContent: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .refreshing:
                ProgressView()
                    .coordinatedFocus(.placeholder)

            case .content:
                if viewModel.displayedElements.isEmpty {
                    ContentUnavailableView(
                        L10n.noItems.localizedCapitalized,
                        systemImage: "rectangle.on.rectangle.slash"
                    )
                    .focusable()
                    .coordinatedFocus(.fallback)
                } else {
                    elementsGrid
                }

            case .error:
                viewModel.error
                    .map(ErrorView.init)
                    .coordinatedFocus(.fallback)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.linear(duration: 0.2), value: viewModel.state)
    }

    private var gridInsets: EdgeInsets {
        EdgeInsets(
            top: Cinema.Spacing.s8,
            leading: Cinema.Spacing.s48,
            bottom: Cinema.Spacing.s64,
            trailing: Cinema.Layout.edgePadding
        )
    }

    private var gridLayout: CollectionVGridLayout {
        switch displayType {
        case .grid:
            .minWidth(
                Cinema.Layout.posterMinimumWidth,
                insets: gridInsets,
                itemSpacing: Cinema.Layout.gridSpacing,
                lineSpacing: Cinema.Layout.gridSpacing
            )

        case .list:
            .columns(
                1,
                insets: gridInsets,
                itemSpacing: 0,
                lineSpacing: Cinema.Spacing.s4,
                itemSizing: .height
            )
        }
    }

    private var elementsGrid: some View {
        CollectionVGrid(
            uniqueElements: viewModel.displayedElements,
            layout: gridLayout
        ) { entry in
            element(entry)
                .if(entry.id == viewModel.displayedElements.first?.id) { view in
                    view
                        .coordinatedFocus(Focus.firstElement.rawValue)
                        .environmentObject(focusCoordinator)
                }
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.getNextPage()
        }
        .proxy(gridProxy)
        .contentInsetAdjustmentBehavior(.never)
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func element(_ entry: ItemEntry) -> some View {
        switch displayType {
        case .grid:
            CinemaPosterCell(item: entry.snapshot) {
                entry.libraryDidSelectElement(router: router, in: namespace)
            }

        case .list:
            CinemaListRow(item: entry.snapshot) {
                entry.libraryDidSelectElement(router: router, in: namespace)
            }
        }
    }

    // MARK: - Selection

    private func updateSelection() {
        guard isGridFocused,
              let focusedPoster,
              let entry = focusedPoster._poster as? ItemEntry
        else { return }

        panelViewModel.select(entry.snapshot)
    }

    private func selectFirstElementIfNeeded() {
        guard let first = viewModel.elements.first else { return }

        if panelViewModel.item == nil {
            panelViewModel.select(first.snapshot)
        }

        requestInitialFocusIfNeeded()
    }

    /// Moves focus to the first poster once the grid has laid it out.
    private func requestInitialFocusIfNeeded() {
        guard !hasRequestedInitialFocus else { return }

        hasRequestedInitialFocus = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            focusCoordinator.focus(Focus.firstElement.rawValue)
        }
    }

    private func select(_ option: CinemaSortOption) {
        sortOption = option
        applySort?(viewModel, option)
    }
}

extension CinemaCollectionView where Library == ItemLibrary {

    /// A collection of items that can be re-sorted through the library's filters.
    init(
        library: ItemLibrary,
        title: String,
        countTypes: [BaseItemKind],
        sortOptions: [CinemaSortOption] = CinemaSortOption.allCases
    ) {
        self.init(
            library: library,
            title: title,
            countTypes: countTypes,
            initialSort: CinemaSortOption.option(for: library.environment?.filters ?? .default),
            sortOptions: sortOptions
        ) { viewModel, option in
            viewModel.environment.filters.sortBy = [option.sortBy]
            viewModel.environment.filters.sortOrder = [option.sortOrder]
        }
    }
}

extension CinemaCollectionView where Library == PeopleLibrary {

    /// People cannot be re-sorted; the server returns them by name.
    init(
        library: PeopleLibrary,
        title: String,
        countTypes: [BaseItemKind]
    ) {
        self.init(
            library: library,
            title: title,
            countTypes: countTypes,
            initialSort: nil,
            sortOptions: [],
            applySort: nil
        )
    }
}
