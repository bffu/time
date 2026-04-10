import Foundation

extension Int {
    var timeText: String {
        let hours = self / 60
        let minutes = self % 60
        if hours == 0 {
            return "\(minutes) 分钟"
        }
        return "\(hours) 小时 \(minutes) 分钟"
    }
}
