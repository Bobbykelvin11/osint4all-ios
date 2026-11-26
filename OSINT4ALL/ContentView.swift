import SwiftUI

struct ContentView: View {
    @ObservedObject var store: DirectoryStore
    @State private var showAbout = false

    var body: some View {
        TabView {
            DirectoryTabView(store: store, showAbout: $showAbout)
                .tabItem {
                    Label("Directory", systemImage: "square.grid.2x2.fill")
                }

            FavoritesTabView(store: store, showAbout: $showAbout)
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }

            LiveWebTabView(directoryStore: store, showAbout: $showAbout)
                .tabItem {
                    Label("Live Page", systemImage: "globe")
                }
        }
        .tint(Color("AccentColor"))
        .sheet(item: $store.safariItem) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showAbout) {
            AboutView(store: store)
        }
    }
}

private struct DirectoryTabView: View {
    @ObservedObject var store: DirectoryStore
    @Binding var showAbout: Bool
    @State private var searchText = ""

    private var matches: [SearchMatch] {
        store.searchResults(for: searchText)
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    List {
                        Section {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color("AccentColor"))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(store.totalToolCount) OSINT Tools Offline")
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(store.categories.count) categories from OSINT4ALL")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        Section("Categories") {
                            ForEach(store.categories) { category in
                                NavigationLink(value: category) {
                                    HStack(spacing: 12) {
                                        Image(systemName: DirectoryStore.symbolName(for: category.name))
                                            .font(.body)
                                            .foregroundStyle(Color("AccentColor"))
                                            .frame(width: 26)
                                        Text(category.name)
                                            .font(.body.weight(.medium))
                                        Spacer()
                                        Text("\(category.tools.count)")
                                            .font(.caption.monospacedDigit())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.secondary.opacity(0.2))
                                            .clipShape(Capsule())
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .navigationDestination(for: OSINTCategory.self) { category in
                        CategoryDetailView(category: category, store: store)
                    }
                } else if matches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No Tools Found")
                            .font(.headline)
                        Text("Try searching a tool name, domain, or category.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        Section("\(matches.count) Results") {
                            ForEach(matches) { match in
                                ToolRow(
                                    tool: match.tool,
                                    categoryBadge: match.categoryName,
                                    store: store
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("OSINT4ALL")
            .searchable(text: $searchText, prompt: "Search \(store.totalToolCount) tools or domains...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
    }
}

private struct CategoryDetailView: View {
    let category: OSINTCategory
    @ObservedObject var store: DirectoryStore
    @State private var filterText = ""

    private var filteredTools: [OSINTTool] {
        let trimmed = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return category.tools }
        let lower = trimmed.lowercased()
        return category.tools.filter {
            $0.name.lowercased().contains(lower) ||
            $0.domain.lowercased().contains(lower) ||
            ($0.note?.lowercased().contains(lower) ?? false)
        }
    }

    var body: some View {
        List {
            Section("\(filteredTools.count) Tools") {
                ForEach(filteredTools) { tool in
                    ToolRow(tool: tool, categoryBadge: nil, store: store)
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $filterText, prompt: "Filter in \(category.name)...")
    }
}

private struct FavoritesTabView: View {
    @ObservedObject var store: DirectoryStore
    @Binding var showAbout: Bool
    @State private var searchText = ""

    private var filteredFavorites: [SearchMatch] {
        let favs = store.favoriteMatches
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return favs }
        let lower = trimmed.lowercased()
        return favs.filter {
            $0.tool.name.lowercased().contains(lower) ||
            $0.tool.domain.lowercased().contains(lower) ||
            $0.categoryName.lowercased().contains(lower)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.favoriteMatches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)
                        Text("No Favorites Yet")
                            .font(.headline)
                        Text("Tap the star on any tool in the Directory to save it here for offline access.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(32)
                } else {
                    List {
                        Section("\(filteredFavorites.count) Saved") {
                            ForEach(filteredFavorites) { match in
                                ToolRow(
                                    tool: match.tool,
                                    categoryBadge: match.categoryName,
                                    store: store
                                )
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        store.toggleFavorite(match.tool)
                                    } label: {
                                        Label("Remove", systemImage: "star.slash")
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Filter favorites...")
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
    }
}

private struct ToolRow: View {
    let tool: OSINTTool
    let categoryBadge: String?
    @ObservedObject var store: DirectoryStore

    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.openTool(tool)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(tool.domain)
                            .font(.caption)
                            .foregroundStyle(Color("AccentColor"))
                            .lineLimit(1)

                        if let badge = categoryBadge {
                            Text("· \(badge)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    if let note = tool.note, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                store.toggleFavorite(tool)
            } label: {
                Image(systemName: store.isFavorite(tool) ? "star.fill" : "star")
                    .font(.body)
                    .foregroundStyle(store.isFavorite(tool) ? Color.yellow : Color.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(store.isFavorite(tool) ? "Remove Favorite" : "Add Favorite")
        }
        .contextMenu {
            Button {
                store.openTool(tool)
            } label: {
                Label("Open in Safari View", systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string = tool.url
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }

            Button {
                store.toggleFavorite(tool)
            } label: {
                Label(
                    store.isFavorite(tool) ? "Remove Favorite" : "Add Favorite",
                    systemImage: store.isFavorite(tool) ? "star.slash" : "star"
                )
            }
        }
    }
}
