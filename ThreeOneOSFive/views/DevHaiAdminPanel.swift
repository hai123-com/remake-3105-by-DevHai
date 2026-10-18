import SwiftUI
import Charts
import UniformTypeIdentifiers
import UIKit

// All 20 modules operate against the persisted local DEMO provider.
// Remote administration intentionally remains disabled until a trusted server is deployed.
enum DHAdminModule: Int, CaseIterable, Identifiable {
    case dashboard = 1, createKey, licenses, revoke, extend, devices, users,
         announcements, popups, logs, analytics, settings, maintenance, flags,
         releases, support, health, backup, notifications, security
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .createKey: return "Create license key"
        case .licenses: return "Key manager"
        case .revoke: return "Revoke license"
        case .extend: return "Extend license"
        case .devices: return "Device activations"
        case .users: return "Users & roles"
        case .announcements: return "Announcements"
        case .popups: return "Popup broadcasts"
        case .logs: return "Audit logs"
        case .analytics: return "Analytics"
        case .settings: return "App settings"
        case .maintenance: return "Maintenance mode"
        case .flags: return "Feature flags"
        case .releases: return "Release information"
        case .support: return "Support requests"
        case .health: return "System diagnostics"
        case .backup: return "Backup & restore"
        case .notifications: return "Notification center"
        case .security: return "Security center"
        }
    }
    var symbol: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .createKey: return "key.fill"
        case .licenses: return "key.horizontal.fill"
        case .revoke: return "lock.slash.fill"
        case .extend: return "calendar.badge.plus"
        case .devices: return "iphone.gen3"
        case .users: return "person.2.fill"
        case .announcements: return "megaphone.fill"
        case .popups: return "rectangle.on.rectangle.angled"
        case .logs: return "list.bullet.clipboard"
        case .analytics: return "chart.bar.fill"
        case .settings: return "slider.horizontal.3"
        case .maintenance: return "wrench.adjustable.fill"
        case .flags: return "switch.2"
        case .releases: return "shippingbox.fill"
        case .support: return "lifepreserver.fill"
        case .health: return "waveform.path.ecg"
        case .backup: return "externaldrive.fill.badge.timemachine"
        case .notifications: return "bell.badge.fill"
        case .security: return "shield.lefthalf.filled"
        }
    }
}

struct DevHaiAdminPanel: View {
    @EnvironmentObject private var store: DevHaiStore
    @State private var search = ""
    private let columns = [GridItem(.adaptive(minimum: 142), spacing: 12)]
    var body: some View {
        Group {
            if store.isAdmin && store.demoMode {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        DHGlassCard {
                            HStack(spacing: 14) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(AppTheme.accent)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("ADMIN CONTROL CENTER")
                                        .font(.headline.bold())
                                    Text("20 local demo modules • DevHai")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        TextField("Search admin features", text: $search)
                            .textFieldStyle(.roundedBorder)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(DHAdminModule.allCases.filter {
                                search.isEmpty || $0.title.localizedCaseInsensitiveContains(search)
                            }) { module in
                                // Explicit destination is reliable in both the Admin tab
                                // and the existing Home / Profile navigation stacks.
                                NavigationLink {
                                    DevHaiAdminDetail(module: module)
                                } label: {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Image(systemName: module.symbol)
                                            .font(.title2)
                                            .foregroundStyle(AppTheme.accent)
                                        Spacer(minLength: 0)
                                        Text(module.title)
                                            .font(.subheadline.weight(.semibold))
                                            .multilineTextAlignment(.leading)
                                            .foregroundStyle(.white)
                                        Text(String(format: "%02d", module.rawValue))
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 114, alignment: .leading)
                                    .padding(14)
                                    .background(AppTheme.cardSurface, in: RoundedRectangle(cornerRadius: 21))
                                    .overlay(RoundedRectangle(cornerRadius: 21).stroke(AppTheme.cardBorder, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
            } else {
                ContentUnavailableViewCompat(message: "Administrator access required")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("DEVHAI ADMIN")
        .tint(AppTheme.accent)
    }
}

private struct ContentUnavailableViewCompat: View {
    let message: String
    var body: some View { Text(message).font(.headline).padding().background(AppTheme.pageBackground) }
}

struct DHGlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
}

struct DevHaiAdminDetail: View {
    @EnvironmentObject private var store: DevHaiStore
    @Environment(\.openURL) private var openURL
    let module: DHAdminModule
    @State private var name = ""
    @State private var key = ""
    @State private var role: DevHaiRole = .user
    @State private var days = 30
    @State private var deviceLimit = 2
    @State private var note = ""
    @State private var title = ""
    @State private var message = ""
    @State private var priority = "Normal"
    @State private var announcementStart = Date()
    @State private var announcementEnd = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var hasAnnouncementEnd = false
    @State private var announcementIcon = "bell.fill"
    @State private var search = ""
    @State private var visibleCount = 25
    @State private var feedback: String?
    @State private var selectedLicenseID: UUID?
    @State private var confirmationPending = false
    @State private var backupURL: URL?
    @State private var showImporter = false
    @State private var confirmRestoreURL: URL?
    @State private var confirmRestore = false
    @State private var backupPreview = ""

    var body: some View {
        Group {
            if store.isAdmin && store.demoMode {
                details
            } else {
                Text("This module requires a trusted, authenticated backend or an ADMIN DEMO session.")
                    .padding()
            }
        }
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.accent)
        .alert("DEVHAI", isPresented: Binding(get: { feedback != nil }, set: { if !$0 { feedback = nil } })) {
            Button("OK") { feedback = nil }
        } message: { Text(feedback ?? "") }
        .confirmationDialog("Confirm revoke this license?", isPresented: $confirmationPending) {
            Button("Revoke license", role: .destructive) {
                if let id = selectedLicenseID { store.setRevoked(id, true) }
            }
        }
        .confirmationDialog("Import this backup? Existing demo settings will change.", isPresented: $confirmRestore) {
            Button("Restore settings") {
                if let url = confirmRestoreURL {
                    do { try store.restoreBackup(url); feedback = "Configuration restored" }
                    catch { feedback = error.localizedDescription }
                }
            }
        } message: { Text(backupPreview) }
    }
    @ViewBuilder private var details: some View {
        switch module {
        case .dashboard: dashboardPage
        case .createKey: createPage
        case .licenses: licensesPage
        case .revoke: revokePage
        case .extend: extendPage
        case .devices: devicesPage
        case .users: usersPage
        case .announcements: announcementsPage
        case .popups: popupsPage
        case .logs: logsPage
        case .analytics: analyticsPage
        case .settings: appSettingsPage
        case .maintenance: maintenancePage
        case .flags: flagsPage
        case .releases: releasePage
        case .support: supportPage
        case .health: healthPage
        case .backup: backupPage
        case .notifications: notificationsPage
        case .security: securityPage
        }
    }

    private var dashboardPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                DHGlassCard {
                    Text("LOCAL DEMO METRICS").font(.caption.bold()).foregroundStyle(AppTheme.accent)
                    Text("Not shared across devices").font(.caption).foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metric("Users", store.data.users.count)
                    metric("Active keys", store.data.licenses.filter { $0.status == "Active" }.count)
                    metric("Expired keys", store.data.licenses.filter { $0.status == "Expired" }.count)
                    metric("Revoked keys", store.data.licenses.filter(\.revoked).count)
                    metric("Local sessions", store.session == nil ? 0 : 1)
                    metric("Activations", store.data.licenses.reduce(0) { $0 + $1.devices.count })
                }
                Text("Latest activity").font(.headline)
                ForEach(store.data.logs.prefix(6)) { item in
                    DHGlassCard { Text(item.action).font(.subheadline.bold()); Text(item.date.formatted()).font(.caption).foregroundStyle(.secondary) }
                }
                Text("Recent announcements").font(.headline)
                ForEach(store.data.announcements.prefix(4)) { item in
                    DHGlassCard { Text(item.title).bold(); Text(item.message).font(.subheadline) }
                }
            }.padding(16)
        }.background(AppTheme.pageBackground)
    }
    private func metric(_ title: String, _ count: Int) -> some View {
        DHGlassCard {
            Text("\(count)").font(.largeTitle.bold()).foregroundStyle(AppTheme.accent)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var createPage: some View {
        Form {
            Section("Create DEMO license") {
                TextField("License name", text: $name)
                TextField("Key or generate a random key", text: $key)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button("Generate secure random key") { key = store.generateKey() }
                Picker("Role", selection: $role) { ForEach(DevHaiRole.allCases) { value in Text(value.rawValue).tag(value) } }
                Stepper("Validity: \(days) days", value: $days, in: 1...3650)
                Stepper("Device limit: \(deviceLimit)", value: $deviceLimit, in: 1...100)
                TextField("Note", text: $note)
                Button("Create license") {
                    do { try store.createLicense(name: name, key: key, role: role, days: days, limit: deviceLimit, note: note); feedback = "Demo license created" }
                    catch { feedback = error.localizedDescription }
                }.disabled(key.count < 8)
            }
            Section { Text("Keys are saved locally in demo mode. Production keys require server-side authorization and hashing.") }
        }
    }
    private var licensesPage: some View {
        Form {
            Section { TextField("Search keys or names", text: $search) }
            ForEach(store.data.licenses.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.key.localizedCaseInsensitiveContains(search) }) { license in
                Section(license.name) {
                    LabeledContent("Status", value: license.status)
                    LabeledContent("Role", value: license.role.rawValue)
                    LabeledContent("Devices", value: "\(license.devices.count)/\(license.deviceLimit)")
                    if let expires = license.expires { LabeledContent("Expires", value: expires.formatted(date: .abbreviated, time: .omitted)) }
                    Button("Copy demo key") { UIPasteboard.general.string = license.key; feedback = "Demo key copied" }
                    TextField("Note", text: Binding(get: { currentLicense(license.id)?.note ?? "" }, set: { value in updateLicense(license.id) { $0.note = value } }))
                    Picker("Role", selection: Binding(get: { currentLicense(license.id)?.role ?? .user }, set: { value in updateLicense(license.id) { $0.role = value } })) {
                        ForEach(DevHaiRole.allCases) { role in Text(role.rawValue).tag(role) }
                    }
                }
            }
        }
    }
    private var revokePage: some View {
        List {
            ForEach(store.data.licenses) { license in
                HStack {
                    VStack(alignment: .leading) { Text(license.name); Text(license.status).font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    if license.revoked {
                        Button("Restore") { store.setRevoked(license.id, false) }
                    } else {
                        Button("Revoke", role: .destructive) { selectedLicenseID = license.id; confirmationPending = true }
                    }
                }
            }
        }
    }
    private var extendPage: some View {
        Form {
            Picker("Extend by", selection: $days) {
                ForEach([1, 7, 30, 90, 365], id: \.self) { count in Text("\(count) days").tag(count) }
            }
            Stepper("Custom: \(days) days", value: $days, in: 1...3650)
            Section("Licenses") {
                ForEach(store.data.licenses) { license in
                    Button("Extend \(license.name)") { store.extendLicense(license.id, by: days); feedback = "Extended by \(days) days" }
                }
            }
        }
    }
    private var devicesPage: some View {
        List {
            Section { Text("Only a privacy-preserving, app-scoped installation ID is used. No UDID collection.").font(.caption) }
            ForEach(store.data.licenses) { license in
                Section(license.name) {
                    LabeledContent("Activations", value: "\(license.devices.count)/\(license.deviceLimit)")
                    ForEach(license.devices, id: \.self) { id in
                        Text(String(id.prefix(8)) + "…").font(.caption.monospaced())
                    }
                    Button("Reset device activations") { store.removeDevice(from: license.id) }
                        .disabled(license.devices.isEmpty)
                }
            }
        }
    }
    private var usersPage: some View {
        Form {
            Section("Add local demo user") {
                TextField("Display name", text: $name)
                Picker("Role", selection: $role) { ForEach(DevHaiRole.allCases) { role in Text(role.rawValue).tag(role) } }
                Button("Add user") {
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    store.data.users.append(DHUser(name: name, role: role)); store.appendLog("User created", name); name = ""
                }
            }
            ForEach(store.data.users) { user in
                Section(user.name) {
                    Toggle("Disabled", isOn: Binding(get: { findUser(user.id)?.disabled ?? false }, set: { value in updateUser(user.id) { $0.disabled = value } }))
                    Picker("Role", selection: Binding(get: { findUser(user.id)?.role ?? .user }, set: { value in updateUser(user.id) { $0.role = value } })) {
                        ForEach(DevHaiRole.allCases) { role in Text(role.rawValue).tag(role) }
                    }
                }
            }
        }
    }
    private var announcementsPage: some View { announcementEditor(isPopup: false) }
    private var popupsPage: some View { announcementEditor(isPopup: true) }
    private func announcementEditor(isPopup: Bool) -> some View {
        Form {
            Section(isPopup ? "Create popup" : "Publish announcement") {
                TextField("Title", text: $title)
                TextField("Message", text: $message, axis: .vertical).lineLimit(3...6)
                Picker("Priority", selection: $priority) { ForEach(["Normal", "Important", "Urgent"], id: \.self) { Text($0) } }
                DatePicker("Start date", selection: $announcementStart)
                Toggle("Set end date", isOn: $hasAnnouncementEnd)
                if hasAnnouncementEnd { DatePicker("End date", selection: $announcementEnd, in: announcementStart...) }
                Picker("Icon", selection: $announcementIcon) {
                    Text("Bell").tag("bell.fill")
                    Text("Shield").tag("shield.fill")
                    Text("Star").tag("star.fill")
                    Text("Important").tag("exclamationmark.triangle.fill")
                }
                Button(isPopup ? "Publish popup" : "Publish announcement") {
                    store.addAnnouncement(title: title, message: message, popup: isPopup, priority: priority,
                                          starts: announcementStart, ends: hasAnnouncementEnd ? announcementEnd : nil,
                                          icon: announcementIcon)
                    title = ""; message = ""
                }.disabled(title.isEmpty || message.isEmpty)
            }
            Section("Published entries") {
                ForEach(store.data.announcements.filter { $0.popup == isPopup }) { announcement in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(announcement.title).font(.headline)
                        TextField("Message", text: Binding(get: { getAnnouncement(announcement.id)?.message ?? "" }, set: { v in updateAnnouncement(announcement.id) { $0.message = v } }), axis: .vertical)
                        Text(announcement.starts.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                        Toggle("Published", isOn: Binding(get: { getAnnouncement(announcement.id)?.published ?? false }, set: { v in updateAnnouncement(announcement.id) { $0.published = v } }))
                        Button("Delete", role: .destructive) {
                            store.data.announcements.removeAll { $0.id == announcement.id }; store.appendLog("Announcement deleted", announcement.title)
                        }
                    }
                }
            }
        }
    }
    private var logsPage: some View {
        List {
            TextField("Filter events", text: $search)
            ForEach(store.data.logs.filter { search.isEmpty || $0.action.localizedCaseInsensitiveContains(search) || $0.message.localizedCaseInsensitiveContains(search) }.prefix(visibleCount)) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.action).font(.subheadline.bold())
                    Text(item.message).font(.caption)
                    Text(item.date.formatted()).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Button("Load more") { visibleCount += 25 }.disabled(visibleCount >= store.data.logs.count)
        }
    }
    private var analyticsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DHGlassCard {
                    Text("Demo license status distribution").font(.headline)
                    Chart {
                        BarMark(x: .value("Status", "Active"), y: .value("Keys", store.data.licenses.filter { $0.status == "Active" }.count))
                        BarMark(x: .value("Status", "Expired"), y: .value("Keys", store.data.licenses.filter { $0.status == "Expired" }.count))
                        BarMark(x: .value("Status", "Revoked"), y: .value("Keys", store.data.licenses.filter { $0.status == "Revoked" }.count))
                    }.frame(height: 200)
                }
                DHGlassCard {
                    Text("Audit event distribution").font(.headline)
                    Chart {
                        ForEach(Array(Set(store.data.logs.map(\.action))).sorted(), id: \.self) { action in
                            BarMark(x: .value("Event", action), y: .value("Count", store.data.logs.filter { $0.action == action }.count))
                        }
                    }.frame(height: 220)
                }
                Text("Charts reflect saved local demo records only.").font(.caption).foregroundStyle(.secondary)
            }.padding(16)
        }.background(AppTheme.pageBackground)
    }
    private var appSettingsPage: some View {
        Form {
            Section("General") {
                TextField("Welcome message", text: $store.data.configuration.welcome)
                Picker("Default language", selection: $store.data.configuration.defaultLanguage) {
                    Text("Tiếng Việt").tag("vi"); Text("English").tag("en")
                }
                Toggle("Show announcements", isOn: $store.data.configuration.announcementVisible)
            }
            Button("Save app settings") { store.save(); store.appendLog("Settings changed", "App preferences updated"); feedback = "Saved locally" }
        }
    }
    private var maintenancePage: some View {
        Form {
            Toggle("Maintenance enabled", isOn: $store.data.configuration.maintenance)
            TextField("Maintenance message", text: $store.data.configuration.maintenanceMessage, axis: .vertical)
            TextField("Return estimate (optional)", text: $store.data.configuration.maintenanceReturn)
            Button("Save maintenance state") { store.save(); store.appendLog("Maintenance changed", store.data.configuration.maintenance ? "Enabled" : "Disabled") }
            Text("Admin sessions can access this screen. This is local demo enforcement only.").font(.caption)
        }
    }
    private var flagsPage: some View {
        Form {
            ForEach(store.data.configuration.flags.keys.sorted(), id: \.self) { flag in
                Toggle(flag, isOn: Binding(get: { store.data.configuration.flags[flag] ?? false }, set: { value in
                    store.data.configuration.flags[flag] = value; store.save(); store.appendLog("Feature flag", "\(flag): \(value)")
                }))
            }
            Text("Flags control available navigation entries only. They never grant iOS permissions or exploit support.").font(.caption)
        }
    }
    private var releasePage: some View {
        Form {
            Section("Installed build") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
            }
            Section("Configured release") {
                TextField("Latest version", text: $store.data.configuration.latestVersion)
                TextField("Release notes", text: $store.data.configuration.releaseNotes, axis: .vertical)
                TextField("Official HTTPS URL", text: $store.data.configuration.updateURL)
                Button("Save release info") {
                    guard URL(string: store.data.configuration.updateURL)?.scheme == "https" else { feedback = "HTTPS URL required"; return }
                    store.save(); store.appendLog("Release settings", "Updated version metadata")
                }
                if let url = URL(string: store.data.configuration.updateURL), url.scheme == "https" {
                    Link("Open official update link", destination: url)
                }
            }
        }
    }
    private var supportPage: some View {
        Form {
            Section("Create request") {
                TextField("Subject", text: $title)
                TextField("Details", text: $message, axis: .vertical)
                Button("Submit") { store.addTicket(subject: title, body: message); title = ""; message = "" }.disabled(title.isEmpty || message.isEmpty)
            }
            ForEach(store.data.tickets) { ticket in
                Section(ticket.subject) {
                    Text(ticket.body)
                    Picker("Status", selection: Binding(get: { getTicket(ticket.id)?.status ?? "Open" }, set: { value in updateTicket(ticket.id) { $0.status = value } })) {
                        ForEach(["Open", "In progress", "Resolved"], id: \.self) { Text($0) }
                    }
                    TextField("Admin notes", text: Binding(get: { getTicket(ticket.id)?.adminNotes ?? "" }, set: { value in updateTicket(ticket.id) { $0.adminNotes = value } }))
                }
            }
        }
    }
    private var healthPage: some View {
        Form {
            Section("App & device (available metrics)") {
                LabeledContent("App", value: "DEVHAI PREMIUM")
                LabeledContent("iOS", value: UIDevice.current.systemVersion)
                LabeledContent("Device", value: UIDevice.current.model)
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                LabeledContent("Free volume space", value: freeDiskInfo)
                LabeledContent("Repository connectivity", value: "Not tested")
                LabeledContent("Current network", value: "Not tested")
                LabeledContent("App memory usage", value: "Unavailable in demo")
            }
            Section("Recent application events") {
                ForEach(store.data.logs.prefix(6)) { item in LabeledContent(item.action, value: item.date.formatted(date: .numeric, time: .shortened)) }
            }
        }
    }
    private var backupPage: some View {
        Form {
            Section("Export redacted configuration") {
                Button("Prepare backup") {
                    do { backupURL = try store.exportBackup(); feedback = "Backup prepared. Use Share backup to export." }
                    catch { feedback = error.localizedDescription }
                }
                if let backupURL = backupURL { ShareLink("Share backup", item: backupURL) }
            }
            Section("Import") {
                Button("Choose JSON backup") { showImporter = true }
                Text("Only app preferences and feature flags are imported. No license keys or private records are backed up.").font(.caption)
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                // Save to sandbox first: the external file access may expire after picker dismissal.
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let copied = FileManager.default.temporaryDirectory.appendingPathComponent("devhai-import-\(UUID().uuidString).json")
                do {
                    try FileManager.default.copyItem(at: url, to: copied)
                    let bytes = try Data(contentsOf: copied)
                    guard bytes.count <= 100_000,
                          let object = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
                          object["schema"] as? String == "devhai-demo-config-v1",
                          let welcome = object["welcome"] as? String,
                          let flags = object["flags"] as? [String: Bool] else {
                        throw DHError.message("Invalid backup schema")
                    }
                    backupPreview = "Welcome: \(String(welcome.prefix(50))) • \(flags.count) feature flags. License keys excluded."
                    confirmRestoreURL = copied
                    confirmRestore = true
                }
                catch { feedback = error.localizedDescription }
            case .failure(let error): feedback = error.localizedDescription
            }
        }
    }
    private var notificationsPage: some View {
        Form {
            Section("Create in-app notification") {
                TextField("Title", text: $title)
                TextField("Message", text: $message, axis: .vertical)
                HStack {
                    Button("Use maintenance template") { title = "Maintenance"; message = "Maintenance is scheduled." }
                    Button("Use update template") { title = "Update"; message = "An update is available." }
                }
                Button("Send in-app") { store.addNotice(title: title, message: message); title = ""; message = "" }.disabled(title.isEmpty || message.isEmpty)
            }
            Section("History") {
                ForEach(store.data.notifications) { notification in
                    HStack {
                        VStack(alignment: .leading) { Text(notification.title).bold(); Text(notification.message).font(.caption) }
                        Spacer()
                        Button(notification.read ? "Read" : "Mark read") {
                            if let idx = store.data.notifications.firstIndex(where: { $0.id == notification.id }) {
                                store.data.notifications[idx].read = true; store.save()
                            }
                        }.disabled(notification.read)
                        Button(role: .destructive) {
                            store.data.notifications.removeAll { $0.id == notification.id }; store.save()
                        } label: { Image(systemName: "xmark.circle") }
                    }
                }
            }
        }
    }
    private var securityPage: some View {
        Form {
            Section("Current session") {
                LabeledContent("Role", value: store.session?.role.rawValue ?? "None")
                LabeledContent("Device ID", value: String(store.deviceID.prefix(8)) + "…")
                if let expiration = store.session?.expires { LabeledContent("Expires", value: expiration.formatted()) }
                Button("Revoke this admin session", role: .destructive) { store.revokeAllSessions() }
            }
            Section("Local login protection") {
                Stepper("Session duration: \(store.data.configuration.sessionHours)h", value: $store.data.configuration.sessionHours, in: 1...168)
                Stepper("Failed login limit: \(store.data.configuration.failedLoginLimit)", value: $store.data.configuration.failedLoginLimit, in: 3...20)
                LabeledContent("Local failed attempts", value: "\(store.data.failedAttempts)")
                Button("Reset failed attempts") { store.data.failedAttempts = 0; store.appendLog("Login protection", "Local failed attempt counter reset") }
                Button("Save security preferences") { store.save(); store.appendLog("Security preferences", "Local limits changed") }
            }
            Section {
                Text("Changing administrator credentials and revoking remote sessions requires a trusted backend. Local demo settings are not production security.").font(.caption)
            }
        }
    }

    private var freeDiskInfo: String {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let bytes = attributes[.systemFreeSize] as? NSNumber else { return "Unavailable" }
        return ByteCountFormatter.string(fromByteCount: bytes.int64Value, countStyle: .file)
    }
    private func currentLicense(_ id: UUID) -> DHLicense? { store.data.licenses.first { $0.id == id } }
    private func updateLicense(_ id: UUID, _ edit: (inout DHLicense) -> Void) {
        guard store.requireAdmin(), let idx = store.data.licenses.firstIndex(where: { $0.id == id }) else { return }
        edit(&store.data.licenses[idx])
        if let uidx = store.data.users.firstIndex(where: { $0.licenseID == id }) {
            store.data.users[uidx].role = store.data.licenses[idx].role
        }
        store.save()
    }
    private func findUser(_ id: UUID) -> DHUser? { store.data.users.first { $0.id == id } }
    private func updateUser(_ id: UUID, _ edit: (inout DHUser) -> Void) {
        guard store.requireAdmin(), let idx = store.data.users.firstIndex(where: { $0.id == id }) else { return }
        edit(&store.data.users[idx])
        if let linked = store.data.users[idx].licenseID,
           let lidx = store.data.licenses.firstIndex(where: { $0.id == linked }) {
            store.data.licenses[lidx].role = store.data.users[idx].role
        }
        store.save()
        store.revalidate()
    }
    private func getAnnouncement(_ id: UUID) -> DHAnnouncement? { store.data.announcements.first { $0.id == id } }
    private func updateAnnouncement(_ id: UUID, _ edit: (inout DHAnnouncement) -> Void) {
        guard store.requireAdmin(), let idx = store.data.announcements.firstIndex(where: { $0.id == id }) else { return }
        edit(&store.data.announcements[idx]); store.save()
    }
    private func getTicket(_ id: UUID) -> DHTicket? { store.data.tickets.first { $0.id == id } }
    private func updateTicket(_ id: UUID, _ edit: (inout DHTicket) -> Void) {
        guard store.requireAdmin(), let idx = store.data.tickets.firstIndex(where: { $0.id == id }) else { return }
        edit(&store.data.tickets[idx]); store.save()
    }
}
