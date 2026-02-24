import SwiftUI
import SwiftData

struct SearchView: View {
    let baby: Baby
    let events: [BabyEvent]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedCategory: EventCategory?

    private var filteredEvents: [BabyEvent] {
        var result = events
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.summaryText.lowercased().contains(query) ||
                ($0.notes?.lowercased().contains(query) ?? false) ||
                ($0.medicationName?.lowercased().contains(query) ?? false) ||
                ($0.milestoneDescription?.lowercased().contains(query) ?? false) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryFilters

                if filteredEvents.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredEvents) { event in
                            searchResultRow(event)
                                .listRowBackground(HenriiColors.canvasElevated)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(HenriiColors.canvasPrimary)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search events...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HenriiColors.accentPrimary)
                }
            }
        }
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: HenriiSpacing.sm) {
                filterChip(label: "All", category: nil)
                filterChip(label: "Feeding", category: .feeding)
                filterChip(label: "Sleep", category: .sleep)
                filterChip(label: "Diapers", category: .diaper)
                filterChip(label: "Health", category: .health)
                filterChip(label: "Growth", category: .growth)
                filterChip(label: "Milestones", category: .milestone)
            }
            .padding(.horizontal, HenriiSpacing.margin)
            .padding(.vertical, HenriiSpacing.sm)
        }
        .scrollIndicators(.hidden)
    }

    private func filterChip(label: String, category: EventCategory?) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.henriiCallout)
                .foregroundStyle(selectedCategory == category ? .white : HenriiColors.textPrimary)
                .padding(.horizontal, HenriiSpacing.md)
                .padding(.vertical, HenriiSpacing.sm)
                .background(selectedCategory == category ? HenriiColors.accentPrimary : HenriiColors.canvasElevated)
                .clipShape(Capsule())
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
    }

    private func searchResultRow(_ event: BabyEvent) -> some View {
        HStack(spacing: HenriiSpacing.md) {
            Circle()
                .fill(Color(event.categoryColor).opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: event.icon)
                        .font(.callout)
                        .foregroundStyle(Color(event.categoryColor))
                }

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
    }

    private var emptyState: some View {
        VStack(spacing: HenriiSpacing.lg) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(HenriiColors.textTertiary)
            Text(searchText.isEmpty ? "Search for events" : "No results found")
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)
            Text(searchText.isEmpty ? "Try \"Tylenol\", \"sleep\", or \"bottle\"" : "Try a different search term")
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textTertiary)
            Spacer()
        }
    }
}
