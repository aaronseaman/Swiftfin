//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// The destinations in the Cinema navigation bar.
extension TabItem {

    /// Every film and series, newest first.
    static var cinemaCollection: TabItem {
        TabItem(
            id: "cinema-collection",
            title: L10n.collection,
            systemImage: "square.grid.2x2"
        ) {
            CinemaCollectionView(
                library: cinemaLibrary(title: L10n.myCollection, itemTypes: [.movie, .series]),
                title: L10n.myCollection.localizedCapitalized,
                countTypes: [.movie, .series]
            )
        }
    }

    static var cinemaFilms: TabItem {
        TabItem(
            id: "cinema-films",
            title: L10n.films,
            systemImage: "film"
        ) {
            CinemaCollectionView(
                library: cinemaLibrary(title: L10n.films, itemTypes: [.movie]),
                title: L10n.films,
                countTypes: [.movie]
            )
        }
    }

    static var cinemaSeries: TabItem {
        TabItem(
            id: "cinema-series",
            title: L10n.series,
            systemImage: "tv"
        ) {
            CinemaCollectionView(
                library: cinemaLibrary(title: L10n.series, itemTypes: [.series]),
                title: L10n.series,
                countTypes: [.series]
            )
        }
    }

    static var cinemaPeople: TabItem {
        TabItem(
            id: "cinema-people",
            title: L10n.people,
            systemImage: "person.2"
        ) {
            CinemaCollectionView(
                library: PeopleLibrary(),
                title: L10n.people,
                countTypes: [.person]
            )
        }
    }

    static var cinemaCollections: TabItem {
        TabItem(
            id: "cinema-collections",
            title: L10n.collections,
            systemImage: "film.stack"
        ) {
            CinemaCollectionView(
                library: cinemaLibrary(title: L10n.collections, itemTypes: [.boxSet]),
                title: L10n.collections,
                countTypes: [.boxSet],
                sortOptions: CinemaSortOption.boxSetCases
            )
        }
    }

    private static func cinemaLibrary(title: String, itemTypes: [BaseItemKind]) -> ItemLibrary {
        ItemLibrary(
            parent: BaseItemDto(name: title),
            filters: .recent,
            staticFilters: .init(itemTypes: itemTypes)
        )
    }
}
