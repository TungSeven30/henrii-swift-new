import SwiftUI

struct ExportShareView: View {
    let csv: String
    let babyName: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: HenriiSpacing.xl) {
                VStack(spacing: HenriiSpacing.md) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 48))
                        .foregroundStyle(HenriiColors.accentPrimary)

                    Text("Export Ready")
                        .font(.henriiTitle2)
                        .foregroundStyle(HenriiColors.textPrimary)

                    let lineCount = csv.components(separatedBy: "\n").count - 1
                    Text("\(lineCount) events for \(babyName)")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
                .padding(.top, HenriiSpacing.xxl)

                ScrollView {
                    Text(csv)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(HenriiColors.textSecondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(HenriiSpacing.md)
                }
                .frame(maxHeight: 200)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
                .padding(.horizontal, HenriiSpacing.margin)

                Spacer()

                VStack(spacing: HenriiSpacing.md) {
                    Button {
                        UIPasteboard.general.string = csv
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        HStack {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy CSV to Clipboard")
                        }
                        .font(.henriiHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(copied ? HenriiColors.dataGrowth : HenriiColors.accentPrimary)
                        .clipShape(Capsule())
                    }
                    .sensoryFeedback(.success, trigger: copied)

                    if let shareItems = createShareItems() {
                        ShareLink(item: shareItems) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.henriiHeadline)
                            .foregroundStyle(HenriiColors.accentPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(HenriiColors.accentPrimary.opacity(0.12))
                            .clipShape(Capsule())
                        }
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

    private func createShareItems() -> String? {
        csv.isEmpty ? nil : csv
    }
}
