import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    let onComplete: (UUID) -> Void

    @State private var step: Int = 0
    @State private var babyName: String = ""
    @State private var birthDate: Date = Date()
    @State private var showDatePicker: Bool = false
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        ZStack {
            HenriiColors.canvasPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: HenriiSpacing.xxl) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(HenriiColors.accentPrimary)
                        .symbolEffect(.pulse, options: .repeating, isActive: step == 0)

                    switch step {
                    case 0:
                        welcomeStep
                    case 1:
                        nameStep
                    case 2:
                        birthDateStep
                    case 3:
                        readyStep
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, HenriiSpacing.margin)
                .animation(.spring(duration: 0.4, bounce: 0.2), value: step)

                Spacer()
                Spacer()
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: HenriiSpacing.lg) {
            Text("Hi. I'm Henrii.")
                .font(.henriiLargeTitle)
                .foregroundStyle(HenriiColors.textPrimary)

            Text("I'll help you keep track of everything so you can focus on what matters most.")
                .font(.henriiBody)
                .foregroundStyle(HenriiColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                withAnimation { step = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    nameFieldFocused = true
                }
            } label: {
                Text("Let's get started")
                    .font(.henriiHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(HenriiColors.accentPrimary)
                    .clipShape(Capsule())
            }
            .padding(.top, HenriiSpacing.lg)
        }
    }

    private var nameStep: some View {
        VStack(spacing: HenriiSpacing.lg) {
            Text("What's your baby's name?")
                .font(.henriiTitle2)
                .foregroundStyle(HenriiColors.textPrimary)

            TextField("Baby's name", text: $babyName)
                .font(.henriiLargeTitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(HenriiColors.textPrimary)
                .focused($nameFieldFocused)
                .submitLabel(.next)
                .onSubmit {
                    guard !babyName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    withAnimation { step = 2 }
                }

            Button {
                guard !babyName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                withAnimation { step = 2 }
            } label: {
                Text("Next")
                    .font(.henriiHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(babyName.trimmingCharacters(in: .whitespaces).isEmpty ? HenriiColors.accentPrimary.opacity(0.4) : HenriiColors.accentPrimary)
                    .clipShape(Capsule())
            }
            .disabled(babyName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var birthDateStep: some View {
        VStack(spacing: HenriiSpacing.lg) {
            Text("When was \(babyName) born?")
                .font(.henriiTitle2)
                .foregroundStyle(HenriiColors.textPrimary)

            DatePicker(
                "Birth date",
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()

            Button {
                withAnimation { step = 3 }
            } label: {
                Text("Next")
                    .font(.henriiHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(HenriiColors.accentPrimary)
                    .clipShape(Capsule())
            }
        }
    }

    private var readyStep: some View {
        VStack(spacing: HenriiSpacing.lg) {
            Text("You're all set.")
                .font(.henriiLargeTitle)
                .foregroundStyle(HenriiColors.textPrimary)

            Text("Just tell me what's happening and I'll handle the rest.")
                .font(.henriiBody)
                .foregroundStyle(HenriiColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                let baby = Baby(name: babyName.trimmingCharacters(in: .whitespaces), birthDate: birthDate)
                modelContext.insert(baby)

                let welcome = ConversationEntry(
                    type: .system,
                    text: "Welcome! I'm ready to help you track \(baby.name)'s day. Just tell me what's happening \u{2014} \"fed 4oz\", \"diaper change\", \"nap time\" \u{2014} and I'll take care of the rest.",
                    babyID: baby.id
                )
                modelContext.insert(welcome)

                try? modelContext.save()
                onComplete(baby.id)
            } label: {
                HStack(spacing: HenriiSpacing.sm) {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Log first feed")
                }
                .font(.henriiHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(HenriiColors.accentPrimary)
                .clipShape(Capsule())
            }
            .sensoryFeedback(.success, trigger: step)
        }
    }
}
