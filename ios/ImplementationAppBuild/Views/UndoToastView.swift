import SwiftUI

struct UndoToastView: View {
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: HenriiSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HenriiColors.dataGrowth)
            Text("Logged")
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textPrimary)

            Spacer()

            Button {
                onUndo()
            } label: {
                Text("Undo")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.accentPrimary)
            }
        }
        .padding(.horizontal, HenriiSpacing.lg)
        .padding(.vertical, HenriiSpacing.md)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, HenriiSpacing.xl)
    }
}
