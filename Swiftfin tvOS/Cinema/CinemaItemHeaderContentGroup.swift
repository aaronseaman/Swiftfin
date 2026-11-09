//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    /// The header of an item page: the original poster beside the title,
    /// metadata, format, synopsis and playback controls, on a flat background.
    struct CinemaHeaderContentGroup: ContentGroup {

        let id: String = ItemView.Component.header
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @ObservedObject
            var provider: ItemContentGroupProvider

            private var item: BaseItemDto {
                provider.item
            }

            private var posterDisplayType: PosterDisplayType {
                switch item.type {
                case .episode, .program, .liveTvProgram, .video, .musicVideo:
                    .landscape
                default:
                    .portrait
                }
            }

            private var posterWidth: CGFloat {
                posterDisplayType == .landscape ? Cinema.Layout.itemPosterWidth * 1.6 : Cinema.Layout.itemPosterWidth
            }

            private var directorName: String? {
                item.people?
                    .first { $0.type == .director }?
                    .name?
                    .nilIfBlank
            }

            private var metadataLine: some View {
                DotHStack {
                    if let year = item.premiereDateYear ?? item.productionYear.map({ String($0) }) {
                        Text(year)
                    }

                    if let runtime = item.runtime {
                        Text(Cinema.Format.runtime(runtime))
                    }

                    if let genre = item.genres?.first {
                        Text(genre)
                    }

                    if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                    }

                    if let rating = item.officialRating?.nilIfBlank {
                        Text(rating)
                    }
                }
                .font(Cinema.Typography.meta)
                .foregroundStyle(Cinema.Palette.secondaryText)
                .lineLimit(1)
            }

            private var details: some View {
                VStack(alignment: .leading, spacing: Cinema.Spacing.s16) {
                    if let parentID = item.parentRootID, let parentTitle = item.parentTitle {
                        ItemView.ParentButton(title: parentTitle, id: parentID)
                    }

                    Text(item.displayTitle)
                        .font(Cinema.Typography.title)
                        .foregroundStyle(Cinema.Palette.primaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    metadataLine

                    if let directorName {
                        Text(L10n.directedBy(directorName))
                            .font(Cinema.Typography.meta)
                            .foregroundStyle(Cinema.Palette.secondaryText)
                            .lineLimit(1)
                    }

                    let chips = CinemaMediaFormat.chips(for: provider.playbackIntent?.mediaSource ?? item.mediaSources?.first)

                    if chips.isNotEmpty {
                        FlowLayout(alignment: .leading, direction: .down, spacing: Cinema.Spacing.s8) {
                            ForEach(chips, id: \.self) { chip in
                                CinemaChip(text: chip)
                            }
                        }
                    }

                    if let tagline = item.taglines?.first(where: \.isNotEmpty) {
                        Text(tagline)
                            .font(Cinema.Typography.label)
                            .foregroundStyle(Cinema.Palette.primaryText)
                            .lineLimit(2)
                    }

                    if let overview = item.overview?.nilIfBlank {
                        Text(overview)
                            .font(Cinema.Typography.body)
                            .foregroundStyle(Cinema.Palette.secondaryText)
                            .lineSpacing(6)
                            .lineLimit(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ItemView.ActionBar(
                        provider: provider,
                        alignment: .leading
                    )
                    .frame(maxWidth: 640, alignment: .leading)
                    .padding(.top, Cinema.Spacing.s8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            var body: some View {
                HStack(alignment: .top, spacing: Cinema.Spacing.s48) {
                    PosterImage(
                        item: item,
                        type: posterDisplayType,
                        size: .medium
                    )
                    .frame(width: posterWidth)
                    .clipShape(RoundedRectangle(cornerRadius: Cinema.Radius.poster, style: .continuous))
                    .accessibilityHidden(true)

                    details
                }
                .focusSection()
                .padding(.horizontal, Cinema.Layout.edgePadding)
                .padding(.top, Cinema.Spacing.s48)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}
