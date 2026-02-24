import SwiftUI

struct CalendarStripView: View {
    let onSelectDate: (Date) -> Void
    @State private var selectedDate: Date = Date()

    private let calendar = Calendar.current
    private let dateRange: [Date] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<14).reversed().compactMap { offset in
            cal.date(byAdding: .day, value: -offset, to: today)
        }
    }()

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: HenriiSpacing.sm) {
                ForEach(dateRange, id: \.self) { date in
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isToday = calendar.isDateInToday(date)

                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedDate = date
                        }
                        onSelectDate(date)
                    } label: {
                        VStack(spacing: 2) {
                            Text(dayOfWeek(date))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(isSelected ? .white : HenriiColors.textTertiary)

                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? .white : isToday ? HenriiColors.accentPrimary : HenriiColors.textPrimary)
                        }
                        .frame(width: 36, height: 48)
                        .background(isSelected ? HenriiColors.accentPrimary : .clear)
                        .clipShape(.rect(cornerRadius: HenriiRadius.small))
                    }
                }
            }
        }
        .contentMargins(.horizontal, HenriiSpacing.margin)
        .scrollIndicators(.hidden)
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased().prefix(3).description
    }
}
