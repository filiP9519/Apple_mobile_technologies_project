import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var password: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 36)

                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 52))
                        .foregroundStyle(.tint)

                    Text("Sign Up Page")
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("register.title")

                    Text("Create a local account stored securely with SwiftData.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("register.username")
                        .onChange(of: username) { _, _ in
                            authViewModel.clearError()
                        }

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.oneTimeCode)
                        .accessibilityIdentifier("register.password")
                        .onChange(of: password) { _, _ in
                            authViewModel.clearError()
                        }

                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("register.error")
                    }

                    Button {
                        authViewModel.register(username: username, password: password)
                    } label: {
                        Text("Register")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("register.submit")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )

                Button {
                    authViewModel.clearError()
                    dismiss()
                } label: {
                    Text("Already have an account? Login")
                        .font(.subheadline.weight(.medium))
                }
                .accessibilityIdentifier("register.goToLogin")

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
