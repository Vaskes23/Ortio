//
//  DictationUIComponents.swift
//  Ortio
//

import SwiftUI
import UIKit

// MARK: - DictationPillControl

struct DictationPillControl: View {
    let state: ModelNotesDictationState
    let meterLevels: [CGFloat]
    let duration: TimeInterval
    let actionSymbolName: String
    let actionAccessibilityLabel: String
    let actionDisabled: Bool
    let onAction: () -> Void
    let onUndo: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            DictationStatusCapsule(
                state: state,
                meterLevels: meterLevels,
                duration: duration,
                onUndo: onUndo
            )
            .frame(maxWidth: .infinity)

            Button(action: onAction) {
                DictationOrb(
                    symbolName: actionSymbolName,
                    variant: .primaryAction,
                    size: 44
                )
                .opacity(actionDisabled ? 0.72 : 1)
            }
            .buttonStyle(.plain)
            .disabled(actionDisabled)
            .accessibilityLabel(actionAccessibilityLabel)
        }
    }
}

// MARK: - DictationStatusCapsule

private struct DictationStatusCapsule: View {
    let state: ModelNotesDictationState
    let meterLevels: [CGFloat]
    let duration: TimeInterval
    let onUndo: (() -> Void)?

    var body: some View {
        Group {
            switch state {
            case .idle:
                DictationIdleCapsule()
            case .recording:
                DictationRecordingCapsule(
                    meterLevels: meterLevels,
                    duration: duration
                )
            case .transcribing:
                DictationTranscribingCapsule()
            case .insertedFeedback:
                DictationInsertedCapsule(onUndo: onUndo)
            case .error(let message):
                DictationErrorCapsule(message: message)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        .dictationCapsuleSurface()
    }
}

// MARK: - Idle Capsule

private struct DictationIdleCapsule: View {
    private static let previewLevels: [CGFloat] = [
        0.18, 0.26, 0.22, 0.36, 0.3, 0.18, 0.22, 0.34, 0.24, 0.18, 0.3, 0.22,
        0.18, 0.28, 0.24, 0.16, 0.22, 0.3, 0.2, 0.18, 0.26, 0.2, 0.16, 0.24
    ]

    var body: some View {
        DictationWaveformView(levels: Self.previewLevels)
            .frame(height: 16)
            .opacity(0.72)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)
    }
}

// MARK: - Recording Capsule

private struct DictationRecordingCapsule: View {
    let meterLevels: [CGFloat]
    let duration: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            DictationWaveformView(levels: meterLevels)
                .frame(height: 18)
                .frame(maxWidth: .infinity)

            Text(duration.dictationTimestamp)
                .font(.footnote.monospacedDigit().weight(.medium))
                .foregroundStyle(DictationPalette.secondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recording, \(duration.dictationTimestamp)")
    }
}

// MARK: - DictationWaveformView

struct DictationWaveformView: View {
    let levels: [CGFloat]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let barCount = max(levels.count, 1)
            let spacing = max(1.5, geometry.size.width * 0.008)
            let totalSpacing = spacing * CGFloat(max(barCount - 1, 0))
            let barWidth = max(1.4, (geometry.size.width - totalSpacing) / CGFloat(barCount))
            let maxHeight = geometry.size.height * 0.82

            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                    Capsule(style: .continuous)
                        .fill(color(for: index, level: level))
                        .frame(width: barWidth, height: max(4, maxHeight * level))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: levels)
        }
        .accessibilityHidden(true)
    }

    private func color(for index: Int, level: CGFloat) -> Color {
        let emphasis = level > 0.62 || index == emphasizedIndex
        return emphasis ? DictationPalette.waveformEmphasis : DictationPalette.waveform
    }

    private var emphasizedIndex: Int {
        max(0, min(levels.count - 1, levels.count / 2))
    }
}

// MARK: - Inserted / Error / Transcribing Capsules

private struct DictationInsertedCapsule: View {
    let onUndo: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Text("Added to notes")
                .font(.footnote.weight(.medium))
                .foregroundStyle(DictationPalette.primaryText)

            Spacer(minLength: 0)

            if let onUndo {
                Button("Undo", action: onUndo)
                    .buttonStyle(.plain)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DictationPalette.primaryText)
                    .accessibilityLabel("Undo latest transcript")
            }
        }
    }
}

private struct DictationErrorCapsule: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(OrtioDesignSystem.Palette.destructive)

            Text(message)
                .font(.footnote)
                .foregroundStyle(OrtioDesignSystem.Palette.destructive)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DictationTranscribingCapsule: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .tint(DictationPalette.waveformEmphasis)

            Text("Transcribing\u{2026}")
                .font(.footnote.weight(.medium))
                .foregroundStyle(DictationPalette.primaryText)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Capsule Surface

private struct DictationCapsuleSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Capsule(style: .continuous)
                    .fill(DictationPalette.capsuleFill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DictationPalette.capsuleStroke, lineWidth: 1)
            )
            .shadow(color: DictationPalette.orbShadow, radius: 18, x: 0, y: 10)
    }
}

private extension View {
    func dictationCapsuleSurface() -> some View {
        modifier(DictationCapsuleSurfaceModifier())
    }
}

// MARK: - DictationOrb

enum DictationOrbVariant {
    case shell
    case primaryAction
    case mutedAction
}

struct DictationOrb: View {
    let symbolName: String
    let variant: DictationOrbVariant
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: symbolName)
            .font(symbolFont)
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor)
            )
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
    }

    private var symbolFont: Font {
        switch variant {
        case .shell:
            .title3.weight(.semibold)
        case .primaryAction, .mutedAction:
            .title3.weight(.bold)
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .shell:
            DictationPalette.shellGlyph
        case .primaryAction:
            DictationPalette.primaryActionGlyph
        case .mutedAction:
            DictationPalette.mutedActionGlyph
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .shell:
            DictationPalette.shellFill
        case .primaryAction:
            DictationPalette.primaryActionFill
        case .mutedAction:
            DictationPalette.mutedActionFill
        }
    }

    private var borderColor: Color {
        switch variant {
        case .shell:
            DictationPalette.orbBorder
        case .primaryAction:
            OrtioDesignSystem.Palette.clear
        case .mutedAction:
            OrtioDesignSystem.Palette.clear
        }
    }

    private var shadowColor: Color {
        DictationPalette.orbShadow
    }
}

// MARK: - DictationPalette

enum DictationPalette {
    static var shellFill: Color {
        OrtioDesignSystem.Palette.surface.opacity(0.98)
    }

    static var shellGlyph: Color {
        OrtioDesignSystem.Palette.primaryText
    }

    static var capsuleFill: Color {
        OrtioDesignSystem.Palette.surface.opacity(0.96)
    }

    static var capsuleStroke: Color {
        OrtioDesignSystem.Palette.subtleBorder
    }

    static var waveform: Color {
        OrtioDesignSystem.Palette.secondaryText.opacity(0.58)
    }

    static var waveformEmphasis: Color {
        OrtioDesignSystem.Palette.secondaryText
    }

    static var primaryText: Color {
        OrtioDesignSystem.Palette.primaryText
    }

    static var secondaryText: Color {
        OrtioDesignSystem.Palette.secondaryText
    }

    static var primaryActionFill: Color {
        OrtioDesignSystem.Palette.primaryAccent
    }

    static var primaryActionGlyph: Color {
        OrtioDesignSystem.Palette.lightText
    }

    static var mutedActionFill: Color {
        OrtioDesignSystem.Palette.secondary
    }

    static var mutedActionGlyph: Color {
        OrtioDesignSystem.Palette.lightText
    }

    static let orbShadow = OrtioDesignSystem.Palette.shadow
    static let orbBorder = OrtioDesignSystem.Palette.subtleBorder
}

// MARK: - TimeInterval Extension

extension TimeInterval {
    var dictationTimestamp: String {
        let totalSeconds = max(0, Int(self.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
