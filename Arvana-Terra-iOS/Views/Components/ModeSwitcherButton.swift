import SwiftUI

struct ModeSwitcherButton: View {
    @ObservedObject var regionManager = RegionModeManager.shared

    var body: some View {
        Button(action: { regionManager.toggleMode() }) {
            HStack(spacing: 4) {
                Image(systemName: regionManager.displayMode.icon)
                    .font(.system(size: 12))
                Text(regionManager.displayMode.label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                regionManager.isRegionalMode
                    ? Color.primaryNavy
                    : Color.primaryNavy.opacity(0.1)
            )
            .foregroundColor(
                regionManager.isRegionalMode ? .white : Color.primaryNavy
            )
            .cornerRadius(20)
        }
    }
}
