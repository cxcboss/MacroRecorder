import Foundation

struct MacroItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date
    var events: [MouseEvent]
    
    init(id: UUID = UUID(), name: String, events: [MouseEvent]) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.events = events
    }
    
    var eventCount: Int {
        events.count
    }
    
    var duration: TimeInterval {
        guard let lastEvent = events.last else { return 0 }
        return lastEvent.timestamp
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 1000)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
        } else {
            return String(format: "0:%02d.%03d", seconds, milliseconds)
        }
    }
}
