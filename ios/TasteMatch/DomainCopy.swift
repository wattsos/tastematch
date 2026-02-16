import Foundation

enum DomainCopy {

    static func aboutBody(_ domain: TasteDomain) -> String {
        switch domain {
        case .space:
            return "\(Brand.name) was born from a simple idea: your space already knows your style. We built an engine that reads the visual DNA of your room — color temperature, texture, contrast — and translates it into a taste profile you can act on."
        case .objects:
            return "\(Brand.name) was born from a simple idea: your collection already signals your taste. We built an engine that reads the visual DNA of your objects — materials, form, finish — and translates it into a taste profile you can act on."
        case .art:
            return "\(Brand.name) was born from a simple idea: what you hang says everything. We built an engine that reads the visual DNA of your collection — palette, composition, movement — and translates it into a taste profile you can act on."
        }
    }

    static func aboutStep1(_ domain: TasteDomain) -> String {
        switch domain {
        case .space:   return "Snap a photo of any room or space you love."
        case .objects: return "Upload any watch, bag, or accessory you own."
        case .art:     return "Upload art you love or want to explore."
        }
    }

    static func historyLine(_ domain: TasteDomain) -> String {
        switch domain {
        case .space:   return "Every room you analyze will\nshow up here over time."
        case .objects: return "Every collection you analyze will\nshow up here over time."
        case .art:     return "Every collection you analyze will\nshow up here over time."
        }
    }

    static func evolutionLine(_ domain: TasteDomain) -> String {
        switch domain {
        case .space:   return "Analyze at least two rooms and\nwe'll map how your style shifts."
        case .objects: return "Analyze at least two collections and\nwe'll map how your taste shifts."
        case .art:     return "Analyze at least two collections and\nwe'll map how your taste shifts."
        }
    }
}
