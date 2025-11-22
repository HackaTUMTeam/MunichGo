//
//  ExploreView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI

struct ExploreView: View {
    
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        let model = SwipeableCardsView.Model(cards: (auth.events ?? []).map({event in
            return CardView.Model(event: event)
        }))
        VStack {
                
                
                Text("Today's Highlights")
                .font(Font.largeTitle.bold())
                
                SwipeableCardsView(model: model) { model in
                    print(model.swipedCards)
                    model.reset()
                }
            }
            .padding()
            .task {
                await auth.getEvents()
            }
                
    }
}

#Preview {
    ExploreView()
        .environmentObject(AuthViewModel())
}
