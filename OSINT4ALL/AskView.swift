import SwiftUI

struct AskView: View {
    @ObservedObject var store: DirectoryStore
    @Binding var showAbout: Bool

    @State private var query = ""
    @State private var response: AskResponse?
    @State private var isExpandingWithModel = false
    @FocusState private var isInputFocused: Bool

    private let chipColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                askSearchBar

                if let response {
                    resultsList(response)
                } else {
                    emptyPromptView
                }
            }
            .navigationTitle("Ask OSINT4ALL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .onChange(of: query) { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    response = nil
                } else {
                    response = SearchEngine.search(query: trimmed, categories: store.categories)
                }
            }
        }
    }

    private var askSearchBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color("AccentColor"))
                    .font(.body.weight(.semibold))

                TextField("Describe what you want to find...", text: $query)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.never)
                    .focused($isInputFocused)
                    .onSubmit {
                        submitQuery()
                    }

                if isExpandingWithModel {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                if !query.isEmpty {
                    Button {
                        query = ""
                        response = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color("AccentColor").opacity(isInputFocused ? 0.8 : 0.25), lineWidth: 1)
            )

            HStack {
                Label(
                    SearchEngine.isOnDeviceFoundationModelAvailable
                        ? "Offline AI + Intent Search"
                        : "Offline Intent & Fuzzy Search",
                    systemImage: "bolt.shield.fill"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)

                Spacer()

                Text("\(store.totalToolCount) tools indexed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
    }

    private var emptyPromptView: some View {
        List {
            Section("Try Asking") {
                LazyVGrid(columns: chipColumns, spacing: 8) {
                    ForEach(SearchEngine.suggestionQueries, id: \.self) { suggestion in
                        Button {
                            runSuggestion(suggestion)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkle.magnifyingglass")
                                    .font(.caption)
                                    .foregroundStyle(Color("AccentColor"))
                                Text(suggestion)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .listRowBackground(Color.clear)
            }

            if !store.recentSearches.isEmpty {
                Section {
                    ForEach(store.recentSearches, id: \.self) { recent in
                        Button {
                            runSuggestion(recent)
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                Text(recent)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent Searches")
                        Spacer()
                        Button("Clear") {
                            store.clearRecentSearches()
                        }
                        .font(.caption)
                        .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func resultsList(_ response: AskResponse) -> some View {
        List {
            if !response.detectedIntents.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(response.detectedIntents, id: \.self) { intent in
                                Label(intent, systemImage: "sparkles")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color("AccentColor").opacity(0.18))
                                    .foregroundStyle(Color("AccentColor"))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                } header: {
                    Text("Detected Intent")
                }
            }

            if !response.directActions.isEmpty {
                Section("Quick Actions") {
                    ForEach(response.directActions) { action in
                        Button {
                            store.openURL(action.url)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: action.systemImage)
                                    .foregroundStyle(Color("AccentColor"))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(action.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !response.topPicks.isEmpty {
                Section("Top Picks") {
                    ForEach(response.topPicks) { item in
                        ToolRow(
                            tool: item.tool,
                            categoryBadge: item.categoryName,
                            matchReason: item.reason,
                            store: store
                        )
                    }
                }
            }

            if response.categoryGroups.isEmpty {
                Section("Offline Directory") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No direct matches in the offline directory.")
                            .font(.subheadline.weight(.medium))
                        Text("Try different keywords (e.g. username, email, phone, exif, domain, breach) or search the web below.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                ForEach(response.categoryGroups) { group in
                    Section {
                        ForEach(group.results) { item in
                            ToolRow(
                                tool: item.tool,
                                categoryBadge: nil,
                                matchReason: item.reason,
                                store: store
                            )
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: DirectoryStore.symbolName(for: group.categoryName))
                            Text("\(group.categoryName) (\(group.results.count))")
                        }
                    }
                }
            }

            Section("Search the Web") {
                ForEach(response.webFallbacks) { fallback in
                    Button {
                        store.openURL(fallback.url)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: fallback.systemImage)
                                .foregroundStyle(Color("AccentColor"))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fallback.title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                Text(fallback.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
    }

    private func runSuggestion(_ text: String) {
        query = text
        submitQuery()
    }

    private func submitQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isInputFocused = false
        store.addRecentSearch(trimmed)
        response = SearchEngine.search(query: trimmed, categories: store.categories)

        if SearchEngine.isOnDeviceFoundationModelAvailable {
            isExpandingWithModel = true
            Task {
                let extra = await SearchEngine.rewriteQueryWithFoundationModelIfAvailable(trimmed)
                await MainActor.run {
                    isExpandingWithModel = false
                    if !extra.isEmpty, query.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
                        response = SearchEngine.search(
                            query: trimmed,
                            categories: store.categories,
                            extraKeywords: extra
                        )
                    }
                }
            }
        }
    }
}
