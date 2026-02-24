import SwiftUI
import SwiftData

struct AddVaccinationView: View {
    let baby: Baby
    var vaccination: Vaccination?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""

    private var isEditing: Bool { vaccination != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Vaccine name", text: $name)
                        .font(.henriiBody)
                    DatePicker("Date given", selection: $date, displayedComponents: .date)
                        .font(.henriiBody)
                }

                Section("Notes (optional)") {
                    TextField("Reactions, batch #, etc.", text: $notes, axis: .vertical)
                        .font(.henriiBody)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Vaccination" : "Add Vaccination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let vaccination {
                    name = vaccination.name
                    date = vaccination.date
                    notes = vaccination.notes ?? ""
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let vaccination {
            vaccination.name = trimmedName
            vaccination.date = date
            vaccination.notes = notes.isEmpty ? nil : notes
        } else {
            let vax = Vaccination(name: trimmedName, date: date, notes: notes.isEmpty ? nil : notes)
            vax.baby = baby
            modelContext.insert(vax)
        }
        dismiss()
    }
}
