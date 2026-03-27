import SwiftUI
import SwiftData
import PhotosUI
import UserNotifications
import Speech
import CoreImage.CIFilterBuiltins
import UIKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.henriiReduceMotion) private var reduceMotion
    let onComplete: (UUID) -> Void

    @State private var step: Int = 0
    @State private var babyName: String = ""
    @State private var birthDate: Date = Date()
    @State private var selectedGender: BabyGender = .boy
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isSaving: Bool = false
    @State private var partnerName: String = ""
    @FocusState private var nameFieldFocused: Bool

    private let totalSteps = 8

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                if step > 0 && step < totalSteps - 1 {
                    progressBar
                        .padding(.top, HenriiSpacing.sm)
                        .padding(.horizontal, HenriiSpacing.margin)
                }

                Spacer()

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: nameStep
                    case 2: genderStep
                    case 3: birthDateStep
                    case 4: photoStep
                    case 5: partnerInviteStep
                    case 6: permissionsStep
                    case 7: readyStep
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, HenriiSpacing.margin)
                .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.4, bounce: 0.2), value: step)

                Spacer()
                Spacer()
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            HenriiColors.canvasPrimary
                .ignoresSafeArea()

            Circle()
                .fill(HenriiColors.accentPrimary.opacity(0.06))
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(y: -120)
                .ignoresSafeArea()

            Circle()
                .fill(HenriiColors.dataSleep.opacity(0.04))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 100, y: 200)
                .ignoresSafeArea()
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1..<totalSteps - 1, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? HenriiColors.accentPrimary : HenriiColors.accentPrimary.opacity(0.15))
                    .frame(height: 3)
            }
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: HenriiSpacing.xl) {
            ZStack {
                Circle()
                    .fill(HenriiColors.accentPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(HenriiColors.accentPrimary)
                    .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
            }

            VStack(spacing: HenriiSpacing.md) {
                Text("Hi. I'm Henrii.")
                    .font(.henriiLargeTitle)
                    .foregroundStyle(HenriiColors.textPrimary)

                Text("You parent. I'll keep track.")
                    .font(.henriiBody)
                    .foregroundStyle(HenriiColors.textSecondary)
            }

            primaryButton("Let's get started") {
                advanceTo(1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    nameFieldFocused = true
                }
            }
            .padding(.top, HenriiSpacing.sm)
        }
    }

    // MARK: - Step 1: Name

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
                    guard !trimmedName.isEmpty else { return }
                    advanceTo(2)
                }

            primaryButton("Next") {
                advanceTo(2)
            }
            .disabled(trimmedName.isEmpty)
            .opacity(trimmedName.isEmpty ? 0.4 : 1)
        }
    }

    // MARK: - Step 2: Gender

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

            primaryButton("Next") {
                advanceTo(3)
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
                        .fill(isSelected ? cardColor.opacity(0.2) : Color(.systemGray5).opacity(0.6))
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

    // MARK: - Step 3: Birth Date

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

            primaryButton("Next") {
                advanceTo(4)
            }
        }
    }

    // MARK: - Step 4: Photo (Optional)

    private var photoStep: some View {
        VStack(spacing: HenriiSpacing.xl) {
            Text("Want to add a photo?")
                .font(.henriiTitle2)
                .foregroundStyle(HenriiColors.textPrimary)

            ZStack {
                if let photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(HenriiColors.accentPrimary.opacity(0.3), lineWidth: 3)
                        }
                } else {
                    Circle()
                        .fill(HenriiColors.canvasElevated)
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(HenriiColors.textTertiary)
                        }
                }
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: HenriiSpacing.sm) {
                    Image(systemName: photoData == nil ? "photo.on.rectangle.angled" : "arrow.triangle.2.circlepath")
                    Text(photoData == nil ? "Choose Photo" : "Change Photo")
                }
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.accentPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(HenriiColors.accentPrimary.opacity(0.12))
                .clipShape(Capsule())
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }

            VStack(spacing: HenriiSpacing.md) {
                primaryButton("Next") {
                    advanceTo(5)
                }

                if photoData == nil {
                    Button {
                        advanceTo(5)
                    } label: {
                        Text("Skip for now")
                            .font(.henriiCallout)
                            .foregroundStyle(HenriiColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Step 5: Partner Invite

    private var partnerInviteStep: some View {
        VStack(spacing: HenriiSpacing.xl) {
            VStack(spacing: HenriiSpacing.sm) {
                Text("Want to invite your partner?")
                    .font(.henriiTitle2)
                    .foregroundStyle(HenriiColors.textPrimary)

                Text("Share this private link so \(babyName)'s timeline stays in sync across both phones.")
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: HenriiSpacing.md) {
                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 170, height: 170)
                        .padding(HenriiSpacing.md)
                        .background(HenriiColors.canvasElevated)
                        .clipShape(.rect(cornerRadius: HenriiRadius.large))
                }

                ShareLink(item: inviteURL, subject: Text("Join me on Henrii"), message: Text("Track \(babyName) together: \(inviteURL.absoluteString)")) {
                    Label("Share Invite Link", systemImage: "square.and.arrow.up")
                        .font(.henriiHeadline)
                        .foregroundStyle(HenriiColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(HenriiColors.accentPrimary.opacity(0.12))
                        .clipShape(.capsule)
                }

                Text(inviteURL.absoluteString)
                    .font(.caption2)
                    .foregroundStyle(HenriiColors.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            VStack(spacing: HenriiSpacing.md) {
                primaryButton("Continue") {
                    advanceTo(6)
                }

                Button {
                    advanceTo(6)
                } label: {
                    Text("Skip for now")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Step 6: Permissions

    private var permissionsStep: some View {
        VStack(spacing: HenriiSpacing.xl) {
            VStack(spacing: HenriiSpacing.md) {
                Image(systemName: "bell.and.waves.left.and.right.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(HenriiColors.accentPrimary)

                Text("Stay in the loop")
                    .font(.henriiTitle2)
                    .foregroundStyle(HenriiColors.textPrimary)

                Text("Henrii can remind you about feedings, medications, and milestones — and listen hands-free so you never have to put the baby down.")
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: HenriiSpacing.md) {
                permissionRow(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    subtitle: "Feeding reminders & medication alerts"
                )
                permissionRow(
                    icon: "mic.fill",
                    title: "Voice Input",
                    subtitle: "Log hands-free from across the room"
                )
            }
            .padding(HenriiSpacing.lg)
            .background(permissionCardBackground)

            VStack(spacing: HenriiSpacing.md) {
                primaryButton("Allow All") {
                    Task {
                        await requestAllPermissions()
                        advanceTo(7)
                    }
                }

                Button {
                    advanceTo(7)
                } label: {
                    Text("Maybe later")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var permissionCardBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: HenriiRadius.large)
                .fill(HenriiColors.canvasElevated.opacity(0.001))
                .glassEffect()
        } else {
            RoundedRectangle(cornerRadius: HenriiRadius.large)
                .fill(.ultraThinMaterial)
        }
    }

    private func permissionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: HenriiSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(HenriiColors.accentPrimary)
                .frame(width: 40, height: 40)
                .background(HenriiColors.accentPrimary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)

                Text(subtitle)
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }

            Spacer()
        }
    }

    // MARK: - Step 7: Ready

    private var readyStep: some View {
        VStack(spacing: HenriiSpacing.xl) {
            ZStack {
                Circle()
                    .fill(HenriiColors.dataGrowth.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(HenriiColors.dataGrowth)
            }

            VStack(spacing: HenriiSpacing.md) {
                Text("You're all set.")
                    .font(.henriiLargeTitle)
                    .foregroundStyle(HenriiColors.textPrimary)

                Text("Just tell me what's happening and I'll handle the rest.")
                    .font(.henriiBody)
                    .foregroundStyle(HenriiColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            primaryButton("Log first feed", icon: "cup.and.saucer.fill") {
                saveBabyAndComplete()
            }
            .disabled(isSaving)
            .sensoryFeedback(.success, trigger: isSaving)
        }
    }

    // MARK: - Helpers

    private var trimmedName: String {
        babyName.trimmingCharacters(in: .whitespaces)
    }

    private var inviteURL: URL {
        let encodedName = trimmedName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "baby"
        return URL(string: "https://henrii.app/invite/\(encodedName)-\(Int(birthDate.timeIntervalSince1970))") ?? URL(string: "https://henrii.app/invite")!
    }

    private var qrImage: UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(inviteURL.absoluteString.utf8)

        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 9, y: 9)),
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func advanceTo(_ nextStep: Int) {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.4, bounce: 0.2)) {
            step = nextStep
        }
    }

    private func primaryButton(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: HenriiSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.henriiHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(HenriiColors.accentPrimary)
            .clipShape(Capsule())
        }
    }

    private func requestAllPermissions() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])

        _ = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        await AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    private func saveBabyAndComplete() {
        guard !isSaving else { return }
        isSaving = true

        let baby = Baby(name: trimmedName, birthDate: birthDate, gender: selectedGender)
        baby.photoData = photoData
        modelContext.insert(baby)

        let welcome = ConversationEntry(
            type: .system,
            text: "Welcome! I'm ready to help you track \(baby.name)'s day. Just tell me what's happening \u{2014} \"fed 4oz\", \"diaper change\", \"nap time\" \u{2014} and I'll take care of the rest.",
            babyID: baby.id
        )
        modelContext.insert(welcome)

        try? modelContext.save()
        onComplete(baby.id)
    }
}
