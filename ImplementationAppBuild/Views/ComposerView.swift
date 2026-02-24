import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    let timerRunning: Bool
    let onSend: (String) -> Void
    @FocusState private var isFocused: Bool
    @State private var speechService = SpeechService()
    @State private var isHoldingMic: Bool = false
    @Environment(\.henriiReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: HenriiSpacing.md) {
            HStack(spacing: HenriiSpacing.sm) {
                TextField("Tell Henrii...", text: $text)
                    .font(.henriiBody)
                    .foregroundStyle(HenriiColors.textPrimary)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit { send() }

                if speechService.isListening {
                    Button { stopListening() } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: "mic.fill")
                                .font(.title3)
                                .foregroundStyle(.red)
                                .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                        }
                        .frame(width: 56, height: 56)
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: speechService.transcript)
                } else if text.trimmingCharacters(in: .whitespaces).isEmpty {
                    micButton
                } else {
                    Button { send() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(HenriiColors.accentPrimary)
                            .frame(width: 56, height: 56)
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: text)
                }
            }
            .padding(.leading, HenriiSpacing.lg)
            .padding(.trailing, HenriiSpacing.xs)
            .frame(minHeight: 56)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 12, y: 3)
        }
        .padding(.horizontal, HenriiSpacing.margin)
        .padding(.bottom, HenriiSpacing.sm)
        .onChange(of: speechService.transcript) { _, newValue in
            if !newValue.isEmpty {
                text = newValue
            }
        }
    }

    private var micButton: some View {
        ZStack {
            Circle()
                .fill(isHoldingMic ? HenriiColors.accentPrimary.opacity(0.15) : .clear)
                .frame(width: 56, height: 56)
            Image(systemName: "mic.fill")
                .font(.title3)
                .foregroundStyle(HenriiColors.accentPrimary)
                .scaleEffect(isHoldingMic ? 1.15 : 1.0)
                .animation(reduceMotion ? .easeInOut(duration: 0.1) : .spring(duration: 0.2), value: isHoldingMic)
        }
        .frame(width: 56, height: 56)
        .contentShape(Circle())
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .onChanged { _ in
                    isHoldingMic = true
                    startListening()
                }
                .onEnded { _ in
                    isHoldingMic = false
                    if speechService.isListening {
                        stopListening()
                    }
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    startListening()
                }
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: isHoldingMic)
    }

    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        text = ""
    }

    private func startListening() {
        Task {
            let granted = await speechService.requestPermissions()
            if granted {
                speechService.startListening()
            }
        }
    }

    private func stopListening() {
        speechService.stopListening()
        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
            send()
        }
    }
}
