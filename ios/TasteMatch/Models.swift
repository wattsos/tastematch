import Foundation

struct TasteTag: Identifiable, Codable {
    let id: UUID
    let label: String
    let confidence: Double

    init(id: UUID = UUID(), label: String, confidence: Double) {
        self.id = id
        self.label = label
        self.confidence = confidence
    }
}

struct Signal: Identifiable, Codable {
    let id: UUID
    let key: String
    let value: String

    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

struct TasteProfile: Identifiable, Codable {
    let id: UUID
    let tags: [TasteTag]
    let story: String
    let signals: [Signal]

    init(id: UUID = UUID(), tags: [TasteTag], story: String, signals: [Signal]) {
        self.id = id
        self.tags = tags
        self.story = story
        self.signals = signals
    }
}

struct RecommendationItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let reason: String

    init(id: UUID = UUID(), title: String, subtitle: String, reason: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.reason = reason
    }
}

struct AnalyzeRequest: Codable {
    let imageData: [Data]
    let roomContext: String
    let goal: String
}

struct AnalyzeResponse: Codable {
    let tasteProfile: TasteProfile
    let recommendations: [RecommendationItem]
}

enum RoomContext: String, CaseIterable, Identifiable {
    case livingRoom = "Living Room"
    case bedroom = "Bedroom"
    case kitchen = "Kitchen"
    case office = "Office"
    case bathroom = "Bathroom"
    case outdoor = "Outdoor"

    var id: String { rawValue }
}

enum DesignGoal: String, CaseIterable, Identifiable {
    case refresh = "Quick Refresh"
    case overhaul = "Full Overhaul"
    case accent = "Add Accents"
    case organize = "Organize & Declutter"

    var id: String { rawValue }
}
