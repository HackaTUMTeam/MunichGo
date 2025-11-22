//
//  AccountView.swift
//  MunichGo
//
//  Created by Bent Schuetz on 22/11/25.
//
import SwiftUI
struct AccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body : some View {
        VStack(spacing: 16) {
                    Button("Check Health") {
                        Task {
                            await authViewModel.getEvents()
                        }
                    }
                    
                    if let text = authViewModel.events {
                        List(text){
                            Text($0.title)
                        }
                    }
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                .padding()
    }
}

#Preview {
    AccountView()
        .environmentObject(AuthViewModel())
}
