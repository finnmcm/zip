import Foundation
import SwiftUI

struct AdminView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            AdminAnalyticsView()
                .navigationTitle("Admin Dashboard")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}