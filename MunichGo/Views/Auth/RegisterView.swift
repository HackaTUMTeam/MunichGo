//
//  RegisterView.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && passwordsMatch
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Neuen Account erstellen")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Fülle die Felder aus, um loszulegen")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                    
                    // Registration Form
                    VStack(spacing: 16) {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        
                        TextField("E-Mail", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        
                        SecureField("Passwort", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        
                        SecureField("Passwort bestätigen", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        
                        if !password.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwörter stimmen nicht überein")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button {
                            Task {
                                await authViewModel.register(email: email, password: password, name: name)
                                if authViewModel.isAuthenticated {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Registrieren")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.accentColor : Color.gray)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!isFormValid || authViewModel.isLoading)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}

