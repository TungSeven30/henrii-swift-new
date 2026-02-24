import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.henriiReduceMotion) private var reduceMotion
    let onComplete: (UUID) -> Void

    @State private var step: Int = 0
    @State private var babyName: String = ""
    @State private var birthDate: Date = Date()
    @State private var selectedGender: BabyGender = .boy
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
                        .symbolEffect(.pulse, options: .repeating, isActive: step == 0 && !reduceMotion)

                    switch step {
                    case 0:
                        welcomeStep
                    case 1:
                        nameStep
                    case 2:
                        genderStep
                    case 3:
                        birthDateStep
                    case 4:
                        readyStep
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, HenriiSpacing.margin)
                .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.4, bounce: 0.2), value: step)

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

    private var genderStep: some View {
        VStack(spacing: HenriiSpacing.xl) {
            VStack(spacing: HenriiSpacing.sm) {
                Text("Is \(babyName) a boy or girl?")
                    .font(.henriiTitle2)
                    .foregroundStyle(HenriiColors.textPrimary)

                Text("Used for WHO growth chart comparison")
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textTertiary)
            }

            HStack(spacing: HenriiSpacing.md) {
                genderCard(gender: .boy)
                genderCard(gender: .girl)
            }

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
            .padding(.top, HenriiSpacing.sm)
        }
    }

    private func genderCard(gender: BabyGender) -> some View {
        let isSelected = selectedGender == gender
        let isBoy = gender == .boy
        let cardColor: Color = isBoy ? Color(red: 0.55, green: 0.73, blue: 0.87) : Color(red: 0.91, green: 0.68, blue: 0.75)
        let lightBg: Color = isBoy ? Color(red: 0.89, green: 0.94, blue: 0.98) : Color(red: 0.98, green: 0.91, blue: 0.94)

        return Button {
            withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                selectedGender = gender
            }
        } label: {
            VStack(spacing: HenriiSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? cardColor.opacity(0.2)
                            : Color(.systemGray5).opacity(0.6)
                        )
                        .frame(width: 72, height: 72)

                    Text(isBoy ? "\u{1F466}" : "\u{1F467}")
                        .font(.system(size: 38))
                }

                Text(gender.displayName)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(isSelected ? (isBoy ? Color(red: 0.25, green: 0.45, blue: 0.65) : Color(red: 0.65, green: 0.3, blue: 0.42)) : HenriiColors.textSecondary)

                Circle()
                    .strokeBorder(isSelected ? cardColor : Color(.systemGray4), lineWidth: isSelected ? 6 : 1.5)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(cardColor)
                                .frame(width: 10, height: 10)
                        }
                    }
            }
            .padding(.vertical, HenriiSpacing.xl)
            .padding(.horizontal, HenriiSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? lightBg : HenriiColors.canvasElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? cardColor : .clear, lineWidth: 2.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
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
                withAnimation { step = 4 }
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
                let baby = Baby(name: babyName.trimmingCharacters(in: .whitespaces), birthDate: birthDate, gender: selectedGender)
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
