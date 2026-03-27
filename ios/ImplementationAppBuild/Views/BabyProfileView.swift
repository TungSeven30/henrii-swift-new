import SwiftUI
import SwiftData

struct BabyProfileView: View {
    @Bindable var baby: Baby
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showSettings: Bool = false
    @State private var showAddBaby: Bool = false
    @State private var showReport: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var exportCSV: String = ""
    @State private var showHandoff: Bool = false
    @State private var showAddVaccination: Bool = false
    @State private var editingVaccination: Vaccination?
    @State private var selectedMedicalFilter: MedicalNotesFilter = .all
    @State private var showVaccinationExport: Bool = false
    @State private var vaccinationExportText: String = ""
    @State private var showGrowthSheet: Bool = false
    @State private var settings = SettingsManager.shared

    private var babyEvents: [BabyEvent] {
        allEvents.filter { $0.baby?.id == baby.id }
    }

    private var growthEvents: [BabyEvent] {
        babyEvents.filter { $0.category == .growth }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HenriiSpacing.xl) {
                profileHeader
                vitalsSection
                pediatricianSection
                medicalNotesSection
                recentGrowthSection
                vaccinationsSection
                quickActionsSection
            }
            .padding(.horizontal, HenriiSpacing.horizontalMargin(for: sizeClass))
            .padding(.top, HenriiSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(HenriiColors.canvasPrimary)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSettings) {
            SettingsView(baby: baby)
        }
        .sheet(isPresented: $showAddBaby) {
            AddBabyView { _ in }
        }
        .sheet(isPresented: $showReport) {
            DoctorReportView(baby: baby, events: babyEvents)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportShareView(csv: exportCSV, babyName: baby.name)
        }
        .sheet(isPresented: $showHandoff) {
            NavigationStack {
                HandoffSummaryView(baby: baby, events: babyEvents)
            }
        }
        .sheet(isPresented: $showAddVaccination) {
            AddVaccinationView(baby: baby)
        }
        .sheet(item: $editingVaccination) { vax in
            AddVaccinationView(baby: baby, vaccination: vax)
        }
        .sheet(isPresented: $showVaccinationExport) {
            VaccinationExportView(text: vaccinationExportText, babyName: baby.name, vaccinations: baby.vaccinations)
        }
        .sheet(isPresented: $showGrowthSheet) {
            GrowthLogSheet(baby: baby, useMetric: settings.useMetric)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HenriiColors.textTertiary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(HenriiColors.textSecondary)
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: HenriiSpacing.md) {
            Group {
                if let photoData = baby.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Circle()
                        .fill(HenriiColors.accentPrimary.opacity(0.12))
                        .overlay {
                            Text(baby.name.prefix(1))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(HenriiColors.accentPrimary)
                        }
                }
            }
                .frame(width: 88, height: 88)
                .clipShape(Circle())

            Text(baby.name)
                .font(.henriiLargeTitle)
                .foregroundStyle(HenriiColors.textPrimary)

            Text("\(baby.gender.displayName) \u{2022} \(baby.ageDescription)")
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)

            Text("Born \(baby.birthDate, format: .dateTime.month(.wide).day().year())")
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HenriiSpacing.lg)
    }

    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Vitals")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            HStack(spacing: HenriiSpacing.md) {
                statCard(
                    value: baby.apgarScore.isEmpty ? "—" : baby.apgarScore,
                    label: "APGAR",
                    icon: "heart.text.square.fill",
                    color: HenriiColors.semanticAlert
                )
                statCard(
                    value: baby.birthWeightLbs.map { String(format: "%.1f lb", $0) } ?? "—",
                    label: "Birth weight",
                    icon: "scalemass.fill",
                    color: HenriiColors.dataGrowth
                )
            }

            HStack(spacing: HenriiSpacing.md) {
                statCard(
                    value: baby.birthLengthInches.map { String(format: "%.1f in", $0) } ?? "—",
                    label: "Birth length",
                    icon: "ruler.fill",
                    color: HenriiColors.dataGrowth
                )
                statCard(
                    value: baby.bloodType ?? "—",
                    label: "Blood type",
                    icon: "drop.fill",
                    color: HenriiColors.dataFeeding
                )
            }

            if let allergies = baby.allergies, !allergies.isEmpty {
                HStack(spacing: HenriiSpacing.xs) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(HenriiColors.semanticAlert)
                    Text("Allergies: \(allergies)")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
                .padding(HenriiSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.small))
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.sm) {
            HStack(spacing: HenriiSpacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }
            Text(value)
                .font(.henriiData(size: 28))
                .foregroundStyle(HenriiColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private var recentGrowthSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack {
                Text("Growth")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)
                Spacer()
                Picker("Units", selection: $settings.useMetric) {
                    Text("lb/in").tag(false)
                    Text("kg/cm").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            GrowthChartView(baby: baby, growthEvents: growthEvents, useMetric: settings.useMetric)

            Button { showGrowthSheet = true } label: {
                HStack(spacing: HenriiSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.callout)
                    Text("Add Measurement")
                        .font(.henriiCallout)
                }
                .foregroundStyle(HenriiColors.accentPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(HenriiColors.accentPrimary.opacity(0.1))
                .clipShape(.rect(cornerRadius: HenriiRadius.small))
            }

            if growthEvents.isEmpty {
                HStack {
                    Image(systemName: "ruler.fill")
                        .foregroundStyle(HenriiColors.dataGrowth)
                    Text("No growth measurements yet. Tell me a weight or height to start tracking.")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
                .padding(HenriiSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Actions")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            Button { showReport = true } label: {
                actionRow(icon: "doc.text.fill", title: "Generate Doctor's Report")
            }

            Button { generateAndShowExport() } label: {
                actionRow(icon: "square.and.arrow.up", title: "Export Data")
            }

            Button { showHandoff = true } label: {
                actionRow(icon: "arrow.right.arrow.left", title: "Handoff Summary")
            }

            Button { showAddBaby = true } label: {
                actionRow(icon: "plus.circle.fill", title: "Add Another Baby")
            }
        }
    }

    private var pediatricianSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Pediatrician")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            VStack(alignment: .leading, spacing: HenriiSpacing.sm) {
                Text(baby.pediatricianName ?? "Not added yet")
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textPrimary)

                if let appointment = baby.nextPediatricianAppointment {
                    Text("Next appointment: \(appointment, format: .dateTime.month(.abbreviated).day().hour().minute())")
                        .font(.henriiCaption)
                        .foregroundStyle(HenriiColors.textSecondary)
                }

                HStack(spacing: HenriiSpacing.md) {
                    let phone = (baby.pediatricianPhone?.isEmpty == false ? baby.pediatricianPhone! : SettingsManager.shared.pediatricianPhone)
                    if !phone.isEmpty,
                       let url = URL(string: "tel://\(phone.filter { $0.isNumber || $0 == "+" })") {
                        Link(destination: url) {
                            Label("Call", systemImage: "phone.fill")
                                .font(.henriiCallout)
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(HenriiColors.accentPrimary.opacity(0.12))
                                .clipShape(.rect(cornerRadius: HenriiRadius.small))
                        }
                    }
                    Link(destination: URL(string: "http://maps.apple.com")!) {
                        Label("Directions", systemImage: "map.fill")
                            .font(.henriiCallout)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(HenriiColors.canvasPrimary)
                            .clipShape(.rect(cornerRadius: HenriiRadius.small))
                    }
                }
            }
            .padding(HenriiSpacing.lg)
            .background(HenriiColors.canvasElevated)
            .clipShape(.rect(cornerRadius: HenriiRadius.medium))
        }
    }

    private var medicalNotesSection: some View {
        let healthEvents = babyEvents.filter { $0.category == .health }
        let filteredEvents = healthEvents.filter { selectedMedicalFilter.matches(event: $0) }

        return VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Medical Notes")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HenriiSpacing.sm) {
                    ForEach(MedicalNotesFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedMedicalFilter = filter
                        } label: {
                            Text(filter.title)
                                .font(.henriiCaption)
                                .foregroundStyle(selectedMedicalFilter == filter ? .white : HenriiColors.textPrimary)
                                .padding(.horizontal, HenriiSpacing.md)
                                .frame(height: 32)
                                .background(selectedMedicalFilter == filter ? HenriiColors.accentPrimary : HenriiColors.canvasElevated)
                                .clipShape(.capsule)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 0)

            if filteredEvents.isEmpty {
                Text(healthEvents.isEmpty ? "No medical notes yet." : "No entries for this filter yet.")
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textSecondary)
                    .padding(HenriiSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HenriiColors.canvasElevated)
                    .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            } else {
                ForEach(filteredEvents.prefix(5)) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.summaryText)
                                .font(.henriiCallout)
                                .foregroundStyle(HenriiColors.textPrimary)
                            Text(event.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.henriiCaption)
                                .foregroundStyle(HenriiColors.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(HenriiSpacing.lg)
                    .background(HenriiColors.canvasElevated)
                    .clipShape(.rect(cornerRadius: HenriiRadius.medium))
                }
            }
        }
    }

    private func actionRow(icon: String, title: String) -> some View {
        HStack(spacing: HenriiSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(HenriiColors.accentPrimary)
            Text(title)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(HenriiColors.textTertiary)
        }
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private var vaccinationsSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack {
                Text("Vaccinations")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)
                Spacer()
                if !baby.vaccinations.isEmpty {
                    Button {
                        vaccinationExportText = generateVaccinationCard()
                        showVaccinationExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.callout)
                            .foregroundStyle(HenriiColors.accentPrimary)
                    }
                }
                Button { showAddVaccination = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(HenriiColors.accentPrimary)
                }
            }

            if baby.vaccinations.isEmpty {
                HStack {
                    Image(systemName: "syringe.fill")
                        .foregroundStyle(HenriiColors.accentSecondary)
                    Text("No vaccinations recorded yet. Tap + to add one.")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
                .padding(HenriiSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            } else {
                let sorted = baby.vaccinations.sorted { $0.date > $1.date }
                ForEach(sorted) { vax in
                    Button {
                        editingVaccination = vax
                    } label: {
                        HStack(spacing: HenriiSpacing.md) {
                            Circle()
                                .fill(HenriiColors.accentSecondary.opacity(0.12))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Image(systemName: "syringe.fill")
                                        .font(.caption)
                                        .foregroundStyle(HenriiColors.accentSecondary)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(vax.name)
                                    .font(.henriiCallout)
                                    .foregroundStyle(HenriiColors.textPrimary)
                                HStack(spacing: HenriiSpacing.xs) {
                                    Text(vax.date, format: .dateTime.month(.abbreviated).day().year())
                                        .font(.henriiCaption)
                                        .foregroundStyle(HenriiColors.textTertiary)
                                    if let notes = vax.notes, !notes.isEmpty {
                                        Text("\u{2022} \(notes)")
                                            .font(.henriiCaption)
                                            .foregroundStyle(HenriiColors.textTertiary)
                                            .lineLimit(1)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(HenriiColors.textTertiary)
                        }
                        .padding(HenriiSpacing.lg)
                        .background(HenriiColors.canvasElevated)
                        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(vax)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    nonisolated private enum MedicalNotesFilter: CaseIterable, Sendable {
        case all
        case fever
        case medication
        case symptoms

        var title: String {
            switch self {
            case .all: "All"
            case .fever: "Fever"
            case .medication: "Medication"
            case .symptoms: "Symptoms"
            }
        }

        func matches(event: BabyEvent) -> Bool {
            switch self {
            case .all:
                return true
            case .fever:
                return (event.temperatureF ?? 0) >= 100.4
            case .medication:
                return event.medicationName != nil
            case .symptoms:
                return !(event.symptoms?.isEmpty ?? true)
            }
        }
    }

    private func generateAndShowExport() {
        exportCSV = generateCSV()
        showExportSheet = true
    }

    private func generateVaccinationCard() -> String {
        var lines: [String] = []
        lines.append("VACCINATION RECORD")
        lines.append("Name: \(baby.name)")
        lines.append("DOB: \(baby.birthDate.formatted(.dateTime.month(.wide).day().year()))")
        lines.append("")
        lines.append(String(repeating: "─", count: 40))
        let sorted = baby.vaccinations.sorted { $0.date < $1.date }
        for vax in sorted {
            lines.append("\(vax.date.formatted(.dateTime.month(.abbreviated).day().year()))  \(vax.name)")
            if let notes = vax.notes, !notes.isEmpty {
                lines.append("  Notes: \(notes)")
            }
        }
        lines.append(String(repeating: "─", count: 40))
        lines.append("Generated \(Date().formatted(.dateTime.month(.abbreviated).day().year()))")
        return lines.joined(separator: "\n")
    }

    private func generateCSV() -> String {
        var lines: [String] = ["Date,Time,Category,Details,Duration (min),Amount (oz)"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for event in babyEvents.reversed() {
            let date = formatter.string(from: event.timestamp)
            let time = timeFormatter.string(from: event.timestamp)
            let cat = event.category.rawValue
            let details = event.summaryText.replacingOccurrences(of: ",", with: ";")
            let dur = event.durationMinutes.map { String(format: "%.1f", $0) } ?? ""
            let amt = event.amountOz.map { String(format: "%.1f", $0) } ?? ""
            lines.append("\(date),\(time),\(cat),\(details),\(dur),\(amt)")
        }
        return lines.joined(separator: "\n")
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}
