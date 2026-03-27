import SwiftUI
import UIKit

struct VaccinationExportView: View {
    let text: String
    let babyName: String
    let vaccinations: [Vaccination]
    @Environment(\.dismiss) private var dismiss
    @State private var copied: Bool = false
    @State private var pdfURL: URL?

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
                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            HStack {
                                Image(systemName: "doc.richtext")
                                Text("Share as PDF")
                            }
                            .font(.henriiHeadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(HenriiColors.accentPrimary)
                            .clipShape(Capsule())
                        }
                    }

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
                        .foregroundStyle(HenriiColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(HenriiColors.accentPrimary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .sensoryFeedback(.success, trigger: copied)
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
            .onAppear {
                pdfURL = generateVaccinationPDF()
            }
        }
    }

    private func generateVaccinationPDF() -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(babyName)_Vaccinations.pdf")

        do {
            try pdfRenderer.writePDF(to: url) { pdfContext in
                pdfContext.beginPage()
                var yOffset: CGFloat = margin

                let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
                let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .regular)
                let headerFont = UIFont.systemFont(ofSize: 12, weight: .bold)
                let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                let noteFont = UIFont.systemFont(ofSize: 10, weight: .regular)

                let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.label]
                let subtitleAttrs: [NSAttributedString.Key: Any] = [.font: subtitleFont, .foregroundColor: UIColor.secondaryLabel]
                let headerAttrs: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.label]
                let bodyAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.label]
                let noteAttrs: [NSAttributedString.Key: Any] = [.font: noteFont, .foregroundColor: UIColor.secondaryLabel]

                let title = "Vaccination Record" as NSString
                title.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 30), withAttributes: titleAttrs)
                yOffset += 34

                let subtitle = "\(babyName)" as NSString
                subtitle.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 20), withAttributes: subtitleAttrs)
                yOffset += 28

                let dateStr = "Generated \(Date().formatted(.dateTime.month(.wide).day().year()))" as NSString
                dateStr.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 18), withAttributes: noteAttrs)
                yOffset += 30

                let lineRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: 1)
                UIColor.separator.setFill()
                UIRectFill(lineRect)
                yOffset += 16

                let dateHeader = "Date" as NSString
                let nameHeader = "Vaccine" as NSString
                let notesHeader = "Notes" as NSString
                dateHeader.draw(in: CGRect(x: margin, y: yOffset, width: 120, height: 16), withAttributes: headerAttrs)
                nameHeader.draw(in: CGRect(x: margin + 130, y: yOffset, width: 200, height: 16), withAttributes: headerAttrs)
                notesHeader.draw(in: CGRect(x: margin + 340, y: yOffset, width: contentWidth - 340, height: 16), withAttributes: headerAttrs)
                yOffset += 22

                let sorted = vaccinations.sorted { $0.date < $1.date }
                for vax in sorted {
                    if yOffset > pageHeight - margin - 40 {
                        pdfContext.beginPage()
                        yOffset = margin
                    }

                    let dateText = vax.date.formatted(.dateTime.month(.abbreviated).day().year()) as NSString
                    let nameText = vax.name as NSString
                    let notesText = (vax.notes ?? "") as NSString

                    dateText.draw(in: CGRect(x: margin, y: yOffset, width: 120, height: 16), withAttributes: bodyAttrs)
                    nameText.draw(in: CGRect(x: margin + 130, y: yOffset, width: 200, height: 16), withAttributes: bodyAttrs)
                    notesText.draw(in: CGRect(x: margin + 340, y: yOffset, width: contentWidth - 340, height: 16), withAttributes: noteAttrs)
                    yOffset += 22
                }

                yOffset += 20
                let footerLine = CGRect(x: margin, y: yOffset, width: contentWidth, height: 0.5)
                UIColor.separator.setFill()
                UIRectFill(footerLine)
                yOffset += 12

                let footer = "This record was generated by the Henrii app." as NSString
                footer.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 14), withAttributes: noteAttrs)
            }
            return url
        } catch {
            return nil
        }
    }
}
