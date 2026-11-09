//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// The orderings offered by the collection screen's sort control.
enum CinemaSortOption: String, CaseIterable, Displayable, Identifiable {

    case recentlyAdded
    case title
    case releaseDate
    case rating
    case runtime
    case random

    var id: String {
        rawValue
    }

    /// Orderings that make sense for collections (box sets).
    static let boxSetCases: [CinemaSortOption] = [.recentlyAdded, .title, .rating, .random]

    var displayTitle: String {
        switch self {
        case .recentlyAdded:
            L10n.recentlyAdded.localizedCapitalized
        case .title:
            L10n.title
        case .releaseDate:
            L10n.releaseDate
        case .rating:
            L10n.rating
        case .runtime:
            L10n.runtime
        case .random:
            L10n.random
        }
    }

    var sortBy: ItemSortBy {
        switch self {
        case .recentlyAdded:
            .dateCreated
        case .title:
            .sortName
        case .releaseDate:
            .premiereDate
        case .rating:
            .communityRating
        case .runtime:
            .runtime
        case .random:
            .random
        }
    }

    var sortOrder: ItemSortOrder {
        switch self {
        case .title, .random:
            .ascending
        case .recentlyAdded, .releaseDate, .rating, .runtime:
            .descending
        }
    }

    /// The option matching a filter collection, if any.
    static func option(for filters: ItemFilterCollection) -> CinemaSortOption? {
        allCases.first {
            filters.sortBy == [$0.sortBy] && filters.sortOrder == [$0.sortOrder]
        }
    }
}
