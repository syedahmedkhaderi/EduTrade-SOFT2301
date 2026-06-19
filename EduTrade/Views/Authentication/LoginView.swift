import SwiftUI

/// Login screen (spec §4.1, §12.4).
struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var showPassword = false

    var body: some View {
        Form {
            Section {
                TextField("University Email", text: $vm.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                HStack {
                    Group {
                        if showPassword {
                            TextField("Password", text: $vm.password)
                        } else {
                            SecureField("Password", text: $vm.password)
                        }
                    }
                    .textContentType(.password)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(Theme.mutedText)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Sign In")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Demo student: ahmed.mansoori@udst.edu.qa")
                    Text("Demo admin: admin@udst.edu.qa")
                    Text("Password: password123 (admin: admin123)")
                }
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
            }

            if let error = vm.errorMessage {
                Section { ErrorBanner(message: error) }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                Button {
                    Task { _ = await vm.login() }
                } label: {
                    HStack {
                        if vm.isLoading { ProgressView().tint(.white) }
                        Text("Sign In").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(vm.canSubmitLogin ? Theme.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canSubmitLogin)
                .listRowBackground(Color.clear)
            }

            Section {
                Button("Forgot Password?") {
                    Task {
                        await vm.sendPasswordReset()
                        vm.errorMessage = "Password reset link sent (mock)."
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.footnote)
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
}
