import SwiftUI

struct HourlyUsageChartView: View {
    let hourlyUsages: [AppUsageHourly]

    var body: some View {
        GeometryReader { geometry in
            let buckets = aggregatedByHour
            let maxMinutes = max(buckets.map(\.minutes).max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(buckets) { bucket in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.8))
                            .frame(
                                width: max(8, (geometry.size.width - 92) / 24),
                                height: max(4, (geometry.size.height - 28) * CGFloat(bucket.minutes) / CGFloat(maxMinutes))
                            )

                        Text("\(bucket.hour)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var aggregatedByHour: [HourSlot] {
        var values = Array(repeating: 0, count: 24)
        for usage in hourlyUsages {
            values[usage.hour] += usage.minutes
        }
        return values.enumerated().map { HourSlot(hour: $0.offset, minutes: min($0.element, 60)) }
    }
}
