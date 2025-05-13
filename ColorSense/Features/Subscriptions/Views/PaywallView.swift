//
//  PaywallView.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    // Environment objects
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // State variables
    @State private var selectedPlan: Plan = .weekly
    @State private var showError = false
    @State private var currentPage = 0
    @State private var isAppearing = false
    @State private var shouldAnimateCards = true
    @State private var isShowingCloseButton = false
    @State private var progress: CGFloat = 0.0

    private let allowCloseAfter: CGFloat = 5.0

    enum Plan {
        case weekly
        case yearly

        var title: String {
            switch self {
            case .weekly: return "Weekly"
            case .yearly: return "Yearly"
            }
        }

        var productId: String {
            switch self {
            case .weekly: return "colorsenseproplanweekly"
            case .yearly: return "colorsenseproplanannual"
            }
        }
    }

    // Pro features with their icons and descriptions
    private let features: [(icon: String, title: String, description: String)] = [
        ("swatchpalette.fill", "Pro Color Palettes", "Create unlimited palettes with advanced harmony generation from any color"),
        ("eye.fill", "Color Vision Tools", "View and adapt colors for every type of color vision deficiency"),
        ("sparkles", "Pantone Color Matching", "Match to professional color libraries used in design and printing"),
        ("wand.and.stars", "Theme-Based Palettes", "Generate specialized palettes for pastel, vibrant, earth tones and more"),
        ("chart.bar.fill", "Advanced Analysis", "Get precise color harmony scores and comprehensive color data"),
        ("icloud.fill", "Cross-Device Sync", "Access your colors and palettes on all your Apple devices")
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // Header with colorful graphic
                        headerSection
                            .padding(.bottom, 15)

                        // Feature cards carousel
                        featureCarousel(width: geometry.size.width)
                            .padding(.bottom, 15)

                        // Plan selection
                        planToggleSection
                            .padding(.horizontal)
                            .padding(.bottom, 15)

                        // Price display
                        currentPriceView
                            .padding(.bottom, 15)

                        // Call to action button
                        Button {
                            let product = subscriptionsManager.products.first(where: { $0.id == selectedPlan.productId })

                            if let product = product {
                                Task {
                                    await subscriptionsManager.buyProduct(product)
                                }
                            } else {
                                showError = true
                            }
                        } label: {
                            purchaseButtonLabel
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 25)
                        .padding(.bottom, 15)

                        // Restore purchases option
                        Button {
                            Task {
                                await subscriptionsManager.restorePurchases()
                            }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.vertical, 8)
                        }
                        .padding(.bottom, 10)
                        .opacity(isAppearing ? 1 : 0)
                        .animation(.easeOut.delay(0.8), value: isAppearing)

                        // Fine print and links
                        termsAndPrivacyLinks
                            .padding(.bottom, 30)
                    }
                }

                closeButton
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Unable to process your purchase at this time. Please try again later.")
            }
            .alert("Thank You!", isPresented: $subscriptionsManager.showThankYouAlert) {
                Button("Continue", role: .cancel) { dismiss() }
            } message: {
                Text("Thank you for subscribing to ColorSense Pro!")
            }
            .overlay {
                if subscriptionsManager.isLoading {
                    loadingView
                }
            }
        }
        .onAppear {
            // Start animations with a slight delay for a smoother entry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: allowCloseAfter)) {
                    self.progress = 1.0
                }

                withAnimation(.easeOut(duration: 0.6)) {
                    isAppearing = true
                }

                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                    shouldAnimateCards = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + allowCloseAfter) {
                    withAnimation {
                        self.isShowingCloseButton = true
                    }
                }
            }

            Task {
                await subscriptionsManager.loadProducts()
            }
        }
    }

    // Purchase button label
    private var purchaseButtonLabel: some View {
        Text(getButtonLabelText())
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
            .opacity(isAppearing ? 1 : 0)
            .offset(y: isAppearing ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: isAppearing)
    }

    // Get button text based on selected plan
    private func getButtonLabelText() -> String {
        if let product = subscriptionsManager.products.first(where: { $0.id == selectedPlan.productId }),
           let introOffer = product.subscription?.introductoryOffer,
           introOffer.paymentMode == .freeTrial {
            return "Try for Free"
        }
        return "Subscribe Now"
    }

    // MARK: - UI Components



    // Helper to get correct button text
    private func getSubscribeButtonText() -> String {
        let product = subscriptionsManager.products.first(where: { $0.id == selectedPlan.productId })

        if let product = product,
           let introOffer = product.subscription?.introductoryOffer,
           introOffer.paymentMode == .freeTrial {
            return "Start Free Trial"
        }
        return "Subscribe Now"
    }

    // Background gradient with animated stars
    private var backgroundGradient: some View {
        ZStack {
            // Enhanced animated gradient background using TimelineView for smooth animation
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let angle = Angle(radians: now.truncatingRemainder(dividingBy: 10) / 10 * 2 * .pi)
                let angle2 = Angle(radians: now.truncatingRemainder(dividingBy: 15) / 15 * 2 * .pi)

                ZStack {
                    // First gradient layer
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.098, green: 0.098, blue: 0.439),  // Midnight Blue
                            Color(red: 0.294, green: 0.0, blue: 0.51),     // Indigo
                            Color(red: 0.502, green: 0.0, blue: 0.502),    // Purple
                            Color(red: 0.294, green: 0.0, blue: 0.51),     // Indigo
                            Color(red: 0.098, green: 0.098, blue: 0.439),  // Midnight Blue
                        ]),
                        center: .center,
                        angle: angle
                    )
                    .blur(radius: 30)

                    // Second gradient layer with different rotation speed
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.5),   // Purple tint
                            Color.clear
                        ]),
                        center: UnitPoint(
                            x: 0.5 + 0.5 * cos(angle2.radians),
                            y: 0.5 + 0.5 * sin(angle2.radians)
                        ),
                        startRadius: 5,
                        endRadius: UIScreen.main.bounds.width * 0.6
                    )

                    // Overlay with subtle noise texture
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .blendMode(.overlay)
                }
            }
            .opacity(0.9)

            // "stars" effect with subtle pulsing animation
            ZStack {
                ForEach(0..<60) { i in
                    TimelineView(.animation(minimumInterval: 0.1, paused: false)) { timeline in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        let baseSize = [1.75, 2.25, 2.75][i % 3]
                        let pulse = sin(now * 0.5 + Double(i)) * 0.3 + 0.7 // Subtle pulsing effect
                        let size = baseSize * pulse

                        let baseOpacity = [0.4, 0.5, 0.6][i % 3]
                        let opacityPulse = sin(now * 0.3 + Double(i)) * 0.2 + 0.9
                        let opacity = baseOpacity * opacityPulse

                        let xPosition = CGFloat(i * 17 + 10) * 1.8
                        let yPosition = CGFloat(i * 23 + 5) * 1.8

                        // Using truncatingRemainder for position calculation
                        let adjustedX = xPosition.truncatingRemainder(dividingBy: UIScreen.main.bounds.width)
                        let adjustedY = yPosition.truncatingRemainder(dividingBy: UIScreen.main.bounds.height)

                        Circle()
                            .fill(Color.white.opacity(opacity))
                            .frame(width: size, height: size)
                            .blur(radius: 0.3)
                            .position(
                                x: adjustedX,
                                y: adjustedY
                            )
                    }
                }
            }
        }
    }

    // Close button in top right
    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                
                if isShowingCloseButton {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding()
                } else {
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .opacity(0.1 + 0.1 * progress)
                        .rotationEffect(Angle(degrees: -90))
                        .frame(width: 24, height: 24)
                        .padding()
                }
            }
            Spacer()
        }
    }

    // Header section with app icon and title
    private var headerSection: some View {
        VStack(spacing: 15) {
            // App icon with glowing effect
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 100, height: 100)
                    .opacity(isAppearing ? 1 : 0)
                    .scaleEffect(isAppearing ? 1 : 0.7)
                    .animation(.easeOut(duration: 1.2).delay(0.3), value: isAppearing)

                // Icon container
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.1, blue: 0.6),
                                Color(red: 0.2, green: 0.05, blue: 0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: Color(red: 0.3, green: 0.1, blue: 0.5).opacity(0.5), radius: 15, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .scaleEffect(isAppearing ? 1 : 0.7)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: isAppearing)

                // Icon
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 50, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.white.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(isAppearing ? 1 : 0.5)
                    .opacity(isAppearing ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: isAppearing)
            }
            .padding(.top, 20)

            Text("Upgrade to ColorSense Pro")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(isAppearing ? 1 : 0)
                .offset(y: isAppearing ? 0 : 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: isAppearing)

            Text("Unlock the full spectrum of professional features")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .opacity(isAppearing ? 1 : 0)
                .offset(y: isAppearing ? 0 : 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: isAppearing)
        }
    }

    // MARK: - Feature Carousel

    private func featureCarousel(width: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 0) {
            // Feature cards with paging
            TabView(selection: $currentPage) {
                ForEach(0..<features.count, id: \.self) { index in
                    featureCard(
                        icon: features[index].icon,
                        title: features[index].title,
                        description: features[index].description,
                        index: index
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 230)

            // Custom page indicator
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentPage == index ? 1.2 : 1.0)
                        .animation(.spring(), value: currentPage)
                }
            }
            .padding(.top, 8)
        }
    }

    private func featureCard(icon: String, title: String, description: String, index: Int) -> some View {
        VStack(spacing: 20) {
            // Icon with glow effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.2, blue: 0.6),
                                Color(red: 0.2, green: 0.1, blue: 0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.5), radius: 8, x: 0, y: 0)

                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(shouldAnimateCards ? 1.0 : 0.8)
            .opacity(shouldAnimateCards ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.05 * Double(index)), value: shouldAnimateCards)

            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .opacity(shouldAnimateCards ? 1.0 : 0.0)
                .offset(y: shouldAnimateCards ? 0 : 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1 + 0.05 * Double(index)), value: shouldAnimateCards)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(shouldAnimateCards ? 1.0 : 0.0)
                .offset(y: shouldAnimateCards ? 0 : 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15 + 0.05 * Double(index)), value: shouldAnimateCards)
        }
        .frame(width: UIScreen.main.bounds.width - 60)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.clear)
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 24)
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
        )
    }

    // MARK: - Plan Toggle Section

    private var planToggleSection: some View {
        VStack(spacing: 5) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 0) {
                ForEach([Plan.weekly, .yearly], id: \.self) { plan in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                    }) {
                        VStack(spacing: 2) {
                            Text(plan.title)
                                .fontWeight(.medium)
                                .frame(height: 22)

                            if selectedPlan == plan &&
                                selectedPlan == .yearly {
                                Text("Best Value")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.yellow)
                                    .cornerRadius(4)
                                    .opacity(selectedPlan == .yearly ? 1 : 0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPlan == plan ?
                                      Color.white.opacity(0.9) :
                                        Color.clear)
                        )
                        .foregroundColor(selectedPlan == plan ? .black : .white)
                    }
                }
            }
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPlan)
        }
    }

    // MARK: - Price View

    private var currentPriceView: some View {
        Group {
            realPriceView
        }
    }

    private var realPriceView: some View {
        let weeklyProduct = subscriptionsManager.products.first { $0.id == Plan.weekly.productId }
        let yearlyProduct = subscriptionsManager.products.first { $0.id == Plan.yearly.productId }

        let product = selectedPlan == .weekly ? weeklyProduct : yearlyProduct

        return Group {
            if let product = product {
                priceView(for: product, weeklyProduct: weeklyProduct, yearlyProduct: yearlyProduct)
            } else {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                    .frame(height: 80)
            }
        }
    }

    private func priceView(for product: Product, weeklyProduct: Product?, yearlyProduct: Product?) -> some View {
        VStack(spacing: 5) {
            // Main price display
            if selectedPlan == .yearly {
                // Show yearly price with weekly breakdown
                yearlyPriceDisplay(product: product, yearlyProduct: yearlyProduct)
            } else {
                // Weekly price
                weeklyPriceDisplay(product: product)
            }

            // Additional price information section
            additionalPriceInfo(product: product, weeklyProduct: weeklyProduct, yearlyProduct: yearlyProduct)

            // Limited time offer badge
            limitedTimeOfferBadge
                .padding(.top, 5)
        }
    }

    private func yearlyPriceDisplay(product: Product, yearlyProduct: Product?) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(product.displayPrice)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)

                Text("/year")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 2)
            }

            // Weekly equivalent price
            if let yearlyProduct = yearlyProduct {
                let yearlyPriceValue = (yearlyProduct.price as NSDecimalNumber).doubleValue
                let weeklyEquivalent = yearlyPriceValue / 52

                Text("Just $\(String(format: "%.2f", weeklyEquivalent))/week billed annually")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    private func weeklyPriceDisplay(product: Product) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(product.displayPrice)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)

            Text("/week")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 2)
        }
    }

    private func additionalPriceInfo(product: Product, weeklyProduct: Product?, yearlyProduct: Product?) -> some View {
        Group {
            if selectedPlan == .yearly, let yearlyProduct = yearlyProduct, let weeklyProduct = weeklyProduct {
                yearlyDiscountView(yearlyProduct: yearlyProduct, weeklyProduct: weeklyProduct)
            }

            if let introOffer = product.subscription?.introductoryOffer,
               introOffer.paymentMode == .freeTrial {
                freeTrialBadge(for: introOffer)
            }
        }
    }

    private func yearlyDiscountView(yearlyProduct: Product, weeklyProduct: Product) -> some View {
        let yearlyPrice = (yearlyProduct.price as NSDecimalNumber).doubleValue
        let weeklyPrice = (weeklyProduct.price as NSDecimalNumber).doubleValue

        // Calculate annual cost of weekly subscription
        let annualCostOfWeekly = weeklyPrice * 52

        // Calculate savings percentage
        let savings = (annualCostOfWeekly - yearlyPrice) / annualCostOfWeekly
        let discountPercentage = Int(savings * 100)

        return HStack(spacing: 4) {
            Text("Save \(discountPercentage)%")
                .fontWeight(.semibold)

            Text("compared to weekly")
                .fontWeight(.regular)
        }
        .font(.subheadline)
        .foregroundColor(.yellow)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.2))
        )
    }

    private func freeTrialBadge(for offer: Product.SubscriptionOffer) -> some View {
        Text("\(formatSubscriptionPeriod(offer.period)) FREE")
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.green)
            )
    }

    private var limitedTimeOfferBadge: some View {
        Text("Limited Time Offer")
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
    }

    private func formatSubscriptionPeriod(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: return period.value == 1 ? "1 DAY" : "\(period.value) DAYS"
        case .week: return period.value == 1 ? "1 WEEK" : "\(period.value) WEEKS"
        case .month: return period.value == 1 ? "1 MONTH" : "\(period.value) MONTHS"
        case .year: return period.value == 1 ? "1 YEAR" : "\(period.value) YEARS"
        @unknown default: return "\(period.value) \(period.unit)"
        }
    }

    // MARK: - Action Buttons

    // Custom button style for purchase button
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }

    private var purchaseButton: some View {
        let product = subscriptionsManager.products.first(where: { $0.id == selectedPlan.productId })

        return Button {
            Task {
                if let product = product {
                    // Use a single method call that your SubscriptionsManager actually implements
                    await subscriptionsManager.buyProduct(product)
                    //subscriptionsManager.buy(product)
                } else {
                    showError = true
                }
            }
        } label: {
            Text(getButtonText(for: product))
                .fontWeight(.bold)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    // Use a more appealing gradient
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
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: isAppearing)
    }

    private func getButtonText(for product: Product?) -> String {
        if let product = product, let introOffer = product.subscription?.introductoryOffer {
            if introOffer.paymentMode == .freeTrial {
                return "Start Free Trial"
            }
        }
        return "Subscribe Now"
    }

    private func purchaseAction(product: Product?) {
        guard let product = product else {
            showError = true
            return
        }

        Task {
            await subscriptionsManager.buyProduct(product)
        }
    }

    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionsManager.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .padding(.vertical, 8)
        }
        .opacity(isAppearing ? 1 : 0)
        .animation(.easeOut.delay(0.8), value: isAppearing)
    }

    // MARK: - Terms and Privacy

    private var termsAndPrivacyLinks: some View {
        HStack(spacing: 25) {
            Button {
                // Open Terms of Service
                if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Terms of Service")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    .underline()
            }

            Button {
                // Open Privacy Policy
                if let url = URL(string: "https://justinwells.dev/colorsense/privacy-policy.html") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Privacy Policy")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    .underline()
            }
        }
        .opacity(isAppearing ? 1 : 0)
        .animation(.easeOut.delay(0.9), value: isAppearing)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 15) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)

                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
}
