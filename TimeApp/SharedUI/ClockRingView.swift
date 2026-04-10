import SwiftUI

struct ClockRingView: View {
    let timeline: DayTimeline?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 26)

                ForEach(ringSegments) { segment in
                    Circle()
                        .trim(from: segment.startFraction, to: segment.endFraction)
                        .stroke(
                            Color(token: segment.slice.color),
                            style: StrokeStyle(lineWidth: 26, lineCap: .butt)
                        )
                }
                .rotationEffect(.degrees(-90))

                VStack(spacing: 8) {
                    Text("24 小时")
                        .font(.headline)
                    Text("\(ringSegments.count) 段")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var ringSegments: [RingSegment] {
        guard let slices = timeline?.slices.sorted(by: { $0.startMinuteOfDay < $1.startMinuteOfDay }) else {
            return []
        }

        return slices.compactMap { slice in
            guard slice.durationMinutes > 0 else { return nil }
            let start = Double(slice.startMinuteOfDay) / 1_440.0
            let end = Double(slice.startMinuteOfDay + slice.durationMinutes) / 1_440.0
            return RingSegment(slice: slice, startFraction: start, endFraction: min(1, end))
        }
    }
}

private struct RingSegment: Identifiable {
    let id = UUID()
    let slice: TimelineSlice
    let startFraction: Double
    let endFraction: Double
}

