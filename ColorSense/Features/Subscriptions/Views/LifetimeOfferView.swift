//
//  LifetimeOfferView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/15/25.
//

import SwiftUI
import StoreKit

struct LifetimeOfferView: View {
    let product: Product
    var onPurchase: (Product) -> Void
    @State private var isAppearing = false

    var body: some View {
        VStack(spacing: 14) {
            // Special offer badge
            HStack {
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))

                Text("GLOBAL ACCESSIBILITY AWARENESS MONTH")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)

                Spacer()
            }

            // Explanation text
            Text("In honor of Global Accessibility Awareness Month, we're offering ColorSense Pro lifetime access completely free until the end of May.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 5)

            // Action button
            Button {
                onPurchase(product)
            } label: {
                Text("Get Free Lifetime Access")
                    .fontWeight(.bold)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.4), // Brighter yellow
                                Color(red: 1.0, green: 0.6, blue: 0.3)   // Softer orange
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.5), radius: 15, x: 0, y: 8)
            }
            .buttonStyle(ScaleButtonStyle())

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.top, 6)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 10)
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
                isAppearing = true
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
