import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Binding var authPath: [AuthRoute]

    @State private var username: String = ""
    @State private var password: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 36)

                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 54))
                        .foregroundStyle(.tint)

                    Text("Login Page")
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("login.title")

                    Text("Sign in to manage your calendar events and public holidays.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("login.username")
                        .onChange(of: username) { _, _ in
                            authViewModel.clearError()
                        }

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.oneTimeCode)
                        .accessibilityIdentifier("login.password")
                        .onChange(of: password) { _, _ in
                            authViewModel.clearError()
                        }

                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("login.error")
                    }

                    Button {
                        authViewModel.login(username: username, password: password)
                    } label: {
                        Text("Login")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("login.submit")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )

                Button {
                    authViewModel.clearError()
                    authPath.append(.register)
                } label: {
                    Text("Don't have an account? Sign Up")
                        .font(.subheadline.weight(.medium))
                }
                .accessibilityIdentifier("login.goToRegister")

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
