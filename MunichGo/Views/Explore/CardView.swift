//
//  CardView.swift
//  MunichGo
//
//  Created by Bent Schuetz on 22/11/25.
//
import SwiftUI
import Foundation

struct CardView: View {
    enum SwipeDirection {
        case left, right, none
    }

    struct Model: Identifiable, Equatable {
        static func == (lhs: CardView.Model, rhs: CardView.Model) -> Bool {
            return lhs.event.id == rhs.event.id
        }
        
        let id = UUID()
        let event: Event
        var swipeDirection: SwipeDirection = .none
    }

    var model: Model
    var size: CGSize
    var dragOffset: CGSize
    var isTopCard: Bool
    var isSecondCard: Bool

    let dateFormatter = Date.FormatStyle(date: .omitted, time: .shortened)
    
    var body: some View {
        
            VStack{
                AsyncImage(url: model.event.imageReference){ image in
                    image.image?.resizable()
                }
                .frame(height: size.height * 0.5)
                    
                Text(model.event.title!)
                    .foregroundColor(.primary)
                    .font(.largeTitle)
                    .padding()
                VStack(alignment: .leading){
                    Text("Time: \(model.event.startDate.formatted(dateFormatter))")
                    Text("Venue: \(model.event.venue ?? "Unknown")")
                    Button(action: {}){
                        Label("Visit Site", systemImage: "link")
                    }
                        
                }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 0))
            
                
            }
            .frame(width: size.width * 0.95, height: size.height * 0.9, alignment: .top)
            .background()
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 2))
            .shadow(color: isTopCard ? getShadowColor() : (isSecondCard && dragOffset.width != 0 ? Color.gray.opacity(0.2) : Color.clear), radius: 10, x: 0, y: 3)
        
    
    }
    
    private func getShadowColor() -> Color {
        if dragOffset.width > 0 {
            return Color.green.opacity(0.5)
        } else if dragOffset.width < 0 {
            return Color.red.opacity(0.5)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

#Preview {
    ExploreView()
}
