//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// A poster with its title and year beneath. Focus draws a ring and a
/// small lift; nothing expands, overlays or plays.
struct CinemaPosterCell: View {

    @SharedBaseItem
    private var item: BaseItemDto

    private let displayType: PosterDisplayType
    private let action: () -> Void

    init(
        item: BaseItemDto,
        displayType: PosterDisplayType = .portrait,
        action: @escaping () -> Void
    ) {
        self.item = item
        self.displayType = displayType
        self.action = action
    }

    private var subtitle: String? {
        switch item.type {
        case .person:
            item.subtitle
        case .episode:
            item.seasonEpisodeLabel
        default:
            item.premiereDateYear ?? item.productionYear.map { String($0) }
        }
    }

    var body: some View {
        Button(action: action) {
            CinemaPosterCellLabel(
                item: item,
                displayType: displayType,
                subtitle: subtitle
            )
        }
        .buttonStyle(CinemaPlainButtonStyle())
        .focusedValue(\.focusedPoster, AnyPoster(item))
        .posterAccessibility(for: item)
        .posterContextMenu(for: item) {
            CinemaPosterCellLabel(
                item: item,
                displayType: displayType,
                subtitle: subtitle
            )
            .frame(width: 300)
            .padding(Cinema.Spacing.s20)
            .background(Cinema.Palette.elevated)
        }
    }
}

private struct CinemaPosterCellLabel: View {

    @Environment(\.isFocused)
    private var isFocused

    let item: BaseItemDto
    let displayType: PosterDisplayType
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Cinema.Spacing.s12) {
            PosterImage(
                item: item,
                type: displayType,
                size: .small
            )
            .overlay {
                item.posterOverlay(for: displayType)
            }
            .clipShape(RoundedRectangle(cornerRadius: Cinema.Radius.poster, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Cinema.Radius.poster, style: .continuous)
                    .strokeBorder(Cinema.Palette.focus, lineWidth: Cinema.Stroke.focusRing)
                    .opacity(isFocused ? 1 : 0)
            }
            .shadow(color: .black.opacity(isFocused ? 0.45 : 0), radius: 24, y: 12)
            .scaleEffect(isFocused ? 1.06 : 1)
            .animation(Cinema.Motion.hover, value: isFocused)

            VStack(alignment: .leading, spacing: Cinema.Spacing.s4) {
                Text(item.displayTitle)
                    .font(Cinema.Typography.label)
                    .foregroundStyle(Cinema.Palette.primaryText)
                    .lineLimit(1)

                Text(subtitle ?? String.space)
                    .font(Cinema.Typography.meta)
                    .foregroundStyle(Cinema.Palette.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, Cinema.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
