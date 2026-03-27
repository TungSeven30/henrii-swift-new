import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    let baby: Baby
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var settings = SettingsManager.shared
    @Query private var babies: [Baby]
    @State private var showAddBaby: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var showResetConfirm: Bool = false

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

                    Button { showAddBaby = true } label: {
                        Label("Add Another Baby", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Baby Profiles")
                }

                if babies.count > 1 {
                    Section {
                        ForEach(babies) { b in
                            HStack {
                                Text(b.name)
                                    .font(.henriiBody)
                                Spacer()
                                if b.id == baby.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(HenriiColors.accentPrimary)
                                }
                            }
                        }
                    } header: {
                        Text("All Babies")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: HenriiSpacing.sm) {
                        Text("Insight Frequency")
                            .font(.henriiCallout)
                        Slider(value: $settings.insightFrequency, in: 0...1)
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

                    Picker("Tone", selection: $settings.aiTone) {
                        ForEach(AITone.allCases, id: \.self) { tone in
                            Text(tone.rawValue).tag(tone)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("AI Behavior")
                } footer: {
                    tonePreview
                }

                Section {
                    Toggle("Feeding reminders", isOn: $settings.feedingNotifications)
                        .tint(HenriiColors.accentPrimary)
                        .onChange(of: settings.feedingNotifications) { _, enabled in
                            if !enabled {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["feeding-reminder"])
                            }
                        }

                    if settings.feedingNotifications {
                        Stepper("Remind after \(String(format: "%.0f", settings.feedingReminderIntervalHours))h", value: $settings.feedingReminderIntervalHours, in: 1...6, step: 0.5)
                    }

                    Toggle("Sleep reminders", isOn: $settings.sleepNotifications)
                        .tint(HenriiColors.accentPrimary)
                    Toggle("Medication alerts", isOn: $settings.medicationNotifications)
                        .tint(HenriiColors.accentPrimary)
                        .onChange(of: settings.medicationNotifications) { _, enabled in
                            if !enabled {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["medication-pre", "medication-due"])
                            }
                        }

                    if settings.medicationNotifications {
                        Stepper("Pre-alert \(settings.medicationPreAlertMinutes) min before", value: $settings.medicationPreAlertMinutes, in: 5...60, step: 5)
                    }

                    Stepper("Daily summary at \(settings.dailySummaryHour):00", value: $settings.dailySummaryHour, in: 16...23)
                        .onChange(of: settings.dailySummaryHour) { _, newHour in
                            NotificationService.shared.scheduleDailySummaryNotification(at: newHour)
                        }
                } header: {
                    Text("Notifications")
                }

                Section {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(HenriiColors.accentPrimary)
                        TextField("Phone number", text: $settings.pediatricianPhone)
                            .keyboardType(.phonePad)
                    }
                } header: {
                    Text("Pediatrician")
                } footer: {
                    Text("Used for the \"Call Pediatrician\" button on medical alerts.")
                        .font(.henriiCaption)
                }

                Section {
                    Toggle("24-hour time", isOn: $settings.use24Hour)
                        .tint(HenriiColors.accentPrimary)
                    Toggle("Metric units (kg, cm, ml)", isOn: $settings.useMetric)
                        .tint(HenriiColors.accentPrimary)
                } header: {
                    Text("Units & Format")
                }

                Section {
                    Toggle("Enable caregivers", isOn: $settings.caregiversEnabled)
                        .tint(HenriiColors.accentPrimary)

                    if settings.caregiversEnabled {
                        Label("Co-Parent invite link", systemImage: "person.2.fill")
                        Label("Nanny/Sitter invite link", systemImage: "figure.and.child.holdinghands")
                        Label("Grandparent invite link", systemImage: "figure.2.and.child.holdinghands")
                    }
                } header: {
                    Text("Caregivers")
                }

                Section {
                    Toggle("Apple Health sync", isOn: $settings.appleHealthSyncEnabled)
                        .tint(HenriiColors.accentPrimary)
                    Toggle("Siri Shortcuts", isOn: $settings.siriShortcutsEnabled)
                        .tint(HenriiColors.accentPrimary)
                    Toggle("Apple Watch", isOn: $settings.appleWatchEnabled)
                        .tint(HenriiColors.accentPrimary)
                } header: {
                    Text("Integrations")
                }

                Section {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(HenriiColors.accentPrimary)
                        Text("All data stored on-device only")
                            .font(.henriiCallout)
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundStyle(HenriiColors.semanticAlert)
                    }
                } header: {
                    Text("Data & Privacy")
                } footer: {
                    Text("Your data never leaves this device. Henrii processes everything locally.")
                        .font(.henriiCaption)
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
            .sheet(isPresented: $showAddBaby) {
                AddBabyView { _ in }
            }
            .alert("Delete All Data?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all events and conversation history for \(baby.name). This cannot be undone.")
            }
        }
    }

    @ViewBuilder
    private var tonePreview: some View {
        let preview: String = {
            switch settings.aiTone {
            case .direct: return "\"8 feeds today. On track.\""
            case .warm: return "\"That's 8 feeds today \u{2014} right on track for this age.\""
            case .playful: return "\"8 feeds! \(baby.name) is keeping you busy today \u{1F60A}\""
            }
        }()
        Text(preview)
            .font(.henriiCaption)
            .foregroundStyle(HenriiColors.textTertiary)
            .italic()
    }

    private func deleteAllData() {
        let eventDescriptor = FetchDescriptor<BabyEvent>()
        let entryDescriptor = FetchDescriptor<ConversationEntry>()
        if let events = try? modelContext.fetch(eventDescriptor) {
            for event in events where event.baby?.id == baby.id {
                modelContext.delete(event)
            }
        }
        if let entries = try? modelContext.fetch(entryDescriptor) {
            for entry in entries where entry.babyID == baby.id {
                modelContext.delete(entry)
            }
        }
    }
}
