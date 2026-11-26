import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AskResult: Identifiable, Hashable {
    let tool: OSINTTool
    let categoryName: String
    let score: Int
    let reason: String

    var id: String { tool.id }
}

struct AskCategoryGroup: Identifiable {
    let categoryName: String
    let results: [AskResult]
    var id: String { categoryName }
    var topScore: Int { results.first?.score ?? 0 }
}

struct DirectAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let url: URL
}

struct AskResponse {
    let query: String
    let detectedIntents: [String]
    let topPicks: [AskResult]
    let categoryGroups: [AskCategoryGroup]
    let directActions: [DirectAction]
    let webFallbacks: [DirectAction]
}

enum SearchEngine {
    struct IntentRule {
        let label: String
        let triggers: [String]
        let primaryCategories: [String]
        let secondaryCategories: [String]
        let flagshipTools: [String]
    }

    private static let stopwords: Set<String> = [
        "a", "an", "the", "and", "or", "for", "of", "to", "in", "on", "at", "by",
        "with", "from", "is", "are", "was", "were", "be", "been", "being",
        "can", "could", "would", "should", "do", "does", "did", "have", "has",
        "i", "me", "my", "you", "your", "someone", "somebody", "anyone", "person",
        "find", "search", "look", "lookup", "check", "get", "see", "show", "give",
        "tool", "tools", "site", "sites", "website", "app", "want", "need",
        "what", "which", "how", "if", "this", "that", "these", "those", "about",
        "online", "free", "best"
    ]

    static let suggestionQueries: [String] = [
        "find someone by username",
        "reverse image search",
        "who owns this phone number",
        "check if email was breached",
        "view photo EXIF data",
        "lookup domain owner & DNS",
        "find deleted or archived webpage",
        "trace a bitcoin wallet",
        "look up license plate or VIN",
        "search telegram channels"
    ]

    static let intentRules: [IntentRule] = [
        IntentRule(
            label: "Username Lookup",
            triggers: [
                "username", "usernames", "handle", "handles", "alias", "nick", "nickname",
                "screenname", "account", "accounts", "whatsmyname", "sherlock", "maigret",
                "namechk", "knowem", "profile", "profiles"
            ],
            primaryCategories: ["USERNAME"],
            secondaryCategories: ["PEOPLE", "UNIFIED SEARCH", "SOCIAL MEDIA", "ANALYTICS"],
            flagshipTools: ["WhatsMyName Web", "Username Checker", "Username Search", "maigret", "sherlock", "Namechk", "KnowEm"]
        ),
        IntentRule(
            label: "Email Investigation",
            triggers: [
                "email", "emails", "e-mail", "mail", "gmail", "protonmail", "address",
                "inbox", "mx", "header", "epieos", "holehe", "hunter", "ghunt", "verify email"
            ],
            primaryCategories: ["EMAIL"],
            secondaryCategories: ["DATA DUMP", "UNIFIED SEARCH", "IDENTITY RESOLUTION", "GOOGLE"],
            flagshipTools: ["Epieos Email Lookup", "holehe", "Intelligence X", "Email Verifier", "Email Header Analyzer", "GHunt"]
        ),
        IntentRule(
            label: "Data Breaches & Leaks",
            triggers: [
                "breach", "breached", "breaches", "pwned", "leak", "leaks", "leaked",
                "dump", "dumps", "hacked", "compromised", "exposed", "stealer",
                "dehashed", "hibp", "snusbase", "credentials", "credential"
            ],
            primaryCategories: ["DATA DUMP"],
            secondaryCategories: ["EMAIL", "DARKNET", "HASH RECOVERY", "UNIFIED SEARCH"],
            flagshipTools: ["Have I been pwned", "DeHashed", "Intelligence X", "Personal Data Leak Checker", "Snusbase", "DDoSecrets"]
        ),
        IntentRule(
            label: "Phone Number Lookup",
            triggers: [
                "phone", "phones", "number", "numbers", "caller", "call", "called",
                "cell", "mobile", "telephone", "carrier", "sms", "text", "truecaller",
                "phoneinfoga", "reverse phone", "who called"
            ],
            primaryCategories: ["PHONE"],
            secondaryCategories: ["PEOPLE", "IDENTITY RESOLUTION", "RESIDENT DATABASE"],
            flagshipTools: ["PhoneInfoga", "IntelTechniques Telephone", "Reverse Phone Lookup", "Truecaller Search Engine", "Who Called Me", "Phonerator"]
        ),
        IntentRule(
            label: "Reverse Image & Media",
            triggers: [
                "reverse image", "image", "images", "photo", "photos", "picture",
                "pictures", "pic", "pics", "screenshot", "visual", "tineye", "yandex",
                "steganography", "steg", "video", "youtube", "audio", "music"
            ],
            primaryCategories: ["IMAGE / VIDEO / AUDIO / MEDIA"],
            secondaryCategories: ["DOWNLOADER", "YOUTUBE", "MAPS", "TOOLSET"],
            flagshipTools: ["Yandex Images", "TinEye", "Google Images", "Bing Images", "See it, search it"]
        ),
        IntentRule(
            label: "EXIF & Photo Metadata",
            triggers: [
                "exif", "metadata", "meta", "camera", "when taken", "photo data",
                "image data", "gps photo", "geotag"
            ],
            primaryCategories: ["IMAGE / VIDEO / AUDIO / MEDIA"],
            secondaryCategories: ["TOOLSET", "DOWNLOADER"],
            flagshipTools: ["EXIF Data Viewer", "View Exif data online, remove Exif online", "unfurl", "StegOnline"]
        ),
        IntentRule(
            label: "Face Recognition",
            triggers: [
                "face", "faces", "facial", "selfie", "portrait", "lookalike", "pimeyes",
                "findclone", "recognize face", "who is in this photo"
            ],
            primaryCategories: ["IMAGE / VIDEO / AUDIO / MEDIA"],
            secondaryCategories: ["PEOPLE", "ID GENERATOR"],
            flagshipTools: ["PimEyes", "Findclone", "Yandex Images", "Face Photo Generator"]
        ),
        IntentRule(
            label: "Domain, DNS & WHOIS",
            triggers: [
                "domain", "domains", "dns", "whois", "subdomain", "subdomains", "ssl",
                "certificate", "cert", "registrar", "owns website", "website owner",
                "nameserver", "mxtoolbox", "securitytrails", "shodan"
            ],
            primaryCategories: ["WHOIS", "DOMAIN / IP / DNS"],
            secondaryCategories: ["RESOLVERS", "THREAT INTEL", "MALWARE"],
            flagshipTools: ["Who.is", "Whoxy", "Whois History", "SecurityTrails", "dnslytics", "domainbigdata"]
        ),
        IntentRule(
            label: "IP & Network Recon",
            triggers: [
                "ip", "ipv4", "ipv6", "asn", "bgp", "port", "ports", "server",
                "cloudflare", "resolver", "traceroute", "geolocation ip", "mac address"
            ],
            primaryCategories: ["DOMAIN / IP / DNS", "RESOLVERS"],
            secondaryCategories: ["THREAT INTEL", "IoT", "RADIO"],
            flagshipTools: ["Cloudflare Resolver", "dnslytics", "SecurityTrails", "IntelTechniques OSINT"]
        ),
        IntentRule(
            label: "People & Background",
            triggers: [
                "people", "person", "someone", "name", "full name", "background",
                "address", "relatives", "resident", "voter", "age", "idcrawl", "truepeoplesearch"
            ],
            primaryCategories: ["PEOPLE", "RESIDENT DATABASE", "VOTER DATABASES"],
            secondaryCategories: ["PUBLIC RECORDS", "PHONE", "IDENTITY RESOLUTION", "UNIFIED SEARCH"],
            flagshipTools: ["IDCrawl", "TruePeopleSearch", "WebMii", "InfoTracer", "JudyRecords"]
        ),
        IntentRule(
            label: "Geolocation & Maps",
            triggers: [
                "geo", "geolocate", "geolocation", "location", "map", "maps", "satellite",
                "street view", "panorama", "coordinates", "gps", "address", "building",
                "property", "real estate", "house", "weather"
            ],
            primaryCategories: ["MAPS", "GEO", "REAL ESTATE"],
            secondaryCategories: ["WEATHER", "IoT", "[CAN] IOT"],
            flagshipTools: ["Google Maps", "Yandex.Maps", "Bing Maps", "GeoNames", "GEOINT", "Realtor"]
        ),
        IntentRule(
            label: "Crypto & Blockchain",
            triggers: [
                "crypto", "cryptocurrency", "bitcoin", "btc", "ethereum", "eth",
                "wallet", "blockchain", "transaction", "tx", "token", "nft", "etherscan", "blockchair"
            ],
            primaryCategories: ["CRYPTOCURRENCY"],
            secondaryCategories: ["FINANCE", "DARKNET"],
            flagshipTools: ["Bitcoin Explorer", "Ethereum Block Explorer", "Blockchain Explorer", "Blockcypher", "Addresschecker.eu"]
        ),
        IntentRule(
            label: "Vehicles & License Plates",
            triggers: [
                "car", "vehicle", "vehicles", "vin", "license plate", "plate", "plates",
                "tag", "auto", "truck", "motorcycle"
            ],
            primaryCategories: ["LICENSE PLATE / VIN / VEHICLE"],
            secondaryCategories: ["PUBLIC RECORDS", "MAPS"],
            flagshipTools: ["VIN decoder", "Plate Recognizer", "License Plates of the World", "Poctra.com"]
        ),
        IntentRule(
            label: "Flights & Maritime",
            triggers: [
                "flight", "flights", "plane", "aircraft", "airport", "tail number", "adsb",
                "ads-b", "ship", "ships", "vessel", "boat", "maritime", "ais", "ocean"
            ],
            primaryCategories: ["FLIGHT TRACKER", "MARITIME"],
            secondaryCategories: ["MAPS", "GEO", "WEATHER"],
            flagshipTools: ["ADS-B Exchange", "FlightAware", "FlightAirMap", "Marine Traffic", "VesselFinder"]
        ),
        IntentRule(
            label: "Social Media Platforms",
            triggers: [
                "social", "social media", "socmint", "twitter", "tweet", "x", "nitter",
                "facebook", "fb", "instagram", "ig", "tiktok", "telegram", "tg",
                "discord", "reddit", "linkedin", "snapchat", "twitch", "youtube",
                "mastodon", "clubhouse", "onlyfans", "steam", "bot"
            ],
            primaryCategories: [
                "SOCIAL MEDIA", "TWITTER", "FACEBOOK", "INSTAGRAM", "TELEGRAM",
                "DISCORD", "REDDIT", "LINKEDIN", "TIKTOK", "YOUTUBE", "SNAPCHAT",
                "TWITCH", "MASTODON", "STEAM", "CLUBHOUSE", "ONLYFANS", "BOT"
            ],
            secondaryCategories: ["USERNAME", "ANALYTICS"],
            flagshipTools: ["Telegago", "TelegramDB.org", "Discord User Search", "LinkedIn X-Ray Search Tool", "TwitchTracker", "Botometer by OSoMe"]
        ),
        IntentRule(
            label: "Company & Finance",
            triggers: [
                "company", "companies", "business", "corp", "corporation", "llc",
                "incorporation", "sec", "finance", "financial", "executive", "owner", "org"
            ],
            primaryCategories: ["BUSINESS", "FINANCE", "[CAN] CORPORATION"],
            secondaryCategories: ["PUBLIC RECORDS", "GOVERNMENT", "IDENTITY RESOLUTION"],
            flagshipTools: ["Corporation Wiki", "Companies & Orgs Search Engine", "AllPeople", "WhaleSlide"]
        ),
        IntentRule(
            label: "Public, Court & Gov Records",
            triggers: [
                "court", "case", "lawsuit", "criminal", "arrest", "police", "cop",
                "misconduct", "registry", "offender", "sex offender", "government",
                "gov", "public record", "records", "foia", "informant"
            ],
            primaryCategories: ["PUBLIC RECORDS", "GOVERNMENT", "[CAN] GOVERNMENT", "POLICE / LE / FED", "[CAN] POLICE", "SEX OFFENDER", "INFORMANT"],
            secondaryCategories: ["VOTER DATABASES", "RESIDENT DATABASE", "BUSINESS"],
            flagshipTools: ["CourtListener", "JudyRecords", "Public Access to Court Electronic Records", "MuckRock", "NSOPW", "Openoversight"]
        ),
        IntentRule(
            label: "Darknet, Malware & Threat Intel",
            triggers: [
                "darknet", "dark web", "tor", "onion", "ransomware", "malware",
                "virus", "phishing", "threat", "cyber", "sandbox", "virustotal", "ahmia", "extremist"
            ],
            primaryCategories: ["DARKNET", "MALWARE", "THREAT INTEL"],
            secondaryCategories: ["EXTREMIST / FAR-RIGHT", "DATA DUMP", "PRIVACY / SECURITY"],
            flagshipTools: ["Ahmia — Search Tor Hidden Services", "VirusTotal", "Malpedia", "ransomwatch 👀 🦅", "Dark Tracer"]
        ),
        IntentRule(
            label: "Passwords & Hash Cracking",
            triggers: [
                "hash", "hashes", "md5", "sha1", "sha256", "crack", "decrypt",
                "password", "passwords", "rainbow", "wordlist"
            ],
            primaryCategories: ["HASH RECOVERY"],
            secondaryCategories: ["DATA DUMP", "TOOLSET"],
            flagshipTools: ["CrackStation", "Hashes.com", "Hashmob Community", "CyberChef"]
        ),
        IntentRule(
            label: "Archives & Deleted Pages",
            triggers: [
                "archive", "archived", "deleted", "wayback", "cached", "cache",
                "old website", "history", "snapshot", "paste", "pastebin", "news"
            ],
            primaryCategories: ["PRODUCTIVITY", "NEWS", "BLOG"],
            secondaryCategories: ["SOURCE CODES", "SEARCH ENGINES"],
            flagshipTools: ["Wayback Machine", "archive.is", "CachedPages", "Google Cached Pages of Any Website", "Oldweb.today"]
        ),
        IntentRule(
            label: "Google Dorking & Open Files",
            triggers: [
                "dork", "dorking", "google dork", "open directory", "ftp",
                "index of", "filetype", "pdf", "cse", "custom search", "dataset"
            ],
            primaryCategories: ["DORKING", "OPEN DIRECTORY", "GOOGLE CSE", "SEARCH ENGINES", "DATASET"],
            secondaryCategories: ["SOURCE CODES", "FILE UPLOAD"],
            flagshipTools: ["Google Hacking Database", "Google Dork Cheatsheet", "Open Directory Finder", "FilePhish", "Google Advanced Search"]
        ),
        IntentRule(
            label: "IoT, Webcams & Radio",
            triggers: [
                "webcam", "webcams", "camera", "cameras", "cctv", "traffic cam",
                "iot", "radio", "scanner", "frequency", "wifi", "wi-fi", "ssid", "wigle"
            ],
            primaryCategories: ["IoT", "[CAN] IOT", "RADIO"],
            secondaryCategories: ["MAPS", "DOMAIN / IP / DNS"],
            flagshipTools: ["Insecam", "Webcam Search Engine", "EarthCam", "WiGLE: Wireless Network Mapping", "Broadcastify", "RadioReference"]
        ),
        IntentRule(
            label: "Throwaway Contact & Fake ID",
            triggers: [
                "throwaway", "temp email", "temporary", "disposable", "burn", "burner",
                "fake", "generator", "dummy", "sockpuppet", "avatar", "ssn", "sandbox", "emulator"
            ],
            primaryCategories: ["THROWAWAY CONTACT", "ID GENERATOR", "SANDBOX / EMULATOR"],
            secondaryCategories: ["PRIVACY / SECURITY", "SECURE COMMUNICATION"],
            flagshipTools: ["10minutemail.com", "AnonAddy", "SimpleLogin", "Fake Name Generator", "Face Photo Generator", "Kasm"]
        )
    ]

    // Platform-specific boost map so "search telegram" or "twitter" highlights the exact platform category
    private static let platformCategoryMap: [String: String] = [
        "facebook": "FACEBOOK",
        "fb": "FACEBOOK",
        "twitter": "TWITTER",
        "tweet": "TWITTER",
        "nitter": "TWITTER",
        "youtube": "YOUTUBE",
        "yt": "YOUTUBE",
        "reddit": "REDDIT",
        "linkedin": "LINKEDIN",
        "google": "GOOGLE",
        "discord": "DISCORD",
        "twitch": "TWITCH",
        "instagram": "INSTAGRAM",
        "ig": "INSTAGRAM",
        "telegram": "TELEGRAM",
        "tg": "TELEGRAM",
        "snapchat": "SNAPCHAT",
        "snap": "SNAPCHAT",
        "mastodon": "MASTODON",
        "tiktok": "TIKTOK",
        "steam": "STEAM",
        "clubhouse": "CLUBHOUSE",
        "onlyfans": "ONLYFANS"
    ]

    static var isOnDeviceFoundationModelAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    static func rewriteQueryWithFoundationModelIfAvailable(_ query: String) async -> [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            do {
                let session = LanguageModelSession(
                    instructions: "Extract 3 to 6 concise OSINT search keywords (e.g. username, email, phone, breach, exif, domain, geolocation) from the user's request. Return comma-separated keywords only."
                )
                let response = try await session.respond(to: query)
                return response.content
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    .filter { !$0.isEmpty }
            } catch {
                return []
            }
        }
        #endif
        return []
    }

    static func search(
        query rawQuery: String,
        categories: [OSINTCategory],
        extraKeywords: [String] = []
    ) -> AskResponse {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        let rawTokens = tokenize(lower)
        let extraTokens = extraKeywords.flatMap { tokenize($0.lowercased()) }
        var tokens = Array(Set(rawTokens + extraTokens))
        if tokens.isEmpty && !lower.isEmpty {
            tokens = lower.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        }

        // Entity detection
        let detectedDomain = extractDomain(from: trimmed)
        let hasEmail = trimmed.contains("@") && detectedDomain != nil
        let hasIPv4 = extractIPv4(from: trimmed) != nil
        let hasPhoneDigits = trimmed.filter(\.isNumber).count >= 7 && !hasIPv4

        // Match intents
        var matchedIntents: [IntentRule] = []
        var primaryCatSet: Set<String> = []
        var secondaryCatSet: Set<String> = []
        var flagshipSet: Set<String> = []
        var intentReasonByCategory: [String: String] = [:]

        for rule in intentRules {
            let hit = rule.triggers.contains { trigger in
                if trigger.contains(" ") {
                    return lower.contains(trigger)
                }
                return tokens.contains(trigger) ||
                    tokens.contains(stem(trigger)) ||
                    lower.contains(trigger) && trigger.count >= 4
            }
            if hit {
                matchedIntents.append(rule)
                for cat in rule.primaryCategories {
                    primaryCatSet.insert(cat)
                    intentReasonByCategory[cat] = intentReasonByCategory[cat] ?? "Intent: \(rule.label)"
                }
                for cat in rule.secondaryCategories {
                    secondaryCatSet.insert(cat)
                    if intentReasonByCategory[cat] == nil {
                        intentReasonByCategory[cat] = "Related to \(rule.label)"
                    }
                }
                for tool in rule.flagshipTools {
                    flagshipSet.insert(tool.lowercased())
                }
            }
        }

        // Entity-driven category boosts
        if hasEmail {
            primaryCatSet.insert("EMAIL")
            secondaryCatSet.insert("DATA DUMP")
            intentReasonByCategory["EMAIL"] = intentReasonByCategory["EMAIL"] ?? "Detected email address"
        }
        if detectedDomain != nil && !hasEmail {
            primaryCatSet.insert("WHOIS")
            primaryCatSet.insert("DOMAIN / IP / DNS")
            intentReasonByCategory["WHOIS"] = intentReasonByCategory["WHOIS"] ?? "Detected domain name"
            intentReasonByCategory["DOMAIN / IP / DNS"] = intentReasonByCategory["DOMAIN / IP / DNS"] ?? "Detected domain name"
        }
        if hasIPv4 {
            primaryCatSet.insert("DOMAIN / IP / DNS")
            intentReasonByCategory["DOMAIN / IP / DNS"] = intentReasonByCategory["DOMAIN / IP / DNS"] ?? "Detected IP address"
        }
        if hasPhoneDigits {
            primaryCatSet.insert("PHONE")
            intentReasonByCategory["PHONE"] = intentReasonByCategory["PHONE"] ?? "Detected phone digits"
        }

        // Platform-specific boost
        var boostedPlatformCats: Set<String> = []
        for token in tokens {
            if let catName = platformCategoryMap[token] {
                boostedPlatformCats.insert(catName)
                intentReasonByCategory[catName] = "Platform: \(catName.capitalized)"
            }
        }

        var scored: [AskResult] = []
        for cat in categories {
            let catLower = cat.name.lowercased()
            let catTokens = tokenize(catLower)
            let isPlatformBoost = boostedPlatformCats.contains(cat.name)
            let isPrimary = primaryCatSet.contains(cat.name)
            let isSecondary = secondaryCatSet.contains(cat.name)

            for tool in cat.tools {
                var score = 0
                var reasons: [String] = []

                if isPlatformBoost {
                    score += 55
                } else if isPrimary {
                    score += 42
                } else if isSecondary {
                    score += 20
                }

                if (isPlatformBoost || isPrimary || isSecondary),
                   let intentReason = intentReasonByCategory[cat.name]
                {
                    reasons.append(intentReason)
                }

                let nameLower = tool.name.lowercased()
                let domainLower = tool.domain.lowercased()
                let noteLower = (tool.note ?? "").lowercased()
                let nameTokens = tokenize(nameLower)

                if flagshipSet.contains(nameLower) {
                    score += 28
                    reasons.append("Recommended tool")
                }

                var matchedTokenCount = 0
                for tok in tokens where tok.count >= 2 {
                    let tokStem = stem(tok)
                    var tokMatched = false

                    if nameTokens.contains(tok) || nameTokens.contains(tokStem) {
                        score += 30
                        tokMatched = true
                        reasons.append("Name matches '\(tok)'")
                    } else if nameLower.contains(tok) || (tokStem.count >= 4 && nameLower.contains(tokStem)) {
                        score += 20
                        tokMatched = true
                        reasons.append("Name contains '\(tok)'")
                    } else if domainLower.contains(tok) {
                        score += 18
                        tokMatched = true
                        reasons.append("Domain matches '\(tok)'")
                    } else if catTokens.contains(tok) || catLower.contains(tok) {
                        score += 14
                        tokMatched = true
                        if reasons.isEmpty {
                            reasons.append("Category '\(cat.name)'")
                        }
                    } else if !noteLower.isEmpty && noteLower.contains(tok) {
                        score += 12
                        tokMatched = true
                        reasons.append("Note matches '\(tok)'")
                    } else if tok.count >= 5 {
                        // Fuzzy typo tolerance against tool name tokens & category tokens
                        let fuzzyHit = (nameTokens + catTokens).contains { candidate in
                            candidate.count >= 4 && editDistance(tok, candidate) <= 2
                        }
                        if fuzzyHit {
                            score += 12
                            tokMatched = true
                            reasons.append("Fuzzy match for '\(tok)'")
                        }
                    }

                    if tokMatched {
                        matchedTokenCount += 1
                    }
                }

                // Multi-word bonus
                if matchedTokenCount >= 2 {
                    score += matchedTokenCount * 6
                }

                if score >= 18 {
                    let uniqueReasons = Array(NSOrderedSet(array: reasons)).compactMap { $0 as? String }
                    let reasonText = uniqueReasons.prefix(2).joined(separator: " · ")
                    scored.append(AskResult(
                        tool: tool,
                        categoryName: cat.name,
                        score: score,
                        reason: reasonText.isEmpty ? "Category: \(cat.name)" : reasonText
                    ))
                }
            }
        }

        scored.sort {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.tool.name.localizedCaseInsensitiveCompare($1.tool.name) == .orderedAscending
        }

        let topResults = Array(scored.prefix(60))
        let topPicks = Array(topResults.prefix(5))

        // Group remaining (or all topResults) by category, keeping highest-scoring categories first
        var groupedDict: [String: [AskResult]] = [:]
        for item in topResults {
            groupedDict[item.categoryName, default: []].append(item)
        }
        let categoryGroups = groupedDict.map { key, value in
            AskCategoryGroup(categoryName: key, results: value)
        }.sorted {
            if $0.topScore != $1.topScore { return $0.topScore > $1.topScore }
            return $0.categoryName < $1.categoryName
        }

        // Direct verified URL actions when user enters a domain
        var directActions: [DirectAction] = []
        if let domain = detectedDomain, !hasEmail {
            let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? domain
            if let whoisURL = URL(string: "https://who.is/whois/\(encodedDomain)") {
                directActions.append(DirectAction(
                    title: "Who.is Lookup: \(domain)",
                    subtitle: "Open WHOIS & DNS record directly",
                    systemImage: "doc.text.magnifyingglass",
                    url: whoisURL
                ))
            }
            if let archiveURL = URL(string: "https://web.archive.org/web/*/\(encodedDomain)") {
                directActions.append(DirectAction(
                    title: "Wayback Machine: \(domain)",
                    subtitle: "View archived snapshots of \(domain)",
                    systemImage: "clock.arrow.circlepath",
                    url: archiveURL
                ))
            }
        }

        // Web search fallback rows
        var webFallbacks: [DirectAction] = []
        let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let ddgURL = URL(string: "https://duckduckgo.com/?q=\(encodedQuery)") {
            webFallbacks.append(DirectAction(
                title: "Search DuckDuckGo for \"\(trimmed)\"",
                subtitle: "duckduckgo.com",
                systemImage: "safari",
                url: ddgURL
            ))
        }
        if let googleURL = URL(string: "https://www.google.com/search?q=\(encodedQuery)") {
            webFallbacks.append(DirectAction(
                title: "Search Google for \"\(trimmed)\"",
                subtitle: "google.com",
                systemImage: "magnifyingglass",
                url: googleURL
            ))
        }

        return AskResponse(
            query: trimmed,
            detectedIntents: matchedIntents.map(\.label),
            topPicks: topPicks,
            categoryGroups: categoryGroups,
            directActions: directActions,
            webFallbacks: webFallbacks
        )
    }

    private static func tokenize(_ text: String) -> [String] {
        let separators = CharacterSet.alphanumerics.inverted
        return text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 && !stopwords.contains($0) }
    }

    private static func stem(_ word: String) -> String {
        if word.hasSuffix("ies") && word.count > 4 {
            return String(word.dropLast(3)) + "y"
        }
        if word.hasSuffix("ed") && word.count > 4 {
            return String(word.dropLast(2))
        }
        if word.hasSuffix("ing") && word.count > 5 {
            return String(word.dropLast(3))
        }
        if word.hasSuffix("es") && word.count > 4 {
            return String(word.dropLast(2))
        }
        if word.hasSuffix("s") && word.count > 3 && !word.hasSuffix("ss") {
            return String(word.dropLast(1))
        }
        return word
    }

    private static func extractDomain(from text: String) -> String? {
        let pattern = #"(?i)\b([a-z0-9-]+\.)+[a-z]{2,}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text)
        else { return nil }
        return String(text[matchRange]).lowercased()
    }

    private static func extractIPv4(from text: String) -> String? {
        let pattern = #"\b(?:\d{1,3}\.){3}\d{1,3}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text)
        else { return nil }
        return String(text[matchRange])
    }

    private static func editDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let m = aChars.count
        let n = bChars.count
        if abs(m - n) > 2 { return 3 }
        if m == 0 { return n }
        if n == 0 { return m }

        var prev = Array(0...n)
        var curr = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,
                    curr[j - 1] + 1,
                    prev[j - 1] + cost
                )
            }
            swap(&prev, &curr)
        }
        return prev[n]
    }
}
