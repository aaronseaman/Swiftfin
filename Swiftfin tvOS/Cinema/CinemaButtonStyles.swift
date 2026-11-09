//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - Focus ring

extension View {

    /// Draws the Cinema focus ring just outside the view's bounds.
    func cinemaFocusRing(
        _ isFocused: Bool,
        cornerRadius: CGFloat = Cinema.Radius.control
    ) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: cornerRadius + Cinema.Spacing.s8, style: .continuous)
                .strokeBorder(Cinema.Palette.focus, lineWidth: Cinema.Stroke.focusRing)
                .padding(-Cinema.Spacing.s8)
                .opacity(isFocused ? 1 : 0)
        }
    }
}

// MARK: - Plain

/// Draws nothing of its own so the label can present focus.
struct CinemaPlainButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Cinema.Motion.hover, value: configuration.isPressed)
    }
}

// MARK: - Underline

/// Quiet text that brightens on focus and carries an underline while selected.
///
/// Used for the global navigation items and the detail panel's tabs.
struct CinemaUnderlineButtonStyle: ButtonStyle {

    @Environment(\.isFocused)
    private var isFocused

    let isSelected: Bool
    var font: Font = Cinema.Typography.navigation
    var horizontalPadding: CGFloat = Cinema.Spacing.s20
    var fillsHeight: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(isSelected || isFocused ? Cinema.Palette.primaryText : Cinema.Palette.secondaryText)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, Cinema.Spacing.s12)
            .frame(maxHeight: fillsHeight ? .infinity : nil)
            .background {
                RoundedRectangle(cornerRadius: Cinema.Radius.control, style: .continuous)
                    .fill(Cinema.Palette.hover)
                    .padding(.vertical, fillsHeight ? Cinema.Spacing.s12 : 0)
                    .opacity(isFocused ? 1 : 0)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Cinema.Palette.primaryText)
                    .frame(height: 3)
                    .padding(.horizontal, horizontalPadding)
                    .opacity(isSelected ? 1 : 0)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Cinema.Motion.hover, value: isFocused)
            .animation(Cinema.Motion.state, value: isSelected)
    }
}

// MARK: - Primary

/// The one prominent control on a screen, such as Play.
struct CinemaPrimaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isFocused)
    private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Cinema.Typography.navigation)
            .foregroundStyle(Cinema.Palette.background)
            .padding(.horizontal, Cinema.Spacing.s32)
            .frame(height: Cinema.Layout.controlHeight)
            .background {
                RoundedRectangle(cornerRadius: Cinema.Radius.control, style: .continuous)
                    .fill(Cinema.Palette.primaryText)
            }
            .cinemaFocusRing(isFocused)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(isFocused ? 1.04 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Cinema.Motion.hover, value: isFocused)
            .animation(Cinema.Motion.hover, value: configuration.isPressed)
    }
}

// MARK: - Icon

/// A square icon control. Selected controls fill, the rest keep a hairline border.
struct CinemaIconButtonStyle: ButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isFocused)
    private var isFocused
    @Environment(\.isSelected)
    private var isSelected

    var isBordered: Bool = true

    private var fill: Color {
        if isSelected {
            Cinema.Palette.primaryText
        } else if isFocused {
            Cinema.Palette.hover
        } else {
            .clear
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: 28, weight: .medium))
            .foregroundStyle(isSelected ? Cinema.Palette.background : Cinema.Palette.primaryText)
            .frame(width: Cinema.Layout.controlHeight, height: Cinema.Layout.controlHeight)
            .background {
                RoundedRectangle(cornerRadius: Cinema.Radius.control, style: .continuous)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Cinema.Radius.control, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: Cinema.Stroke.hairline)
                    .opacity(isBordered && !isSelected ? 1 : 0)
            }
            .cinemaFocusRing(isFocused)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(isFocused ? 1.04 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Cinema.Motion.hover, value: isFocused)
            .animation(Cinema.Motion.hover, value: configuration.isPressed)
    }
}

// MARK: - Text

/// A quiet text control, such as the sort menu.
struct CinemaTextButtonStyle: ButtonStyle {

    @Environment(\.isFocused)
    private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Cinema.Typography.label)
            .foregroundStyle(isFocused ? Cinema.Palette.primaryText : Cinema.Palette.secondaryText)
            .padding(.horizontal, Cinema.Spacing.s16)
            .frame(height: Cinema.Layout.controlHeight)
            .background {
                RoundedRectangle(cornerRadius: Cinema.Radius.control, style: .continuous)
                    .fill(Cinema.Palette.hover)
                    .opacity(isFocused ? 1 : 0)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Cinema.Motion.hover, value: isFocused)
            .animation(Cinema.Motion.hover, value: configuration.isPressed)
    }
}
