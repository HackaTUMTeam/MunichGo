//
//  LoginView.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "move.3d")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("MunichGO")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Willkommen zurück")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 32)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("E-Mail", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    SecureField("Passwort", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button {
                        Task {
                            await authViewModel.login(email: email, password: password)
                        }
                    } label: {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Anmelden")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                }
                
                Spacer()
                
                // Register Link
                HStack {
                    Text("Noch kein Account?")
                        .foregroundStyle(.secondary)
                    
                    Button {
                        showingRegister = true
                    } label: {
                        Text("Registrieren")
                            .fontWeight(.semibold)
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 24)
            .sheet(isPresented: $showingRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

