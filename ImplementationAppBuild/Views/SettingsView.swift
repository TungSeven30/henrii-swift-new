import SwiftUI

struct SettingsView: View {
    let baby: Baby
    @Environment(\.dismiss) private var dismiss
    @State private var insightFrequency: Double = 0.5
    @State private var use24Hour: Bool = false
    @State private var useMetric: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: HenriiSpacing.md) {
                        Circle()
                            .fill(HenriiColors.accentPrimary.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Text(baby.name.prefix(1))
                                    .font(.henriiHeadline)
                                    .foregroundStyle(HenriiColors.accentPrimary)
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(baby.name)
                                .font(.henriiHeadline)
                                .foregroundStyle(HenriiColors.textPrimary)
                            Text(baby.ageDescription)
                                .font(.henriiCaption)
                                .foregroundStyle(HenriiColors.textSecondary)
                        }
                    }
                } header: {
                    Text("Baby Profile")
                }

                Section {
                    VStack(alignment: .leading, spacing: HenriiSpacing.sm) {
                        Text("Insight Frequency")
                            .font(.henriiCallout)
                        Slider(value: $insightFrequency, in: 0...1)
                            .tint(HenriiColors.accentPrimary)
                        HStack {
                            Text("Minimal")
                                .font(.henriiCaption)
                                .foregroundStyle(HenriiColors.textTertiary)
                            Spacer()
                            Text("Verbose")
                                .font(.henriiCaption)
                                .foregroundStyle(HenriiColors.textTertiary)
                        }
                    }
                } header: {
                    Text("AI Behavior")
                }

                Section {
                    Toggle("24-hour time", isOn: $use24Hour)
                        .tint(HenriiColors.accentPrimary)
                    Toggle("Metric units (kg, cm, ml)", isOn: $useMetric)
                        .tint(HenriiColors.accentPrimary)
                } header: {
                    Text("Units & Format")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(HenriiColors.textTertiary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("You parent. Henrii keeps track.")
                        .font(.henriiCaption)
                        .foregroundStyle(HenriiColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, HenriiSpacing.xl)
                }
            }
            .navigationTitle("Settings")
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
