//
//  NotificationSettingsView.swift
//  Zip
//
//  Created by Finn McMillan on 1/20/25.
//

import SwiftUI
import Inject

struct NotificationSettingsView: View {
    @ObserveInjection var inject
    @StateObject private var fcmService = FCMService.shared
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Permission Status Section
                Section {
                    HStack {
                        Image(systemName: fcmService.isAuthorized ? "bell.fill" : "bell.slash")
                            .foregroundColor(fcmService.isAuthorized ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Notifications")
                                .font(.headline)
                            Text(fcmService.isAuthorized ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !fcmService.isAuthorized {
                            Button("Enable") {
                                requestNotificationPermission()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Status")
                } footer: {
                    if !fcmService.isAuthorized {
                        Text("Enable notifications to receive order updates, delivery alerts, and special promotions.")
                    }
                }
                
                // Notification Types Section
                if fcmService.isAuthorized {
                    Section {
                        ForEach(NotificationType.allCases, id: \.self) { type in
                            NotificationToggleRow(
                                type: type,
                                isEnabled: fcmService.notificationSettings.isEnabled(for: type)
                            ) {
                                fcmService.toggleNotificationType(type)
                            }
                        }
                    } header: {
                        Text("Notification Types")
                    } footer: {
                        Text("Choose which types of notifications you'd like to receive.")
                    }
                }
                
                // Statistics Section
                if fcmService.isAuthorized {
                    Section {
                        HStack {
                            Text("Unread Notifications")
                            Spacer()
                            Text("\(fcmService.unreadCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Total Notifications")
                            Spacer()
                            Text("\(fcmService.notifications.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        if fcmService.notifications.count > 0 {
                            Button("Clear All") {
                                fcmService.clearAllNotifications()
                            }
                            .foregroundColor(.red)
                        }
                    } header: {
                        Text("Statistics")
                    }
                }
                
                // FCM Token Section (Debug)
                #if DEBUG
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FCM Token")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let token = fcmService.fcmToken {
                            Text(token)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .lineLimit(3)
                        } else {
                            Text("No token available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Debug Info")
                }
                #endif
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .alert("Notification Permission", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(permissionAlertMessage)
            }
            .task {
                await fcmService.checkNotificationPermission()
            }
        }
        .enableInjection()
    }
    
    private func requestNotificationPermission() {
        Task {
            let granted = await fcmService.requestNotificationPermission()
            
            if !granted {
                await MainActor.run {
                    permissionAlertMessage = "Notifications are disabled. Please enable them in Settings to receive order updates and delivery alerts."
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct NotificationToggleRow: View {
    let type: NotificationType
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: type.iconName)
                .foregroundColor(type.priority == .high ? .red : type.priority == .medium ? .orange : .blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.body)
                
                Text(priorityDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
        }
        .padding(.vertical, 2)
    }
    
    private var priorityDescription: String {
        switch type.priority {
        case .high:
            return "Critical updates"
        case .medium:
            return "Important updates"
        case .low:
            return "Optional updates"
        }
    }
}

#Preview {
    NotificationSettingsView()
}
