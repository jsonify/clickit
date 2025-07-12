import SwiftUI

/// View for displaying automation session statistics
struct StatisticsView: View {
    @EnvironmentObject private var clickCoordinator: ClickCoordinator

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                Text("Session Statistics")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }

            HStack(spacing: 16) {
                statisticItem("Clicks", value: "\(clickCoordinator.clickCount)")
                statisticItem("Success Rate", value: "\(Int(clickCoordinator.successRate * 100))%")
                statisticItem("Avg Time", value: "\(Int(clickCoordinator.averageClickTime * 1000))ms")
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
    }

    @ViewBuilder
    private func statisticItem(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    StatisticsView()
        .environmentObject(ClickCoordinator.shared)
        .frame(width: 300, height: 100)
}