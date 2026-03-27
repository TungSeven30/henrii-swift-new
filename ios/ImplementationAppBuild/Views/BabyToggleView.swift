import SwiftUI

struct BabyToggleView: View {
    let babies: [Baby]
    @Binding var selectedBabyIDs: Set<UUID>
    let onSwitch: (Baby) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: HenriiSpacing.sm) {
                ForEach(babies) { baby in
                    toggleChip(for: baby)
                }

                if babies.count > 1 {
                    bothChip
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, HenriiSpacing.margin)
        .padding(.vertical, HenriiSpacing.xs)
    }

    private func toggleChip(for baby: Baby) -> some View {
        let isSelected = selectedBabyIDs.contains(baby.id) && selectedBabyIDs.count == 1

        return Button {
            withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                selectedBabyIDs = [baby.id]
                onSwitch(baby)
            }
        } label: {
            HStack(spacing: HenriiSpacing.xs) {
                Circle()
                    .fill(isSelected ? HenriiColors.accentPrimary : HenriiColors.accentPrimary.opacity(0.15))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text(baby.name.prefix(1))
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(isSelected ? .white : HenriiColors.accentPrimary)
                    }

                Text(baby.name)
                    .font(.henriiCallout)
                    .foregroundStyle(isSelected ? .white : HenriiColors.textPrimary)
            }
            .padding(.horizontal, HenriiSpacing.md)
            .frame(height: 36)
            .background(isSelected ? HenriiColors.accentPrimary : HenriiColors.canvasElevated)
            .clipShape(Capsule())
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var bothChip: some View {
        let isSelected = selectedBabyIDs.count > 1

        return Button {
            withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                selectedBabyIDs = Set(babies.map(\.id))
            }
        } label: {
            HStack(spacing: HenriiSpacing.xs) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : HenriiColors.accentPrimary)

                Text("Both")
                    .font(.henriiCallout)
                    .foregroundStyle(isSelected ? .white : HenriiColors.textPrimary)
            }
            .padding(.horizontal, HenriiSpacing.md)
            .frame(height: 36)
            .background(isSelected ? HenriiColors.accentPrimary : HenriiColors.canvasElevated)
            .clipShape(Capsule())
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
