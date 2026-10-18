import SwiftUI
import UIKit

struct DevHaiLoginView: View {
    @EnvironmentObject private var store: DevHaiStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var enteredKey = ""
    @State private var isRevealed = false
    @State private var hasAppeared = false
    @State private var error: String?

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 36)
                    AppLogo(size: 104)
                        .scaleEffect(hasAppeared ? 1 : 0.85)
                        .shadow(color: AppTheme.accent.opacity(0.4), radius: 25)
                    Text("DEVHAI PREMIUM")
                        .font(.system(size: 29, weight: .heavy, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(.white)
                    Text("Premium iOS Management System")
                        .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                    Spacer(minLength: 20)
                    DHGlassCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Label("SECURE ACCESS SYSTEM", systemImage: "lock.shield.fill")
                                .font(.caption.weight(.bold)).tracking(1.2).foregroundStyle(AppTheme.cyan)
                            Text("Activate your license").font(.title3.bold())
                            HStack {
                                Image(systemName: "key.horizontal.fill").foregroundStyle(AppTheme.accent)
                                Group {
                                    if isRevealed { TextField("Activation key", text: $enteredKey) }
                                    else { SecureField("Activation key", text: $enteredKey) }
                                }
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .submitLabel(.go)
                                .onSubmit(activate)
                                Button { isRevealed.toggle() } label: {
                                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                                }
                                .accessibilityLabel(isRevealed ? "Hide key" : "Show key")
                            }
                            .padding(15)
                            .background(AppTheme.pageBackground, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.cardBorder))
                            if let error = error {
                                Label(error, systemImage: "exclamationmark.triangle")
                                    .font(.caption).foregroundStyle(.red)
                            }
                            Button(action: activate) {
                                Text("Activate").frame(maxWidth: .infinity)
                                    .font(.headline).padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            .background(LinearGradient(colors: [AppTheme.accent, AppTheme.cyan], startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 15))
                            .foregroundStyle(.white)
                            .disabled(enteredKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    if !store.demoMode {
                        Text("A production authentication service is required to activate remote licenses.")
                            .font(.caption).foregroundStyle(.orange)
                    }
                    Spacer(minLength: 32)
                    Text("iOS \(UIDevice.current.systemVersion)  •  Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")")
                        .font(.caption2).foregroundStyle(AppTheme.secondaryText)
                    Text("Made by DevHai  •  Based on 3105")
                        .font(.caption2).foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: 470)
                .frame(minHeight: geometry.size.height - 30)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            }
            .background {
                AppTheme.pageBackground.ignoresSafeArea()
                Circle().fill(AppTheme.accent.opacity(0.22)).frame(width: 350, height: 350)
                    .blur(radius: 120).offset(x: 150, y: -220)
            }
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.6)) { hasAppeared = true }
            }
        }
    }
    private func activate() {
        do { try store.authenticate(enteredKey); enteredKey = ""; error = nil }
        catch { self.error = error.localizedDescription }
    }
}

struct DevHaiHomeView: View {
    @EnvironmentObject private var store: DevHaiStore
    @EnvironmentObject private var appState: AppState
    @State private var popup: DHAnnouncement?
    @AppStorage("devhai.latest_demo_popup") private var lastPopupID = ""
    var openSection: (AppSection) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 12) {
                        AppLogo(size: 56)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("DEVHAI PREMIUM").font(.title3.bold()).foregroundStyle(.white)
                            Text("Premium iOS Management System").font(.caption).foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title2).foregroundStyle(AppTheme.cyan)
                    }
                    DHGlassCard {
                        Text(store.data.configuration.welcome)
                            .font(.title2.bold()).foregroundStyle(.white)
                        HStack {
                            Label(store.session?.role.rawValue ?? "", systemImage: "person.crop.circle.fill")
                            Spacer()
                            Text("LICENSE ACTIVE")
                        }.font(.caption.weight(.semibold)).foregroundStyle(AppTheme.cyan)
                        Divider().overlay(AppTheme.cardBorder)
                        Label(appState.isSupported ? "Original device policy: Supported" : "Original device policy: Unsupported",
                              systemImage: appState.isSupported ? "checkmark.circle" : "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(appState.isSupported ? .green : .orange)
                    }
                    // The administrator entry is intentionally visible immediately on Home,
                    // not buried inside Profile. The destination still checks the session role.
                    if store.isAdmin {
                        NavigationLink {
                            DevHaiAdminPanel()
                        } label: {
                            DHGlassCard {
                                HStack(spacing: 16) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 25, weight: .semibold))
                                        .foregroundStyle(AppTheme.cyan)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("ADMIN PANEL")
                                            .font(.headline.bold()).foregroundStyle(.white)
                                        Text("Open 20 management modules")
                                            .font(.caption).foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.headline).foregroundStyle(AppTheme.cyan)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open DEVHAI Admin Panel")
                    }
                    Text("QUICK ACCESS").font(.caption.bold()).tracking(2).foregroundStyle(AppTheme.secondaryText)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        quick("Discover", symbol: "shippingbox.fill", section: .discover)
                        quick("File Manager", symbol: "folder.fill", section: .files)
                        quick("Patch Tools", symbol: "hammer.fill", section: .tools)
                        quick("Profile", symbol: "person.crop.circle", section: .profile)
                    }
                    Text("ANNOUNCEMENTS").font(.caption.bold()).tracking(2).foregroundStyle(AppTheme.secondaryText)
                    if store.activeAnnouncements.isEmpty {
                        DHGlassCard { Text("No announcements yet").font(.subheadline).foregroundStyle(.secondary) }
                    } else {
                        ForEach(store.activeAnnouncements) { item in
                            DHGlassCard {
                                HStack { Image(systemName: item.icon).foregroundStyle(AppTheme.cyan); Text(item.title).bold() }
                                Text(item.message).font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                                Text(item.priority.uppercased()).font(.caption2).foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                    Text("NOTIFICATIONS").font(.caption.bold()).tracking(2).foregroundStyle(AppTheme.secondaryText)
                    if store.data.notifications.isEmpty {
                        DHGlassCard { Text("No in-app notifications").font(.caption).foregroundStyle(.secondary) }
                    } else {
                        ForEach(store.data.notifications.prefix(5)) { notification in
                            DHGlassCard {
                                HStack {
                                    Text(notification.title).font(.subheadline.bold())
                                    Spacer()
                                    if !notification.read {
                                        Button("Mark read") {
                                            if let index = store.data.notifications.firstIndex(where: { $0.id == notification.id }) {
                                                store.data.notifications[index].read = true
                                                store.save()
                                            }
                                        }.font(.caption)
                                    }
                                }
                                Text(notification.message).font(.caption).foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                    Text("Customized by DevHai • Based on original 3105")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(16)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("Home")
            .onAppear {
                guard let notice = store.activeAnnouncements.first(where: { $0.popup && $0.id.uuidString != lastPopupID }) else { return }
                popup = notice; lastPopupID = notice.id.uuidString
            }
            .alert(item: $popup) { value in
                Alert(title: Text(value.title), message: Text(value.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    private func quick(_ title: String, symbol: String, section: AppSection) -> some View {
        Button { openSection(section) } label: {
            DHGlassCard {
                Image(systemName: symbol).font(.title2).foregroundStyle(AppTheme.accent)
                Text(title).font(.subheadline.bold()).foregroundStyle(.white)
            }
        }.buttonStyle(.plain)
    }
}

struct DevHaiDiscoverView: View {
    @State private var page = 0
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            segmented(["Explore", "New", "Sources", "Search"], selection: $page)
            Group {
                switch page {
                case 0: RepositoryHomeView(onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
                case 1: RepositoryNewView(onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
                case 2: RepositorySourcesView(onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
                default: RepositorySearchView(onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct DevHaiToolsView: View {
    @EnvironmentObject private var store: DevHaiStore
    @State private var page = 0
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            segmented(["Patches", "Wallpapers", "Cleaner", "Logs"], selection: $page)
            Group {
                switch page {
                case 0:
                    if store.data.configuration.flags["Patch projects"] != false {
                        PatchProjectsView(onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
                    } else { restricted("Patches have been hidden in demo settings") }
                case 1:
                    if store.data.configuration.flags["Wallpapers"] != false { WallpaperLabView() }
                    else { restricted("Wallpaper tools have been hidden") }
                case 2:
                    if store.data.configuration.flags["Cleaner"] != false { CleanerView() }
                    else { restricted("Cleaner has been hidden") }
                default: LogView()
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct DevHaiProfileView: View {
    @EnvironmentObject private var store: DevHaiStore
    @State private var showSettings = false
    @State private var showSupport = false
    @State private var subject = ""
    @State private var detail = ""
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        AppLogo(size: 54)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DEVHAI PREMIUM").font(.headline)
                            Text(store.session?.role.rawValue ?? "USER").font(.caption).foregroundStyle(AppTheme.cyan)
                        }
                    }.padding(.vertical, 8)
                    LabeledContent("License", value: store.session?.licenseID.uuidString.prefix(8).description ?? "None")
                    if let expiry = store.session?.expires { LabeledContent("Session expires", value: expiry.formatted()) }
                }
                Section("Preferences") {
                    Button { showSettings = true } label: { Label("Original settings", systemImage: "gearshape.fill") }
                    Button { showSupport = true } label: { Label("Contact support", systemImage: "lifepreserver") }
                }
                if store.isAdmin {
                    Section("Administration") {
                        NavigationLink { DevHaiAdminPanel() } label: {
                            Label("ADMIN PANEL • 20 modules", systemImage: "crown.fill")
                        }
                    }
                }
                Section("About & credits") {
                    Text("Customized by DevHai • Based on the 3105 v2.0 project")
                    Text("Original authors and GPL-3.0 / third-party notices remain in the source repository.")
                        .font(.caption)
                    Link("Original 3105 project", destination: URL(string: "https://github.com/YangJiiii/3105")!)
                    Text(store.remoteInfo).font(.caption).foregroundStyle(AppTheme.cyan)
                }
                Section {
                    Button(role: .destructive) { store.logout() } label: { Label("Log out", systemImage: "rectangle.portrait.and.arrow.right") }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .navigationTitle("Profile")
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showSupport) {
                NavigationStack {
                    Form {
                        TextField("Subject", text: $subject)
                        TextField("Message", text: $detail, axis: .vertical)
                        Button("Submit request") {
                            store.addTicket(subject: subject, body: detail)
                            subject = ""; detail = ""; showSupport = false
                        }.disabled(subject.isEmpty || detail.isEmpty)
                    }
                    .navigationTitle("Support")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close") { showSupport = false } } }
                }
            }
        }
    }
}

struct DevHaiMaintenanceView: View {
    @EnvironmentObject private var store: DevHaiStore
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "wrench.adjustable.fill").font(.system(size: 44)).foregroundStyle(AppTheme.accent)
            Text("Maintenance Mode").font(.title.bold())
            Text(store.data.configuration.maintenanceMessage).multilineTextAlignment(.center)
            if !store.data.configuration.maintenanceReturn.isEmpty { Text(store.data.configuration.maintenanceReturn).font(.caption) }
            Button("Log out") { store.logout() }
        }
        .padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.pageBackground)
    }
}

func segmented(_ titles: [String], selection: Binding<Int>) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            ForEach(titles.indices, id: \.self) { index in
                Button { selection.wrappedValue = index } label: {
                    Text(titles[index]).font(.caption.bold()).padding(.horizontal, 16).padding(.vertical, 10)
                        .background(selection.wrappedValue == index ? AppTheme.accent : AppTheme.cardSurface,
                                    in: Capsule())
                        .foregroundStyle(selection.wrappedValue == index ? .white : AppTheme.secondaryText)
                }.buttonStyle(.plain)
            }
        }.padding(.horizontal, 12).padding(.vertical, 8)
    }.background(AppTheme.pageBackground)
}

func restricted(_ message: String) -> some View {
    VStack(spacing: 10) {
        Image(systemName: "lock.shield").font(.largeTitle).foregroundStyle(AppTheme.accent)
        Text(message).font(.subheadline).multilineTextAlignment(.center)
    }.frame(maxWidth: .infinity, maxHeight: .infinity).padding().background(AppTheme.pageBackground)
}
