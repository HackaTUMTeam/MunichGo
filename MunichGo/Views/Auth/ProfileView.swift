//
//  ProfileVIew.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.name ?? "Benutzer")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    NavigationLink {
                        Text("Einstellungen")
                    } label: {
                        Label("Einstellungen", systemImage: "gear")
                    }
                    
                    NavigationLink {
                        Text("Benachrichtigungen")
                    } label: {
                        Label("Benachrichtigungen", systemImage: "bell")
                    }
                }
                
                Section("Über") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    NavigationLink {
                        Text("Datenschutz")
                    } label: {
                        Label("Datenschutz", systemImage: "hand.raised")
                    }
                    
                    NavigationLink {
                        Text("Nutzungsbedingungen")
                    } label: {
                        Label("Nutzungsbedingungen", systemImage: "doc.text")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        authViewModel.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Abmelden", systemImage: "arrow.right.square")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profil")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
