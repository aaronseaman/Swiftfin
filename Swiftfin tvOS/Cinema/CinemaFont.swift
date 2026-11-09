//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreText
import SwiftUI

/// Resolves the Cinema typeface.
///
/// Inter ships with the app as a variable font. Weights are selected
/// through the `wght` variation axis so every weight in the design system
/// maps to the exact value the specification names, and the `opsz` axis
/// follows the point size. When the font is not registered, the system
/// font is used with the same size and weight.
enum CinemaFont {

    static let familyName = "Inter"

    private static let isAvailable: Bool = UIFont.fontNames(forFamilyName: familyName).isNotEmpty

    /// The `wght` axis identifier, the four-character code `'wght'`.
    private static let weightAxis = 0x7767_6874
    /// The `opsz` axis identifier, the four-character code `'opsz'`.
    private static let opticalSizeAxis = 0x6F70_737A

    static func font(size: CGFloat, weight: Font.Weight) -> Font {
        guard let uiFont = uiFont(size: size, weight: weight) else {
            return .system(size: size, weight: weight)
        }

        return Font(uiFont)
    }

    static func uiFont(size: CGFloat, weight: Font.Weight) -> UIFont? {
        guard isAvailable else { return nil }

        let variation: [Int: CGFloat] = [
            weightAxis: axisValue(for: weight),
            opticalSizeAxis: min(max(size, 14), 32),
        ]
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: familyName,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variation,
        ])

        return UIFont(descriptor: descriptor, size: size)
    }

    private static func axisValue(for weight: Font.Weight) -> CGFloat {
        switch weight {
        case .ultraLight: 200
        case .thin: 200
        case .light: 300
        case .regular: 400
        case .medium: 500
        case .semibold: 600
        case .bold: 700
        case .heavy: 800
        case .black: 900
        default: 400
        }
    }
}
