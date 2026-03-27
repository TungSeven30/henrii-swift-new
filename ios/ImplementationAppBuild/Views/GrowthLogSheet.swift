import SwiftUI
import SwiftData

struct GrowthLogSheet: View {
    let baby: Baby
    var useMetric: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var weightText: String = ""
    @State private var heightText: String = ""
    @State private var headText: String = ""

    private var weightUnit: String { useMetric ? "kg" : "lbs" }
    private var lengthUnit: String { useMetric ? "cm" : "in" }

    var body: some View {
        NavigationStack {
            VStack(spacing: HenriiSpacing.xl) {
                VStack(spacing: HenriiSpacing.sm) {
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(HenriiColors.dataGrowth)
                    Text("Log Growth")
                        .font(.henriiTitle2)
                        .foregroundStyle(HenriiColors.textPrimary)
                    Text("Enter at least one measurement")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
                .padding(.top, HenriiSpacing.lg)

                VStack(spacing: HenriiSpacing.lg) {
                    measurementField(label: "Weight", placeholder: useMetric ? "e.g. 5.7" : "e.g. 12.5", unit: weightUnit, text: $weightText)
                    measurementField(label: "Height", placeholder: useMetric ? "e.g. 61" : "e.g. 24", unit: lengthUnit, text: $heightText)
                    measurementField(label: "Head", placeholder: useMetric ? "e.g. 41" : "e.g. 16", unit: lengthUnit, text: $headText)
                }
                .padding(.horizontal, HenriiSpacing.margin)

                Spacer()

                Button {
                    saveGrowth()
                } label: {
                    Text("Save")
                        .font(.henriiHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HenriiSpacing.md)
                        .background(canSave ? HenriiColors.dataGrowth : HenriiColors.textTertiary)
                        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
                }
                .disabled(!canSave)
                .padding(.horizontal, HenriiSpacing.margin)
                .padding(.bottom, HenriiSpacing.lg)
            }
            .background(HenriiColors.canvasPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(HenriiColors.textTertiary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var canSave: Bool {
        Double(weightText) != nil || Double(heightText) != nil || Double(headText) != nil
    }

    private func measurementField(label: String, placeholder: String, unit: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.xs) {
            Text(label)
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textSecondary)
            HStack(spacing: HenriiSpacing.sm) {
                TextField(placeholder, text: text)
                    .keyboardType(.decimalPad)
                    .font(.henriiBody)
                    .padding(HenriiSpacing.md)
                    .background(HenriiColors.canvasElevated)
                    .clipShape(.rect(cornerRadius: HenriiRadius.small))
                Text(unit)
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textTertiary)
                    .frame(width: 30)
            }
        }
    }

    private func saveGrowth() {
        let event = BabyEvent(category: .growth)
        event.baby = baby
        if useMetric {
            event.weightLbs = Double(weightText).map { $0 / 0.453592 }
            event.heightInches = Double(heightText).map { $0 / 2.54 }
            event.headCircumferenceInches = Double(headText).map { $0 / 2.54 }
        } else {
            event.weightLbs = Double(weightText)
            event.heightInches = Double(heightText)
            event.headCircumferenceInches = Double(headText)
        }
        modelContext.insert(event)

        let confirmation = ConversationEntry(
            type: .confirmation,
            text: event.summaryText,
            eventID: event.id,
            babyID: baby.id
        )
        modelContext.insert(confirmation)
        dismiss()
    }
}
