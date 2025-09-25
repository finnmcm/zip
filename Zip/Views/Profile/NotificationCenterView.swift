//
//  NotificationCenterView.swift
//  Zip
//
//  Created by Finn McMillan on 1/20/25.
//

import SwiftUI
import Inject

struct NotificationCenterView: View {
    @ObserveInjection var inject
    @StateObject private var fcmService = FCMService.shared
    @State private var selectedFilter: NotificationFilter = .all
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case orderUpdates = "Order Updates"
        case promotions = "Promotions"
        
        var displayName: String {
            return rawValue
        }
    }
    
    var filteredNotifications: [ZipNotification] {
        let notifications = fcmService.notifications
        
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .orderUpdates:
            return notifications.filter { 
                $0.type == .orderUpdate || 
                $0.type == .orderReady || 
                $0.type == .orderDelivered || 
                $0.type == .orderCancelled 
            }
        case .promotions:
            return notifications.filter { $0.type == .promotion }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(NotificationFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Notifications List
                if filteredNotifications.isEmpty {
                    EmptyNotificationsView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredNotifications) { notification in
                            NotificationRowView(notification: notification) {
                                fcmService.markAsRead(notification)
                            }
                        }
                        .onDelete(perform: deleteNotifications)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Mark All as Read") {
                            fcmService.markAllAsRead()
                        }
                        .disabled(fcmService.unreadCount == 0)
                        
                        Button("Clear All", role: .destructive) {
                            fcmService.clearAllNotifications()
                        }
                        .disabled(fcmService.notifications.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .enableInjection()
    }
    
    private func deleteNotifications(offsets: IndexSet) {
        for index in offsets {
            let notification = filteredNotifications[index]
            fcmService.removeNotification(withId: notification.id)
        }
    }
}

struct NotificationRowView: View {
    let notification: ZipNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: notification.type.iconName)
                    .foregroundColor(notification.type.priority == .high ? .red : 
                                   notification.type.priority == .medium ? .orange : .blue)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(notification.type.priority == .high ? .red.opacity(0.1) : 
                                 notification.type.priority == .medium ? .orange.opacity(0.1) : .blue.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    HStack {
                        Text(notification.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(notification.type.priority == .high ? .red.opacity(0.2) : 
                                         notification.type.priority == .medium ? .orange.opacity(0.2) : .blue.opacity(0.2))
                            )
                            .foregroundColor(notification.type.priority == .high ? .red : 
                                           notification.type.priority == .medium ? .orange : .blue)
                        
                        Spacer()
                        
                        Text(notification.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyNotificationsView: View {
    let filter: NotificationCenterView.NotificationFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(emptyTitle)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(emptyMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyIcon: String {
        switch filter {
        case .all:
            return "bell.slash"
        case .unread:
            return "checkmark.circle"
        case .orderUpdates:
            return "shippingbox"
        case .promotions:
            return "tag"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all:
            return "No Notifications"
        case .unread:
            return "All Caught Up!"
        case .orderUpdates:
            return "No Order Updates"
        case .promotions:
            return "No Promotions"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all:
            return "You'll see notifications about your orders, deliveries, and special offers here."
        case .unread:
            return "You've read all your notifications. Great job staying on top of things!"
        case .orderUpdates:
            return "No order updates yet. When you place an order, you'll see updates here."
        case .promotions:
            return "No promotions available right now. Check back later for special offers!"
        }
    }
}

#Preview {
    NotificationCenterView()
}
