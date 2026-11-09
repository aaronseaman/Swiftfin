//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// The list presentation of a title: a small poster, the title, and a line of metadata.
struct CinemaListRow: View {

    @SharedBaseItem
    private var item: BaseItemDto

    private let action: () -> Void

    init(item: BaseItemDto, action: @escaping () -> Void) {
        self.item = item
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            CinemaListRowLabel(item: item)
        }
        .buttonStyle(CinemaPlainButtonStyle())
        .focusedValue(\.focusedPoster, AnyPoster(item))
        .posterAccessibility(for: item)
    }
}

private struct CinemaListRowLabel: View {

    @Environment(\.isFocused)
    private var isFocused

    let item: BaseItemDto

    private var year: String? {
        item.premiereDateYear ?? item.productionYear.map { String($0) }
    }

    var body: some View {
        HStack(spacing: Cinema.Spacing.s24) {
            PosterImage(
                item: item,
                type: .portrait,
                size: .extraSmall
            )
            .frame(width: 60)
            .clipShape(RoundedRectangle(cornerRadius: Cinema.Spacing.s4, style: .continuous))

            VStack(alignment: .leading, spacing: Cinema.Spacing.s4) {
                Text(item.displayTitle)
                    .font(Cinema.Typography.label)
                    .foregroundStyle(Cinema.Palette.primaryText)
                    .lineLimit(1)

                DotHStack {
                    if let year {
                        Text(year)
                    }

                    if let runtime = item.runtime {
                        Text(Cinema.Format.runtime(runtime))
                    }

                    if let genre = item.genres?.first {
                        Text(genre)
                    }
                }
                .font(Cinema.Typography.meta)
                .foregroundStyle(Cinema.Palette.secondaryText)
                .lineLimit(1)
            }

            Spacer(minLength: Cinema.Spacing.s16)

            if item.userData?.isFavorite == true {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Cinema.Palette.mutedText)
            }
        }
        .padding(.horizontal, Cinema.Spacing.s16)
        .padding(.vertical, Cinema.Spacing.s12)
        .background {
            RoundedRectangle(cornerRadius: Cinema.Radius.control, style: .continuous)
                .fill(Cinema.Palette.hover)
                .opacity(isFocused ? 1 : 0)
        }
        .overlay(alignment: .bottom) {
            CinemaDivider()
                .padding(.horizontal, Cinema.Spacing.s16)
                .opacity(isFocused ? 0 : 1)
        }
        .animation(Cinema.Motion.hover, value: isFocused)
    }
}
