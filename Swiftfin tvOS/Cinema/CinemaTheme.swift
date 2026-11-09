//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Design tokens for the Cinema interface.
///
/// The values follow the Jellyfin Cinema specification: a restrained dark
/// palette, one sans-serif typeface, and a 4-point spacing scale. Sizes are
/// tuned for the 1920 × 1080 point canvas of Apple TV, which is viewed from
/// a distance, so text runs larger than the desktop reference.
enum Cinema {

    // MARK: - Palette

    enum Palette {

        /// Primary background behind every screen.
        static let background = Color(hex: "151719")
        /// Secondary background for the detail panel and list rows.
        static let secondaryBackground = Color(hex: "1B1E20")
        /// Elevated surface for controls at rest.
        static let elevated = Color(hex: "222629")
        /// Surface for a focused or hovered control.
        static let hover = Color(hex: "292E31")

        static let primaryText = Color(hex: "F0F1EF")
        static let secondaryText = Color(hex: "A8AEAD")
        static let mutedText = Color(hex: "777F80")

        static let accent = Color(hex: "8FA9BF")
        static let secondaryAccent = Color(hex: "B5C5D0")

        /// Hairline between regions of a screen.
        static let divider = Color.white.opacity(0.075)
        /// Ring drawn around the focused element.
        static let focus = Color(hex: "A8C0D2")
    }

    // MARK: - Spacing

    /// The 4-point spacing scale. Use the smallest token that fits
    /// instead of an arbitrary value.
    enum Spacing {

        static let s4: CGFloat = 4
        static let s8: CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s20: CGFloat = 20
        static let s24: CGFloat = 24
        static let s32: CGFloat = 32
        static let s40: CGFloat = 40
        static let s48: CGFloat = 48
        static let s64: CGFloat = 64
    }

    // MARK: - Layout

    enum Layout {

        /// Horizontal inset that keeps content inside the Apple TV title-safe area.
        static let edgePadding: CGFloat = 60
        /// Height of the global navigation bar, excluding the safe area above it.
        static let navigationBarHeight: CGFloat = 88
        /// Fraction of the screen width given to the selected item panel.
        static let detailPanelFraction: CGFloat = 0.36
        /// Gutter between posters in a grid.
        static let gridSpacing: CGFloat = 28
        /// Minimum poster width used to compute the grid column count.
        static let posterMinimumWidth: CGFloat = 180
        /// Width of the poster shown in the selected item panel.
        static let panelPosterWidth: CGFloat = 200
        /// Width of the poster on a full item page.
        static let itemPosterWidth: CGFloat = 320
        /// Height of buttons and other controls.
        static let controlHeight: CGFloat = 64
    }

    // MARK: - Shape

    enum Radius {

        static let poster: CGFloat = 8
        static let control: CGFloat = 10
        static let focusRing: CGFloat = 12
    }

    enum Stroke {

        static let focusRing: CGFloat = 4
        static let hairline: CGFloat = 1
    }

    // MARK: - Motion

    enum Motion {

        static let hover: Animation = .easeOut(duration: 0.15)
        static let state: Animation = .easeInOut(duration: 0.18)
        static let panel: Animation = .easeInOut(duration: 0.22)
    }

    // MARK: - Typography

    /// One typeface, three weights: 400 for body and metadata, 500 for
    /// navigation, labels and titles, 600 for important headings.
    enum Typography {

        /// Screen titles such as "My Collection".
        static let display = font(58, weight: .regular)
        /// Title of the selected item.
        static let title = font(44, weight: .medium)
        /// Section headings on an item page.
        static let heading = font(30, weight: .semibold)
        /// Navigation items and primary buttons.
        static let navigation = font(27, weight: .medium)
        /// Synopsis and other running text.
        static let body = font(25, weight: .regular)
        /// Poster titles and table labels.
        static let label = font(24, weight: .medium)
        /// Table values.
        static let value = font(24, weight: .regular)
        /// Release years, counts and secondary metadata.
        static let meta = font(23, weight: .regular)
        /// Format chips and small annotations.
        static let caption = font(20, weight: .medium)
        /// The detail panel's tabs.
        static let tab = font(22, weight: .medium)
        /// The wordmark in the navigation bar.
        static let brand = font(28, weight: .medium)

        static func font(_ size: CGFloat, weight: Font.Weight) -> Font {
            CinemaFont.font(size: size, weight: weight)
        }
    }

    // MARK: - Formatting

    enum Format {

        /// A compact runtime such as "1h 14m".
        static func runtime(_ duration: Duration) -> String {
            duration.formatted(.units(allowed: [.hours, .minutes], width: .narrow))
        }
    }
}
