//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Foundation
import JellyfinAPI

/// Turns a media source's streams into the short format names a collector
/// expects to read, such as "4K UHD", "HDR10" or "Dolby Atmos".
///
/// Every label is derived from values the server reports. When a stream
/// carries no usable value, no label is produced.
enum CinemaMediaFormat {

    // MARK: - Chips

    /// Up to four labels for the selected item: resolution, dynamic range,
    /// best audio format and video codec, in that order.
    static func chips(for source: MediaSourceInfo?) -> [String] {
        guard let source else { return [] }

        let video = source.videoStreams?.first
        let audio = bestAudioStream(in: source)

        let labels: [String?] = [
            video.flatMap(resolutionLabel),
            video.flatMap(rangeLabel),
            audio.flatMap(audioLabel),
            video.flatMap(videoCodecLabel),
        ]

        return Array(labels.compactMap(\.self).uniqued().prefix(4))
    }

    // MARK: - Video

    static func resolutionLabel(for stream: MediaStream) -> String? {
        guard stream.type == .video, let width = stream.width, let height = stream.height, width > 0, height > 0 else {
            return nil
        }

        return switch max(width, height) {
        case 3800...: "4K UHD"
        case 1900...: "1080p"
        case 1200...: "720p"
        default: "SD"
        }
    }

    static func resolutionDetail(for stream: MediaStream) -> String? {
        guard let width = stream.width, let height = stream.height, width > 0, height > 0 else { return nil }

        return "\(width) × \(height)"
    }

    static func videoCodecLabel(for stream: MediaStream) -> String? {
        guard let codec = stream.codec?.lowercased() else { return nil }

        return switch codec {
        case "hevc", "h265": "HEVC"
        case "h264", "avc": "H.264"
        case "av1": "AV1"
        case "vp9": "VP9"
        case "mpeg2video": "MPEG-2"
        case "mpeg4": "MPEG-4"
        default: codec.uppercased()
        }
    }

    /// The dynamic range when it is wider than standard.
    static func rangeLabel(for stream: MediaStream) -> String? {
        guard let range = stream.videoRangeType else { return nil }

        return switch range {
        case .hdr10: L10n.hdr10
        case .hdr10Plus: L10n.hdr10Plus
        case .hlg: L10n.hlg
        case .dovi, .doviWithEL, .doviWithHDR10, .doviWithHDR10Plus, .doviWithELHDR10Plus, .doviWithHLG, .doviWithSDR:
            L10n.dolbyVision
        case .sdr, .doviInvalid, .unknown: nil
        }
    }

    // MARK: - Audio

    static func bestAudioStream(in source: MediaSourceInfo) -> MediaStream? {
        guard let streams = source.audioStreams, streams.isNotEmpty else { return nil }

        if let index = source.defaultAudioStreamIndex, let stream = streams.first(where: { $0.index == index }) {
            return stream
        }

        return streams.first(where: { $0.isDefault == true }) ?? streams.first
    }

    static func audioLabel(for stream: MediaStream) -> String? {
        guard stream.type == .audio else { return nil }

        let profile = stream.profile?.lowercased() ?? ""
        let codec = stream.codec?.lowercased() ?? ""

        if profile.contains("atmos") {
            return "Dolby Atmos"
        }

        if profile.contains("dts:x") || profile.contains("dts-x") {
            return "DTS:X"
        }

        return switch codec {
        case "truehd": "Dolby TrueHD"

        case "eac3": "Dolby Digital Plus"

        case "ac3": "Dolby Digital"

        case "dts":
            if profile.contains("ma") {
                "DTS-HD MA"
            } else if profile.contains("hra") {
                "DTS-HD HRA"
            } else {
                "DTS"
            }

        case "aac": "AAC"

        case "flac": "FLAC"

        case "opus": "Opus"

        case "mp3": "MP3"

        case "pcm", "pcm_s16le", "pcm_s24le": "PCM"

        case "": nil

        default: codec.uppercased()
        }
    }

    static func channelLabel(for stream: MediaStream) -> String? {
        if let layout = stream.channelLayout?.nilIfBlank {
            return layout
        }

        guard let channels = stream.channels, channels > 0 else { return nil }

        return switch channels {
        case 1: "1.0"
        case 2: "2.0"
        case 6: "5.1"
        case 8: "7.1"
        default: "\(channels) ch"
        }
    }

    static func languageName(for code: String?) -> String? {
        guard let code = code?.nilIfBlank else { return nil }

        return Locale.current.localizedString(forLanguageCode: code)
            ?? Locale.current.localizedString(forIdentifier: code)
            ?? code.uppercased()
    }

    // MARK: - Technical rows

    /// The technical table for an item's primary media source.
    static func technicalRows(for item: BaseItemDto) -> [CinemaMetadataRow] {
        guard let source = item.mediaSources?.first else { return [] }

        var rows: [CinemaMetadataRow] = []

        if let video = source.videoStreams?.first {
            let resolution = [resolutionLabel(for: video), resolutionDetail(for: video)]
                .compactMap(\.self)

            if resolution.isNotEmpty {
                rows.append(.init(label: L10n.resolution, value: resolution.joined(separator: " · ")))
            }

            let codec = [videoCodecLabel(for: video), video.profile?.nilIfBlank]
                .compactMap(\.self)

            if codec.isNotEmpty {
                rows.append(.init(label: L10n.video, value: codec.joined(separator: " · ")))
            }

            if let range = video.videoRangeType, range != .unknown {
                rows.append(.init(label: L10n.videoRange, value: range.displayTitle))
            }

            if let frameRate = video.realFrameRate ?? video.averageFrameRate {
                rows.append(.init(label: L10n.framerate, value: frameRate.formatted(.number.precision(.fractionLength(0 ... 3)))))
            }
        }

        for stream in (source.audioStreams ?? []).prefix(2) {
            let value = [audioLabel(for: stream), channelLabel(for: stream), languageName(for: stream.language)]
                .compactMap(\.self)

            if value.isNotEmpty {
                rows.append(.init(label: L10n.audio, value: value.joined(separator: " · ")))
            }
        }

        if let subtitles = source.subtitleStreams, subtitles.isNotEmpty {
            let languages = Array(
                subtitles
                    .compactMap { languageName(for: $0.language) }
                    .uniqued()
            )

            rows.append(.init(
                label: L10n.subtitles,
                value: languages.isEmpty ? subtitles.count.description : languages.prefix(4).joined(separator: ", ")
            ))
        }

        if let container = source.container?.nilIfBlank {
            rows.append(.init(label: L10n.container, value: container.uppercased()))
        }

        if let bitrate = source.bitrate, bitrate > 0 {
            rows.append(.init(label: L10n.bitrate, value: bitrate.formatted(.bitRate)))
        }

        if let size = source.size, size > 0 {
            rows.append(.init(label: L10n.size, value: Int64(size).formatted(.byteCount(style: .file))))
        }

        return rows
    }
}
