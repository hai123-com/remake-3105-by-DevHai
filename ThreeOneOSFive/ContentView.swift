import SwiftUI

// The original repository, patch, file and device screens remain instantiated here.
struct ContentView: View {
    @EnvironmentObject private var devHai: DevHaiStore
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @AppStorage(FeatureVisibility.developerModeStorageKey) private var developerModeEnabled = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var tabNavigation = AppTabNavigationState()
    @State private var showSettings = false
    @State private var showLogs = false

    var body: some View {
        Group {
            if horizontalSizeClass == .regular { regularLayout }
            else { compactLayout }
        }
        .tint(AppTheme.accent)
        .onChange(of: patchDraftCoordinator.request?.id) { id in
            if id != nil { tabNavigation.select(AppSection.tools.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { id in
            if id != nil { tabNavigation.select(AppSection.tools.rawValue) }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }
    private var compactLayout: some View {
        TabView(selection: Binding(get: { tabNavigation.selectedTab }, set: { tabNavigation.select($0) })) {
            ForEach(AppSection.allCases) { section in
                sectionContent(section)
                    .tabItem { Label(section.title, systemImage: section.systemImage) }
                    .tag(section.rawValue)
            }
        }
    }
    private var regularLayout: some View {
        NavigationSplitView {
            List(AppSection.allCases) { section in
                Button {
                    tabNavigation.select(section.rawValue)
                } label: {
                    Label(section.title, systemImage: section.systemImage)
                        .foregroundStyle(section.rawValue == tabNavigation.selectedTab ? AppTheme.accent : .primary)
                }.listRowBackground(section.rawValue == tabNavigation.selectedTab ? AppTheme.accent.opacity(0.15) : Color.clear)
            }
            .navigationTitle("DEVHAI")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        } detail: {
            sectionContent(AppSection(rawValue: tabNavigation.selectedTab) ?? .home)
        }
    }
    @ViewBuilder private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            DevHaiHomeView { tabNavigation.select($0.rawValue) }
        case .discover:
            if devHai.data.configuration.flags["Repository"] != false {
                DevHaiDiscoverView(onOpenSettings: openSettings, onOpenLogs: openLogs)
            } else { restricted("Repository entry has been disabled") }
        case .files:
            if !developerModeEnabled {
                restricted("Enable the original Developer Mode in Settings to access the file browser")
            } else if devHai.data.configuration.flags["Files"] == false {
                restricted("File browser entry has been disabled")
            } else {
                AppDataBrowserView(
                    tabSession: Binding(get: { tabNavigation.filesTabs }, set: { tabNavigation.setFilesTabs($0) }),
                    onOpenSettings: openSettings, onOpenLogs: openLogs
                )
            }
        case .tools:
            DevHaiToolsView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .profile:
            DevHaiProfileView()
        }
    }
    private func openSettings() { showSettings = true }
    private func openLogs() { showLogs = true }
}

extension AppSection {
    var title: String {
        switch self {
        case .home: return "Home"
        case .discover: return "Discover"
        case .files: return "Files"
        case .tools: return "Tools"
        case .profile: return "Profile"
        }
    }
    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .discover: return "shippingbox.fill"
        case .files: return "folder.fill"
        case .tools: return "hammer.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}
