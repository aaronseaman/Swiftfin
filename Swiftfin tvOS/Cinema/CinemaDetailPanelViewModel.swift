//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Holds the item shown in the selected item panel.
///
/// Selection follows focus in the grid, so the panel first shows what the
/// grid already knows, then fetches the full item (overview, people,
/// media streams) after a short pause and resolves what Play would start.
@MainActor
final class CinemaDetailPanelViewModel: ViewModel {

    @OptionalSharedBaseItem
    private(set) var item: BaseItemDto?

    @Published
    private(set) var detailsItemID: String?
    @Published
    private(set) var playbackIntent: PlaybackIntent?
    @Published
    var actionError: Error?

    private var loadTask: Task<Void, Never>?

    /// Whether the full item for the current selection has been loaded.
    var hasDetails: Bool {
        guard let id = item?.id else { return false }

        return detailsItemID == id
    }

    func select(_ newItem: BaseItemDto) {
        guard let id = newItem.id, id != item?.id else { return }

        item = newItem
        playbackIntent = nil
        loadTask?.cancel()

        loadTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled, let self else { return }

            await self.loadDetails(id: id)
        }
    }

    func toggleFavorite() async {
        guard let entry = $item, let current = entry.value else { return }

        do {
            try await requireUserSession().setFavorite(entry, to: current.userData?.isFavorite != true)
            objectWillChange.send()
        } catch {
            actionError = error
        }
    }

    func togglePlayed() async {
        guard let entry = $item, let current = entry.value else { return }

        do {
            try await requireUserSession().setPlayed(entry, to: current.userData?.isPlayed != true)
            objectWillChange.send()
        } catch {
            actionError = error
        }
    }

    private func loadDetails(id: String) async {
        do {
            let userSession = try requireUserSession()
            let entry = try await userSession.getFullItem(id: id)

            guard !Task.isCancelled, entry.itemID == item?.id else { return }

            $item = entry

            let intent = try await resolvePlaybackIntent(for: entry.snapshot, userSession: userSession)

            guard !Task.isCancelled, entry.itemID == item?.id else { return }

            playbackIntent = intent
            detailsItemID = entry.itemID
        } catch {
            guard !Task.isCancelled else { return }

            logger.error("Unable to load details for item \(id): \(error.localizedDescription)")
        }
    }

    private func resolvePlaybackIntent(
        for item: BaseItemDto,
        userSession: UserSession
    ) async throws -> PlaybackIntent? {
        switch item.type {
        case .series, .season:
            var episode: BaseItemDto?

            if item.type == .series {
                episode = try await nextUpItem(for: item)
            }

            if episode == nil {
                episode = try await firstAvailableItem(for: item)
            }

            guard let episode else { return nil }

            let entry = try await userSession.getFullItem(episode)

            // Keep the record alive until the playback intent takes ownership
            return withExtendedLifetime(entry) {
                entry.snapshot.getPlaybackIntent(userSession: userSession)
            }

        default:
            return item.isPlayable ? item.getPlaybackIntent(userSession: userSession) : nil
        }
    }

    private func nextUpItem(for item: BaseItemDto) async throws -> BaseItemDto? {
        var parameters = Paths.GetNextUpParameters()
        parameters.seriesID = item.id

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await send(request)

        guard let item = response.value.items?.first, !item.isMissing else {
            return nil
        }

        return item
    }

    private func firstAvailableItem(for item: BaseItemDto) async throws -> BaseItemDto? {
        var parameters = Paths.GetItemsParameters()
        parameters.includeItemTypes = [.episode]
        parameters.isMissing = false
        parameters.isRecursive = true
        parameters.limit = 1
        parameters.parentID = item.id
        parameters.sortOrder = [.ascending]

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        return response.value.items?.first
    }
}
