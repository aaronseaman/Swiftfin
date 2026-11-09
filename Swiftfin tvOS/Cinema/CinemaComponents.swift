//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - Divider

/// A hairline in the divider colour.
struct CinemaDivider: View {

    var axis: Axis = .horizontal

    var body: some View {
        Rectangle()
            .fill(Cinema.Palette.divider)
            .frame(
                width: axis == .vertical ? Cinema.Stroke.hairline : nil,
                height: axis == .horizontal ? Cinema.Stroke.hairline : nil
            )
    }
}

// MARK: - Chip

/// A compact, outlined label for technical formats such as "4K UHD".
struct CinemaChip: View {

    let text: String

    var body: some View {
        Text(text)
            .font(Cinema.Typography.caption)
            .foregroundStyle(Cinema.Palette.secondaryText)
            .lineLimit(1)
            .padding(.horizontal, Cinema.Spacing.s12)
            .padding(.vertical, Cinema.Spacing.s4 + 2)
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: Cinema.Stroke.hairline)
            }
    }
}

// MARK: - Metadata table

struct CinemaMetadataRow: Hashable {

    let label: String
    let value: String
}

/// Label and value pairs separated by hairlines.
struct CinemaMetadataTable: View {

    let rows: [CinemaMetadataRow]
    var labelWidth: CGFloat = 190

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .firstTextBaseline, spacing: Cinema.Spacing.s24) {
                    Text(row.label)
                        .font(Cinema.Typography.label)
                        .foregroundStyle(Cinema.Palette.secondaryText)
                        .frame(width: labelWidth, alignment: .leading)

                    Text(row.value)
                        .font(Cinema.Typography.value)
                        .foregroundStyle(Cinema.Palette.primaryText)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, Cinema.Spacing.s8 + 2)
                .overlay(alignment: .bottom) {
                    CinemaDivider()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
