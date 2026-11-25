import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Binding var mainPath: [MainRoute]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                Text("Home Page")
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("home.title")

                Text("Welcome, \(authViewModel.currentUser?.username ?? "Guest")")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("home.welcome")
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Today: \(DateFormatting.displayDate(from: Date()))", systemImage: "clock")
                Label("Holidays: Slovakia (SK) via Nager.Date", systemImage: "globe.europe.africa")
                Label("Try Siri: \"Add an event in CalendarReplica\"", systemImage: "sparkles")
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Button {
                    mainPath.append(.calendar)
                } label: {
                    Label("Calendar", systemImage: "calendar.day.timeline.left")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("home.openCalendar")

                Button(role: .destructive) {
                    authViewModel.signOut()
                } label: {
                    Label("SignOut", systemImage: "rectangle.portrait.and.arrow.right")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("home.signOut")
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
