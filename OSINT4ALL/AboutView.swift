import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DirectoryStore

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("OSINT4ALL for iOS") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Categories", value: "\(store.categories.count)")
                    LabeledContent("Bundled Tools", value: "\(store.totalToolCount)")
                    LabeledContent("Browsing Mode", value: "Offline Directory + In-App Browser")
                    Text("All categories, tool titles, and URLs are bundled inside the app so you can search and favorite tools offline. Selecting any tool opens it in an in-app Safari view.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Credits & Attribution") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OSINT4ALL")
                            .font(.headline)
                        Text("Curated by \(store.author) and hosted on start.me.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)

                    Button {
                        if let url = URL(string: store.startMeURLString) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                store.openURL(url)
                            }
                        }
                    } label: {
                        Label("Open OSINT4ALL on start.me", systemImage: "globe")
                    }

                    Button {
                        if let url = URL(string: store.mirrorURLString) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                store.openURL(url)
                            }
                        }
                    } label: {
                        Label("OSINT4ALL GitHub Mirror", systemImage: "chevron.left.forwardslash.chevron.right")
                    }

                    Button {
                        if let url = URL(string: "https://start.me") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                store.openURL(url)
                            }
                        }
                    } label: {
                        Label("start.me Platform", systemImage: "square.grid.2x2")
                    }
                }

                Section("License") {
                    Text("The OSINT4ALL repository (osint4all/osint4all.github.io) is dedicated to the public domain under Creative Commons Zero v1.0 Universal (CC0 1.0).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
