import SwiftUI
import SwiftData

struct AddBabyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let onAdd: (UUID) -> Void

    @State private var babyName: String = ""
    @State private var birthDate: Date = Date()
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: HenriiSpacing.xl) {
                Circle()
                    .fill(HenriiColors.accentPrimary.opacity(0.12))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(HenriiColors.accentPrimary)
                    }
                    .padding(.top, HenriiSpacing.xl)

                VStack(spacing: HenriiSpacing.lg) {
                    TextField("Baby's name", text: $babyName)
                        .font(.henriiTitle2)
                        .multilineTextAlignment(.center)
                        .focused($nameFieldFocused)

                    DatePicker(
                        "Birth date",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
                .padding(.horizontal, HenriiSpacing.margin)

                Spacer()

                Button {
                    let trimmed = babyName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    let baby = Baby(name: trimmed, birthDate: birthDate)
                    modelContext.insert(baby)

                    let welcome = ConversationEntry(
                        type: .system,
                        text: "Welcome! I'm ready to help you track \(baby.name)'s day.",
                        babyID: baby.id
                    )
                    modelContext.insert(welcome)
                    try? modelContext.save()
                    onAdd(baby.id)
                    dismiss()
                } label: {
                    Text("Add Baby")
                        .font(.henriiHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(babyName.trimmingCharacters(in: .whitespaces).isEmpty ? HenriiColors.accentPrimary.opacity(0.4) : HenriiColors.accentPrimary)
                        .clipShape(Capsule())
                }
                .disabled(babyName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, HenriiSpacing.margin)
                .padding(.bottom, HenriiSpacing.lg)
            }
            .navigationTitle("Add Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HenriiColors.accentPrimary)
                }
            }
            .onAppear { nameFieldFocused = true }
        }
    }
}
