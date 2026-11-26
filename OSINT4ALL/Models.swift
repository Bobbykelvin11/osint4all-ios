import Combine
import Foundation
import SwiftUI

struct DirectoryPayload: Codable {
    let title: String
    let author: String
    let startMeURL: String
    let mirrorURL: String
    let categoryCount: Int
    let toolCount: Int
    let categories: [OSINTCategory]
}

struct OSINTCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let tools: [OSINTTool]
}

struct OSINTTool: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let url: String
    let domain: String
    let note: String?

    var parsedURL: URL? {
        URL(string: url)
    }
}

struct SearchMatch: Identifiable, Hashable {
    let tool: OSINTTool
    let categoryName: String
    var id: String { tool.id }
}

@MainActor
final class DirectoryStore: ObservableObject {
    @Published private(set) var categories: [OSINTCategory] = []
    @Published private(set) var totalToolCount: Int = 0
    @Published private(set) var author: String = "socmint (osint4all)"
    @Published private(set) var startMeURLString: String = "https://start.me/p/L1rEYQ/osint4all"
    @Published private(set) var mirrorURLString: String = "https://github.com/osint4all/osint4all.github.io"
    @Published var favoriteIDs: Set<String> = []
    @Published var recentSearches: [String] = []
    @Published var safariItem: SafariItem?

    private let favoritesKey = "osint4all.favorites.v1"
    private let recentSearchesKey = "osint4all.recentSearches.v1"

    init() {
        loadFavorites()
        loadRecentSearches()
        loadBundledDirectory()
    }

    private func loadBundledDirectory() {
        guard let url = Bundle.main.url(forResource: "links", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(DirectoryPayload.self, from: data)
        else {
            return
        }
        categories = payload.categories
        totalToolCount = payload.toolCount
        author = payload.author
        startMeURLString = payload.startMeURL
        mirrorURLString = payload.mirrorURL
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            favoriteIDs = Set(saved)
        }
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }

    private func loadRecentSearches() {
        if let saved = UserDefaults.standard.stringArray(forKey: recentSearchesKey) {
            recentSearches = saved
        }
    }

    func addRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }

    func isFavorite(_ tool: OSINTTool) -> Bool {
        favoriteIDs.contains(tool.id)
    }

    func toggleFavorite(_ tool: OSINTTool) {
        if favoriteIDs.contains(tool.id) {
            favoriteIDs.remove(tool.id)
        } else {
            favoriteIDs.insert(tool.id)
        }
        saveFavorites()
    }

    func openTool(_ tool: OSINTTool) {
        guard let url = tool.parsedURL,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return }
        safariItem = SafariItem(url: url)
    }

    func openURL(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return }
        safariItem = SafariItem(url: url)
    }

    func searchResults(for query: String) -> [SearchMatch] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        var matches: [SearchMatch] = []
        for cat in categories {
            let catMatches = cat.name.lowercased().contains(lower)
            for tool in cat.tools {
                if catMatches ||
                    tool.name.lowercased().contains(lower) ||
                    tool.domain.lowercased().contains(lower) ||
                    (tool.note?.lowercased().contains(lower) ?? false)
                {
                    matches.append(SearchMatch(tool: tool, categoryName: cat.name))
                }
            }
        }
        return matches
    }

    var favoriteMatches: [SearchMatch] {
        var list: [SearchMatch] = []
        for cat in categories {
            for tool in cat.tools where favoriteIDs.contains(tool.id) {
                list.append(SearchMatch(tool: tool, categoryName: cat.name))
            }
        }
        return list
    }

    static func symbolName(for categoryName: String) -> String {
        let upper = categoryName.uppercased()
        if upper.contains("PHONE") || upper.contains("SMS") { return "phone.fill" }
        if upper.contains("EMAIL") || upper.contains("MAIL") { return "envelope.fill" }
        if upper.contains("THROWAWAY") { return "trash.circle.fill" }
        if upper.contains("USER") || upper.contains("NAME") || upper.contains("IDENTITY") { return "person.text.rectangle.fill" }
        if upper.contains("PEOPLE") || upper.contains("PERSON") { return "person.2.fill" }
        if upper.contains("IMAGE") || upper.contains("PHOTO") || upper.contains("EXIF") { return "photo.on.rectangle" }
        if upper.contains("VIDEO") || upper.contains("YOUTUBE") || upper.contains("STREAM") || upper.contains("TWITCH") { return "play.rectangle.fill" }
        if upper.contains("MAP") || upper.contains("GEO") || upper.contains("SATELLITE") || upper.contains("FLIGHT") || upper.contains("MARITIME") || upper.contains("TRANSPORT") { return "map.fill" }
        if upper.contains("CRYPTO") || upper.contains("BITCOIN") || upper.contains("BLOCKCHAIN") { return "bitcoinsign.circle.fill" }
        if upper.contains("DARK") || upper.contains("TOR") || upper.contains("ONION") { return "eye.slash.fill" }
        if upper.contains("THREAT") || upper.contains("MALWARE") || upper.contains("BREACH") || upper.contains("LEAK") || upper.contains("SECURITY") || upper.contains("PRIVACY") { return "shield.lefthalf.filled" }
        if upper.contains("HASH") || upper.contains("PASSWORD") { return "key.fill" }
        if upper.contains("DOMAIN") || upper.contains("DNS") || upper.contains("IP") || upper.contains("NETWORK") || upper.contains("INFRA") { return "network" }
        if upper.contains("TWITTER") || upper.contains("FACEBOOK") || upper.contains("INSTAGRAM") || upper.contains("TELEGRAM") || upper.contains("DISCORD") || upper.contains("REDDIT") || upper.contains("SOCIAL") || upper.contains("TIKTOK") || upper.contains("LINKEDIN") { return "bubble.left.and.bubble.right.fill" }
        if upper.contains("SEARCH") || upper.contains("GOOGLE") || upper.contains("DORK") { return "magnifyingglass" }
        if upper.contains("ARCHIVE") || upper.contains("PAST") || upper.contains("NEWS") { return "newspaper.fill" }
        if upper.contains("FINANC") || upper.contains("COMPANY") || upper.contains("BUSINESS") || upper.contains("CORP") { return "building.2.fill" }
        if upper.contains("CODE") || upper.contains("TOOLSET") || upper.contains("SANDBOX") || upper.contains("EMULATOR") { return "wrench.and.screwdriver.fill" }
        if upper.contains("WEATHER") { return "cloud.sun.fill" }
        if upper.contains("FILE") || upper.contains("DOWNLOAD") || upper.contains("UPLOAD") { return "arrow.down.doc.fill" }
        return "folder.fill"
    }
}
