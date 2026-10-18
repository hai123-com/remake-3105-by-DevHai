import Foundation
import SwiftUI
import Security
import CryptoKit
import UIKit

// DEVHAI DEMO backend. It is intentionally local-only and NEVER grants server authority.
// Configure a trusted remote service before distributing production licenses.
enum DevHaiRole: String, Codable, CaseIterable, Identifiable {
    case user = "USER"
    case admin = "ADMIN"
    var id: String { rawValue }
}

struct DHLicense: Codable, Identifiable {
    var id = UUID()
    var name: String
    var key: String // DEMO ONLY. Production servers must store hashes, not recoverable keys.
    var role: DevHaiRole
    var created = Date()
    var expires: Date?
    var maxActivations = 2
    var deviceLimit = 2
    var revoked = false
    var note = ""
    var devices: [String] = []
    var lastActivated: Date?
    var status: String {
        if revoked { return "Revoked" }
        if let expires = expires, expires <= Date() { return "Expired" }
        return "Active"
    }
}

struct DHAudit: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var action: String
    var message: String
}
struct DHAnnouncement: Codable, Identifiable {
    var id = UUID()
    var title: String
    var message: String
    var priority = "Normal"
    var starts = Date()
    var ends: Date? = nil
    var published = true
    var popup = false
    var icon = "bell.fill"
    var active: Bool { published && starts <= Date() && (ends == nil || ends! > Date()) }
}
struct DHTicket: Codable, Identifiable {
    var id = UUID()
    var subject: String
    var body: String
    var status = "Open"
    var adminNotes = ""
    var created = Date()
}
struct DHNotice: Codable, Identifiable {
    var id = UUID()
    var title: String
    var message: String
    var read = false
    var date = Date()
}
struct DHUser: Codable, Identifiable {
    var id = UUID()
    var name: String
    var role: DevHaiRole
    var disabled = false
    var licenseID: UUID? = nil
}
struct DHSession: Codable, Identifiable {
    var id = UUID()
    var licenseID: UUID
    var role: DevHaiRole
    var deviceID: String
    var started = Date()
    var expires: Date
}
struct DHConfiguration: Codable {
    var welcome = "Welcome to DevHai"
    var defaultLanguage = "vi"
    var announcementVisible = true
    var maintenance = false
    var maintenanceMessage = "System maintenance. Please return later."
    var maintenanceReturn = ""
    var sessionHours = 24
    var failedLoginLimit = 5
    var releaseNotes = "DEVHAI Premium UI and local demo administrator tools"
    var latestVersion = "1.1.1"
    var updateURL = "https://github.com/YangJiiii/3105/releases"
    var flags: [String: Bool] = [
        "Repository": true, "Files": true, "Wallpapers": true,
        "Patch projects": true, "Cleaner": true, "Experimental UI": false
    ]
}
struct DHSnapshot: Codable {
    var licenses: [DHLicense] = []
    var users: [DHUser] = []
    var announcements: [DHAnnouncement] = []
    var logs: [DHAudit] = []
    var tickets: [DHTicket] = []
    var notifications: [DHNotice] = []
    var configuration = DHConfiguration()
    var blockedDevices: [String] = []
    var failedAttempts: Int = 0
}

// App-scoped credentials, NOT a device fingerprint or an authentication backend.
enum DHKeychain {
    private static let service = "devhai.premium.demo"
    static func read(_ key: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: key,
            kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func write(_ key: String, _ value: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = Data(value.utf8)
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attrs as CFDictionary, nil)
    }
    static func delete(_ key: String) {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: key] as CFDictionary)
    }
}

// Endpoint contract for a future real production licensing backend.
protocol DHRemoteLicensing {
    func authenticate(key: String, deviceID: String) async throws -> Data
    func perform(endpoint: String, token: String, body: Data?) async throws -> Data
}
struct DHHTTPSClient: DHRemoteLicensing {
    let baseURL: URL
    func authenticate(key: String, deviceID: String) async throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: ["key": key, "device_id": deviceID])
        return try await request("/v1/licenses/activate", token: nil, body: data)
    }
    func perform(endpoint: String, token: String, body: Data? = nil) async throws -> Data {
        try await request(endpoint, token: token, body: body)
    }
    private func request(_ endpoint: String, token: String?, body: Data?) async throws -> Data {
        guard baseURL.scheme == "https", endpoint.hasPrefix("/v1/") else { throw DHError.message("Only HTTPS v1 endpoints are permitted") }
        let url = baseURL.appendingPathComponent(String(endpoint.dropFirst()))
        var request = URLRequest(url: url)
        request.httpMethod = body == nil ? "GET" : "POST"
        request.timeoutInterval = 15
        if let body = body { request.httpBody = body; request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if let token = token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let status = response as? HTTPURLResponse, (200..<300).contains(status.statusCode) else {
            throw DHError.message("Backend rejected request")
        }
        return data
    }
}
enum DHError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let message) = self { return message }; return nil }
}

final class DevHaiStore: ObservableObject {
    @Published var data: DHSnapshot
    @Published private(set) var session: DHSession?
    @Published var lastError: String?
    let deviceID: String
    let demoMode: Bool
    private let snapshotURL: URL
    private let sessionKey = "active_session"

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DevHaiPremium", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        snapshotURL = folder.appendingPathComponent("demo-admin.json")
        let configuredAPI = Bundle.main.object(forInfoDictionaryKey: "DEVHAI_API_BASE_URL") as? String ?? ""
        demoMode = configuredAPI.isEmpty
        if let saved = DHKeychain.read("installation_id") { deviceID = saved }
        else { let fresh = UUID().uuidString; deviceID = fresh; DHKeychain.write("installation_id", fresh) }
        if let bytes = try? Data(contentsOf: snapshotURL), let saved = try? JSONDecoder().decode(DHSnapshot.self, from: bytes) {
            data = saved
        } else {
            // These two keys grant NO authority outside the local demo app.
            var initial = DHSnapshot()
            initial.licenses = [
                DHLicense(name: "Demo User", key: "USER123", role: .user),
                DHLicense(name: "Demo Admin", key: "ADMINDEMO", role: .admin)
            ]
            initial.users = initial.licenses.map { DHUser(name: $0.name, role: $0.role, licenseID: $0.id) }
            initial.announcements = [DHAnnouncement(title: "DEVHAI PREMIUM", message: "Demo mode • Customized from 3105 v2.0")]
            data = initial
        }
        if let encoded = DHKeychain.read(sessionKey), let sessionData = Data(base64Encoded: encoded),
            let restored = try? JSONDecoder().decode(DHSession.self, from: sessionData) {
            session = restored
        } else { session = nil }
        revalidate()
    }

    var isAdmin: Bool { session?.role == .admin }
    var activeAnnouncements: [DHAnnouncement] { data.configuration.announcementVisible ? data.announcements.filter(\.active) : [] }
    var remoteInfo: String { demoMode ? "LOCAL DEMO • Not synchronized" : "Remote service configured • integration required" }

    func revalidate() {
        guard let existing = session else { return }
        guard demoMode, existing.expires > Date(),
              data.licenses.contains(where: { $0.id == existing.licenseID && $0.role == existing.role && $0.status == "Active" && $0.devices.contains(existing.deviceID) }) &&
              !data.users.contains(where: { $0.licenseID == existing.licenseID && $0.disabled }) else {
            session = nil; DHKeychain.delete(sessionKey); return
        }
    }

    func authenticate(_ input: String) throws {
        guard demoMode else { throw DHError.message("This build uses a remote API. Configure server authentication before use.") }
        guard data.failedAttempts < data.configuration.failedLoginLimit else {
            throw DHError.message("Too many failed attempts in this local demo. Contact the admin.")
        }
        let key = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let idx = data.licenses.firstIndex(where: { $0.key == key }) else {
            data.failedAttempts += 1
            appendLog("Failed authentication", "Invalid local demo key")
            throw DHError.message("Invalid activation key")
        }
        guard data.licenses[idx].status == "Active" else { throw DHError.message("This key has expired or been revoked") }
        if !data.licenses[idx].devices.contains(deviceID) {
            guard data.licenses[idx].devices.count < max(1, data.licenses[idx].deviceLimit) else { throw DHError.message("Device limit reached") }
            guard data.licenses[idx].devices.count < max(1, data.licenses[idx].maxActivations) else { throw DHError.message("Activation limit reached") }
            data.licenses[idx].devices.append(deviceID)
        }
        guard !data.blockedDevices.contains(deviceID) else { throw DHError.message("This demo device was disabled") }
        data.licenses[idx].lastActivated = Date()
        data.failedAttempts = 0
        let license = data.licenses[idx]
        guard !data.users.contains(where: { $0.licenseID == license.id && $0.disabled }) else {
            throw DHError.message("This account is disabled")
        }
        let newSession = DHSession(licenseID: license.id, role: license.role, deviceID: deviceID,
                                   expires: Date().addingTimeInterval(TimeInterval(max(1, data.configuration.sessionHours) * 3600)))
        session = newSession
        if let encoded = try? JSONEncoder().encode(newSession) { DHKeychain.write(sessionKey, encoded.base64EncodedString()) }
        appendLog("Login", "License: \(license.name) • \(license.role.rawValue)")
    }

    func logout() {
        if session != nil { appendLog("Logout", "Local demo session ended") }
        session = nil; DHKeychain.delete(sessionKey)
    }
    func requireAdmin() -> Bool { revalidate(); return demoMode && isAdmin }
    func appendLog(_ action: String, _ message: String) {
        // Caller must never pass plaintext keys or sensitive file data.
        data.logs.insert(DHAudit(action: action, message: message), at: 0)
        if data.logs.count > 800 { data.logs = Array(data.logs.prefix(800)) }
        save()
    }
    func save() {
        guard demoMode else { return }
        if let encoded = try? JSONEncoder().encode(data) { try? encoded.write(to: snapshotURL, options: [.atomic, .completeFileProtectionUnlessOpen]) }
        objectWillChange.send()
    }
    func createLicense(name: String, key: String, role: DevHaiRole, days: Int, limit: Int, note: String) throws {
        guard requireAdmin() else { throw DHError.message("Admin authorization required") }
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard clean.count >= 8, clean.count <= 80, clean.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }) else {
            throw DHError.message("Key must be 8–80 letters, digits, or hyphens")
        }
        guard !data.licenses.contains(where: { $0.key == clean }) else { throw DHError.message("Key already exists") }
        var record = DHLicense(name: name.isEmpty ? "Untitled" : name, key: clean, role: role)
        record.expires = Calendar.current.date(byAdding: .day, value: max(1, days), to: Date())
        record.deviceLimit = max(1, limit); record.maxActivations = max(1, limit)
        record.note = note
        data.licenses.append(record)
        data.users.append(DHUser(name: record.name, role: role, licenseID: record.id))
        appendLog("License created", "License ID: \(record.id.uuidString)")
    }
    func setRevoked(_ id: UUID, _ revoked: Bool) {
        guard requireAdmin(), let idx = data.licenses.firstIndex(where: { $0.id == id }) else { return }
        data.licenses[idx].revoked = revoked
        appendLog(revoked ? "License revoked" : "License restored", "License ID: \(id.uuidString)")
        revalidate()
    }
    func extendLicense(_ id: UUID, by days: Int) {
        guard requireAdmin(), let idx = data.licenses.firstIndex(where: { $0.id == id }) else { return }
        let base = max(data.licenses[idx].expires ?? Date(), Date())
        data.licenses[idx].expires = Calendar.current.date(byAdding: .day, value: max(1, days), to: base)
        appendLog("License extended", "Added \(days) days to license ID: \(id.uuidString)")
    }
    func removeDevice(from id: UUID) {
        guard requireAdmin(), let idx = data.licenses.firstIndex(where: { $0.id == id }) else { return }
        data.licenses[idx].devices = []
        appendLog("Device activations reset", "License ID: \(id.uuidString)")
        revalidate()
    }
    func addAnnouncement(title: String, message: String, popup: Bool, priority: String,
                         starts: Date = Date(), ends: Date? = nil, icon: String = "bell.fill") {
        guard requireAdmin(), !title.isEmpty, !message.isEmpty else { return }
        data.announcements.insert(DHAnnouncement(title: title, message: message, priority: priority,
                                                     starts: starts, ends: ends, popup: popup, icon: icon), at: 0)
        appendLog("Announcement published", title)
    }
    func addNotice(title: String, message: String) {
        guard requireAdmin(), !title.isEmpty, !message.isEmpty else { return }
        data.notifications.insert(DHNotice(title: title, message: message), at: 0)
        appendLog("In-app notice sent", title)
    }
    func addTicket(subject: String, body: String) {
        guard session != nil, !subject.isEmpty, !body.isEmpty else { return }
        data.tickets.insert(DHTicket(subject: subject, body: body), at: 0)
        appendLog("Support request", subject)
    }
    func revokeAllSessions() { guard requireAdmin() else { return }; logout() }
    func generateKey() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { return UUID().uuidString }
        return "DH-" + bytes.map { String(format: "%02X", $0) }.joined()
    }
    func exportBackup() throws -> URL {
        guard requireAdmin() else { throw DHError.message("Admin authorization required") }
        // Redact license secrets, device IDs and activity details. No user data is exported.
        let safe: [String: Any] = [
            "schema": "devhai-demo-config-v1",
            "welcome": data.configuration.welcome,
            "language": data.configuration.defaultLanguage,
            "announcementVisible": data.configuration.announcementVisible,
            "releaseNotes": data.configuration.releaseNotes,
            "latestVersion": data.configuration.latestVersion,
            "updateURL": data.configuration.updateURL,
            "flags": data.configuration.flags
        ]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("DEVHAI-demo-backup.json")
        try JSONSerialization.data(withJSONObject: safe, options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
        appendLog("Backup exported", "Redacted demo configuration")
        return url
    }
    func restoreBackup(_ url: URL) throws {
        guard requireAdmin() else { throw DHError.message("Admin authorization required") }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let content = try Data(contentsOf: url)
        guard content.count <= 100_000,
              let object = try JSONSerialization.jsonObject(with: content) as? [String: Any],
              object["schema"] as? String == "devhai-demo-config-v1",
              let welcome = object["welcome"] as? String, welcome.count <= 300,
              let flags = object["flags"] as? [String: Bool] else { throw DHError.message("Unsupported or invalid backup") }
        data.configuration.welcome = welcome
        data.configuration.flags = flags
        if let value = object["language"] as? String { data.configuration.defaultLanguage = value }
        if let value = object["announcementVisible"] as? Bool { data.configuration.announcementVisible = value }
        if let value = object["releaseNotes"] as? String { data.configuration.releaseNotes = String(value.prefix(5000)) }
        if let value = object["latestVersion"] as? String { data.configuration.latestVersion = String(value.prefix(40)) }
        if let value = object["updateURL"] as? String, URL(string: value)?.scheme == "https" { data.configuration.updateURL = value }
        appendLog("Backup restored", "Demo configuration imported")
    }
}
