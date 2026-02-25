import SwiftUI

struct VaccinationExportView: View {
    let text: String
    let babyName: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: HenriiSpacing.xl) {
                VStack(spacing: HenriiSpacing.md) {
                    Image(systemName: "syringe.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HenriiColors.accentSecondary)

                    Text("Vaccination Card")
                        .font(.henriiTitle2)
                        .foregroundStyle(HenriiColors.textPrimary)

                    Text("\(babyName)'s immunization record")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
                .padding(.top, HenriiSpacing.xxl)

                ScrollView {
                    Text(text)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(HenriiColors.textSecondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(HenriiSpacing.md)
                }
                .frame(maxHeight: 240)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
                .padding(.horizontal, HenriiSpacing.margin)

                Spacer()

                VStack(spacing: HenriiSpacing.md) {
                    Button {
                        UIPasteboard.general.string = text
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        HStack {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy to Clipboard")
                        }
                        .font(.henriiHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(copied ? HenriiColors.dataGrowth : HenriiColors.accentPrimary)
                        .clipShape(Capsule())
                    }
                    .sensoryFeedback(.success, trigger: copied)

                    ShareLink(item: text) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Vaccination Card")
                        }
                        .font(.henriiHeadline)
                        .foregroundStyle(HenriiColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(HenriiColors.accentPrimary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, HenriiSpacing.margin)
                .padding(.bottom, HenriiSpacing.lg)
            }
            .background(HenriiColors.canvasPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HenriiColors.accentPrimary)
                }
            }
        }
    }
}
