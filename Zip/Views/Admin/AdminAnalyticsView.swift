//
//  AdminAnalyticsView.swift
//  Zip
//

import SwiftUI
import Charts

struct AdminAnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Controls
                VStack(spacing: 12) {
                    // Period Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Period Type")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Picker("Period", selection: $viewModel.selectedPeriodType) {
                            ForEach(TimePeriodType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.selectedPeriodType) { _, _ in
                            Task {
                                await viewModel.loadStatistics()
                            }
                        }
                    }
                    
                    // Time Range Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Range")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Picker("Range", selection: $viewModel.selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.selectedTimeRange) { _, _ in
                            Task {
                                await viewModel.loadStatistics()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Error State
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("Unable to load statistics")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.loadStatistics()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                // Loading State
                else if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading analytics...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                // Content
                else if !viewModel.statistics.isEmpty {
                    // Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        AnalyticsCard(
                            title: "Total Revenue",
                            value: viewModel.formattedTotalRevenue,
                            subtitle: growthText(viewModel.revenueGrowth),
                            icon: "dollarsign.circle.fill",
                            color: .green,
                            growth: viewModel.revenueGrowth
                        )
                        
                        AnalyticsCard(
                            title: "Total Orders",
                            value: "\(viewModel.totalOrders)",
                            subtitle: growthText(viewModel.ordersGrowth),
                            icon: "cart.fill",
                            color: .blue,
                            growth: viewModel.ordersGrowth
                        )
                        
                        AnalyticsCard(
                            title: "Avg Order Value",
                            value: viewModel.formattedAverageOrderValue,
                            subtitle: nil,
                            icon: "bag.fill",
                            color: .purple,
                            growth: nil
                        )
                        
                        AnalyticsCard(
                            title: "Completion Rate",
                            value: viewModel.formattedCompletionRate,
                            subtitle: nil,
                            icon: "checkmark.circle.fill",
                            color: completionRateColor(viewModel.completionRate),
                            growth: nil
                        )
                    }
                    .padding(.horizontal)
                    
                    // Revenue Chart
                    if viewModel.statistics.count > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Revenue Trend")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(viewModel.statistics.reversed()) { stat in
                                    LineMark(
                                        x: .value("Date", stat.periodStart),
                                        y: .value("Revenue", NSDecimalNumber(decimal: stat.totalRevenue).doubleValue)
                                    )
                                    .foregroundStyle(Color.green)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Date", stat.periodStart),
                                        y: .value("Revenue", NSDecimalNumber(decimal: stat.totalRevenue).doubleValue)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.05)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let doubleValue = value.as(Double.self) {
                                            Text("$\(Int(doubleValue))")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Orders Chart
                    if viewModel.statistics.count > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Orders Trend")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(viewModel.statistics.reversed()) { stat in
                                    BarMark(
                                        x: .value("Date", stat.periodStart),
                                        y: .value("Orders", stat.totalOrders)
                                    )
                                    .foregroundStyle(Color.blue)
                                }
                            }
                            .frame(height: 180)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Performance Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance Metrics")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            MetricRow(
                                icon: "clock.fill",
                                title: "Avg Completion Time",
                                value: viewModel.formattedAverageDeliveryTime,
                                color: .orange
                            )
                            
                            // Note: On-time delivery metric hidden until estimated/actual delivery times are added to orders table
                            // MetricRow(
                            //     icon: "checkmark.circle.fill",
                            //     title: "On-Time Delivery",
                            //     value: viewModel.formattedOnTimePercentage,
                            //     color: .green
                            // )
                            
                            if let currentStats = viewModel.currentPeriodStats {
                                MetricRow(
                                    icon: "person.2.fill",
                                    title: "New Customers",
                                    value: "\(currentStats.newCustomers)",
                                    color: .purple
                                )
                                
                                MetricRow(
                                    icon: "arrow.clockwise",
                                    title: "Returning Customers",
                                    value: "\(currentStats.returningCustomers)",
                                    color: .blue
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // Detailed Statistics List
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Period Details")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.statistics.prefix(10)) { stat in
                            StatisticDetailRow(statistic: stat)
                        }
                    }
                    .padding(.vertical, 8)
                    
                } else {
                    // Empty State
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No statistics available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Statistics will appear here once orders are placed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(.vertical)
        }
        .task {
            await viewModel.loadStatistics()
        }
        .refreshable {
            await viewModel.refreshStatistics()
        }
    }
    
    private func growthText(_ growth: Double?) -> String? {
        guard let growth = growth else { return nil }
        let sign = growth >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", growth))%"
    }
    
    private func completionRateColor(_ rate: Double) -> Color {
        if rate >= 95 {
            return .green
        } else if rate >= 85 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Analytics Card Component
struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let growth: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                if let growth = growth {
                    HStack(spacing: 2) {
                        Image(systemName: growth >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(String(format: "%.1f%%", abs(growth)))
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(growth >= 0 ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((growth >= 0 ? Color.green : Color.red).opacity(0.15))
                    )
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Metric Row Component
struct MetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Statistic Detail Row Component
struct StatisticDetailRow: View {
    let statistic: OrderStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(statistic.periodStart, style: .date)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(statistic.totalOrders) orders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                // Revenue
                VStack(alignment: .leading, spacing: 2) {
                    Text("Revenue")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("$\(NSDecimalNumber(decimal: statistic.totalRevenue).doubleValue, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Customers
                VStack(alignment: .leading, spacing: 2) {
                    Text("Customers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(statistic.uniqueCustomers)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Completion
                VStack(alignment: .leading, spacing: 2) {
                    Text("Completed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.0f%%", statistic.completionRate))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(completionColor(statistic.completionRate))
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func completionColor(_ rate: Double) -> Color {
        if rate >= 95 {
            return .green
        } else if rate >= 85 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    AdminAnalyticsView()
}

