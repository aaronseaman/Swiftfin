//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Counts the titles of each kind in the collection for the screen header.
@MainActor
final class CinemaCollectionCountsViewModel: ViewModel {

    struct Count: Hashable, Identifiable {

        let kind: BaseItemKind
        let value: Int

        var id: BaseItemKind {
            kind
        }

        var displayTitle: String {
            let number = value.formatted()

            return switch kind {
            case .movie:
                L10n.filmsWithCount(number)
            case .series:
                L10n.seriesWithCount(number)
            case .boxSet:
                L10n.collectionsWithCount(number)
            case .person:
                L10n.peopleWithCount(number)
            default:
                L10n.titlesWithCount(number)
            }
        }
    }

    @Published
    private(set) var counts: [Count] = []

    let kinds: [BaseItemKind]

    /// The sum across kinds, shown before the per-kind counts when more than one kind is counted.
    var total: Int? {
        guard kinds.count > 1, counts.count == kinds.count else { return nil }

        return counts.map(\.value).reduce(0, +)
    }

    init(kinds: [BaseItemKind]) {
        self.kinds = kinds
        super.init()
    }

    func refresh() {
        Task {
            await refresh()
        }
    }

    func refresh() async {
        guard let userSession else { return }

        var result: [Count] = []

        for kind in kinds {
            if let value = try? await count(of: kind, userSession: userSession) {
                result.append(.init(kind: kind, value: value))
            }
        }

        counts = result
    }

    private func count(of kind: BaseItemKind, userSession: UserSession) async throws -> Int? {
        if kind == .person {
            var parameters = Paths.GetPersonsParameters()
            parameters.limit = 1

            let response = try await userSession.client.send(Paths.getPersons(parameters: parameters))
            return response.value.totalRecordCount
        }

        var parameters = Paths.GetItemsParameters()
        parameters.enableImages = false
        parameters.includeItemTypes = [kind]
        parameters.isRecursive = true
        parameters.limit = 1
        parameters.userID = userSession.user.id

        let response = try await userSession.client.send(Paths.getItems(parameters: parameters))
        return response.value.totalRecordCount
    }
}
