//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// The selected item panel: poster, title, metadata, playback controls,
/// synopsis, and tabs of structured information. It is part of the
/// collection layout, never a modal.
struct CinemaDetailPanel: View {

    enum Tab: String, CaseIterable, Displayable, Identifiable {

        case overview
        case castAndCrew
        case technical
        case inCollection

        var id: String {
            rawValue
        }

        var displayTitle: String {
            switch self {
            case .overview:
                L10n.overview
            case .castAndCrew:
                L10n.castAndCrew.localizedCapitalized
            case .technical:
                L10n.technical
            case .inCollection:
                L10n.inCollection.localizedCapitalized
            }
        }
    }

    @ObservedObject
    var viewModel: CinemaDetailPanelViewModel

    @PlayMedia
    private var playMedia

    @Router
    private var router

    @State
    private var selectedTab: Tab = .overview

    /// Rows that fit beneath the header on a 1080-point screen.
    private static let maximumRows = 4

    // MARK: - Body

    var body: some View {
        Group {
            if let item = viewModel.item {
                content(for: item)
                    .id(item.id)
                    .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(Cinema.Motion.panel, value: viewModel.item?.id)
        .errorMessage($viewModel.actionError)
        .accessibilityElement(children: .contain)
    }

    private func content(for item: BaseItemDto) -> some View {
        VStack(alignment: .leading, spacing: Cinema.Spacing.s24) {
            header(for: item)

            actions(for: item)

            if let overview = item.overview?.nilIfBlank {
                Text(overview)
                    .font(Cinema.Typography.body)
                    .foregroundStyle(Cinema.Palette.secondaryText)
                    .lineSpacing(6)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            tabBar(for: item)

            tabContent(for: item)
        }
        .padding(.horizontal, Cinema.Spacing.s48)
        .padding(.top, Cinema.Spacing.s40)
        .padding(.bottom, Cinema.Spacing.s48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    private func header(for item: BaseItemDto) -> some View {
        HStack(alignment: .top, spacing: Cinema.Spacing.s24) {
            PosterImage(
                item: item,
                type: .portrait,
                size: .medium
            )
            .frame(width: Cinema.Layout.panelPosterWidth)
            .clipShape(RoundedRectangle(cornerRadius: Cinema.Radius.poster, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Cinema.Spacing.s12) {
                Text(item.displayTitle)
                    .font(Cinema.Typography.title)
                    .foregroundStyle(Cinema.Palette.primaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                metadataLine(for: item)

                if let director = directorName(for: item) {
                    Text(L10n.directedBy(director))
                        .font(Cinema.Typography.meta)
                        .foregroundStyle(Cinema.Palette.secondaryText)
                        .lineLimit(1)
                }

                let chips = CinemaMediaFormat.chips(for: item.mediaSources?.first)

                if chips.isNotEmpty {
                    FlowLayout(alignment: .leading, direction: .down, spacing: Cinema.Spacing.s8) {
                        ForEach(chips, id: \.self) { chip in
                            CinemaChip(text: chip)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metadataLine(for item: BaseItemDto) -> some View {
        DotHStack {
            if let year = item.premiereDateYear ?? item.productionYear.map({ String($0) }) {
                Text(year)
                    .layoutPriority(2)
            }

            if let runtime = item.runtime {
                Text(Cinema.Format.runtime(runtime))
                    .layoutPriority(1)
            }

            if let genre = item.genres?.first {
                Text(genre)
            }

            if item.type == .person, let birthplace = item.birthplace {
                Text(birthplace)
            }
        }
        .font(Cinema.Typography.meta)
        .foregroundStyle(Cinema.Palette.secondaryText)
        .lineLimit(1)
    }

    private func directorName(for item: BaseItemDto) -> String? {
        item.people?
            .first { $0.type == .director }?
            .name?
            .nilIfBlank
    }

    // MARK: - Actions

    private func actions(for item: BaseItemDto) -> some View {
        let isFavorite = item.userData?.isFavorite == true
        let isPlayed = item.userData?.isPlayed == true
        let hasProgress = (viewModel.playbackIntent?.item.userData?.playbackPositionTicks ?? 0) > 0

        return HStack(spacing: Cinema.Spacing.s12) {
            if item.presentPlayButton {
                Button {
                    guard let intent = viewModel.playbackIntent else { return }

                    playMedia(intent: intent)
                } label: {
                    Label(hasProgress ? L10n.resume : L10n.play, systemImage: "play.fill")
                }
                .buttonStyle(CinemaPrimaryButtonStyle())
            } else {
                Button {
                    open(item)
                } label: {
                    Label(L10n.details, systemImage: "arrow.up.forward")
                }
                .buttonStyle(CinemaPrimaryButtonStyle())
            }

            if item.canBeFavorited {
                Button {
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Label(
                        isFavorite ? L10n.removeFromFavorites : L10n.addToFavorites,
                        systemImage: isFavorite ? "bookmark.fill" : "bookmark"
                    )
                }
                .buttonStyle(CinemaIconButtonStyle())
            }

            Menu {
                Button(L10n.details, systemImage: "info.circle") {
                    open(item)
                }

                if item.canBePlayed {
                    Button(
                        isPlayed ? L10n.markAsUnplayed : L10n.markAsPlayed,
                        systemImage: isPlayed ? "minus.circle" : "checkmark.circle"
                    ) {
                        Task { await viewModel.togglePlayed() }
                    }
                }

                if item.canShuffle {
                    ShuffleButton(item: item)
                }
            } label: {
                Label(L10n.menu, systemImage: "ellipsis")
            }
            .menuStyle(.button)
            .buttonStyle(CinemaIconButtonStyle())
        }
    }

    private func open(_ item: BaseItemDto) {
        router.route(to: .item(item: item))
    }

    // MARK: - Tabs

    private func availableTabs(for item: BaseItemDto) -> [Tab] {
        Tab.allCases.filter { tab in
            switch tab {
            case .overview, .inCollection:
                true
            case .castAndCrew:
                item.people?.isNotEmpty == true
            case .technical:
                item.mediaSources?.isNotEmpty == true
            }
        }
    }

    private func resolvedTab(for item: BaseItemDto) -> Tab {
        let tabs = availableTabs(for: item)
        return tabs.contains(selectedTab) ? selectedTab : .overview
    }

    private func tabBar(for item: BaseItemDto) -> some View {
        let current = resolvedTab(for: item)

        return HStack(spacing: 0) {
            ForEach(availableTabs(for: item)) { tab in
                Button(tab.displayTitle) {
                    selectedTab = tab
                }
                .buttonStyle(
                    CinemaUnderlineButtonStyle(
                        isSelected: current == tab,
                        font: Cinema.Typography.tab,
                        horizontalPadding: Cinema.Spacing.s12
                    )
                )
                .accessibilityAddTraits(current == tab ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            CinemaDivider()
        }
        .focusSection()
    }

    @ViewBuilder
    private func tabContent(for item: BaseItemDto) -> some View {
        switch resolvedTab(for: item) {
        case .overview:
            CinemaMetadataTable(rows: overviewRows(for: item))
        case .castAndCrew:
            castAndCrew(for: item)
        case .technical:
            CinemaMetadataTable(rows: Array(CinemaMediaFormat.technicalRows(for: item).prefix(Self.maximumRows)))
        case .inCollection:
            CinemaMetadataTable(rows: collectionRows(for: item))
        }
    }

    // MARK: - Rows

    private func overviewRows(for item: BaseItemDto) -> [CinemaMetadataRow] {
        var rows: [CinemaMetadataRow] = []

        if item.type == .person {
            if let birthday = item.birthday {
                rows.append(.init(label: L10n.born, value: birthday.formatted(date: .long, time: .omitted)))
            }

            if let deathday = item.deathday {
                rows.append(.init(label: L10n.died, value: deathday.formatted(date: .long, time: .omitted)))
            }

            if let birthplace = item.birthplace {
                rows.append(.init(label: L10n.birthplace, value: birthplace))
            }

            return rows
        }

        if let genres = item.genres, genres.isNotEmpty {
            rows.append(.init(label: L10n.genre, value: genres.prefix(3).joined(separator: ", ")))
        }

        if let runtime = item.runtime {
            rows.append(.init(label: L10n.runtime, value: Cinema.Format.runtime(runtime)))
        }

        if let premiereDate = item.premiereDate {
            rows.append(.init(label: L10n.release, value: premiereDate.formatted(date: .abbreviated, time: .omitted)))
        } else if let year = item.productionYear {
            rows.append(.init(label: L10n.release, value: String(year)))
        }

        if let source = item.mediaSources?.first,
           let audio = CinemaMediaFormat.bestAudioStream(in: source),
           let language = CinemaMediaFormat.languageName(for: audio.language)
        {
            rows.append(.init(label: L10n.language, value: language))
        }

        if let studio = item.studios?.first?.name?.nilIfBlank {
            rows.append(.init(label: L10n.studio, value: studio))
        }

        if let rating = item.officialRating?.nilIfBlank {
            rows.append(.init(label: L10n.rating, value: rating))
        }

        return Array(rows.prefix(Self.maximumRows))
    }

    private func collectionRows(for item: BaseItemDto) -> [CinemaMetadataRow] {
        var rows: [CinemaMetadataRow] = []

        if let added = item.dateCreated {
            rows.append(.init(label: L10n.dateAdded, value: added.formatted(date: .abbreviated, time: .omitted)))
        }

        if item.type == .series {
            if let seasons = item.childCount {
                rows.append(.init(label: L10n.seasons, value: seasons.formatted()))
            }

            if let episodes = item.recursiveItemCount {
                rows.append(.init(label: L10n.episodes, value: episodes.formatted()))
            }
        }

        if item.type == .boxSet, let count = item.childCount {
            rows.append(.init(label: L10n.items, value: count.formatted()))
        }

        if let userData = item.userData {
            if item.canBePlayed {
                rows.append(.init(label: L10n.played, value: userData.isPlayed == true ? L10n.yes : L10n.no))
            }

            if let playCount = userData.playCount, playCount > 0 {
                rows.append(.init(label: L10n.playCount, value: playCount.formatted()))
            }

            if let lastPlayed = userData.lastPlayedDate {
                rows.append(.init(label: L10n.datePlayed, value: lastPlayed.formatted(date: .abbreviated, time: .omitted)))
            }

            if item.canBeFavorited {
                rows.append(.init(label: L10n.favorite, value: userData.isFavorite == true ? L10n.yes : L10n.no))
            }
        }

        if let tags = item.tags, tags.isNotEmpty {
            rows.append(.init(label: L10n.tags, value: tags.prefix(4).joined(separator: ", ")))
        }

        return Array(rows.prefix(Self.maximumRows))
    }

    private func castAndCrew(for item: BaseItemDto) -> some View {
        let people = Array((item.mergedPeople ?? []).prefix(Self.maximumRows * 2))
        let columns = [
            GridItem(.flexible(), spacing: Cinema.Spacing.s24, alignment: .topLeading),
            GridItem(.flexible(), spacing: Cinema.Spacing.s24, alignment: .topLeading),
        ]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: Cinema.Spacing.s12) {
            ForEach(Array(people.enumerated()), id: \.offset) { _, person in
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.displayTitle)
                        .font(Cinema.Typography.label)
                        .foregroundStyle(Cinema.Palette.primaryText)
                        .lineLimit(1)

                    if let role = person.displayRole?.nilIfBlank ?? person.type?.displayTitle {
                        Text(role)
                            .font(Cinema.Typography.meta)
                            .foregroundStyle(Cinema.Palette.secondaryText)
                            .lineLimit(1)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, Cinema.Spacing.s8)
    }
}
