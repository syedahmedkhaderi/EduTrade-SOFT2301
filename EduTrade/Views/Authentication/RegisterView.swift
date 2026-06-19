import SwiftUI

/// Registration screen (spec §4.1, §12.2).
struct RegisterView: View {
    @StateObject private var vm = AuthViewModel()

    @State private var showPassword = false
    @State private var hasTouchedEmail = false
    @State private var hasTouchedPassword = false

    var body: some View {
        Form {
            Section {
                TextField("Full Name", text: $vm.fullName)
                    .textContentType(.name)
                    .autocorrectionDisabled()

                TextField("University Email", text: $vm.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: vm.email) { _, _ in hasTouchedEmail = true }

                if hasTouchedEmail && !vm.email.isEmpty && !vm.isEmailValid {
                    Label("Must be a valid @udst.edu.qa address", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: { Text("Your Details") }

            Section {
                HStack {
                    Group {
                        if showPassword {
                            TextField("Password", text: $vm.password)
                        } else {
                            SecureField("Password", text: $vm.password)
                        }
                    }
                    .textContentType(.newPassword)
                    .onChange(of: vm.password) { _, _ in hasTouchedPassword = true }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(Theme.mutedText)
                    }
                    .buttonStyle(.plain)
                }

                if hasTouchedPassword, let msg = Validators.passwordStrengthMessage(vm.password) {
                    Label(msg, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                SecureField("Confirm Password", text: $vm.confirmPassword)
                    .textContentType(.newPassword)

                if !vm.confirmPassword.isEmpty && !vm.doPasswordsMatch {
                    Label("Passwords don't match", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Security")
            } footer: {
                Text("Password must be at least 8 characters with one letter and one number.")
                    .font(.caption)
            }

            if let error = vm.errorMessage {
                Section { ErrorBanner(message: error) }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                Button {
                    Task { _ = await vm.register() }
                } label: {
                    HStack {
                        if vm.isLoading { ProgressView().tint(.white) }
                        Text("Create Account").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(vm.canSubmitRegister ? Theme.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canSubmitRegister)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}
