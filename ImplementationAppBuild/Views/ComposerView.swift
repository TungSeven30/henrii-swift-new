import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    let timerRunning: Bool
    let onSend: (String) -> Void
    @FocusState private var isFocused: Bool
    @State private var speechService = SpeechService()

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
                        Image(systemName: "mic.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .frame(width: 44, height: 44)
                            .symbolEffect(.pulse, options: .repeating, isActive: true)
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: speechService.transcript)
                } else if text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button { startListening() } label: {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                            .foregroundStyle(HenriiColors.accentPrimary)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    Button { send() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(HenriiColors.accentPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: text)
                }
            }
            .padding(.leading, HenriiSpacing.lg)
            .padding(.trailing, HenriiSpacing.xs)
            .frame(minHeight: 52)
            .background(HenriiColors.canvasElevated)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
        .padding(.horizontal, HenriiSpacing.margin)
        .padding(.bottom, HenriiSpacing.sm)
        .onChange(of: speechService.transcript) { _, newValue in
            if !newValue.isEmpty {
                text = newValue
            }
        }
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
