import SwiftUI

struct TestAuthView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Credentials") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                Section {
                    Button(action: {
                        viewModel.signIn(email: email, password: password)
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Sign In")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                
                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                if viewModel.isAuthenticated {
                    Section("User Info") {
                        if let user = viewModel.user {
                            LabeledContent("ID", value: user.id)
                            LabeledContent("Email", value: user.email)
                        }
                        
                        Button("Sign Out", role: .destructive) {
                            viewModel.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Test Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        if viewModel.isAuthenticated {
                            dismiss()
                        } else {
                            // Only dismiss if they successfully logged in or explicitly cancel
                            // This encourages them to complete the login flow
                            let alert = UIAlertController(
                                title: "Close without signing in?",
                                message: "You need to sign in to view and manage your mind maps.",
                                preferredStyle: .alert
                            )
                            
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                            alert.addAction(UIAlertAction(title: "Close", style: .destructive) { _ in
                                dismiss()
                            })
                            
                            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    TestAuthView()
        .environmentObject(AuthViewModel())
} 