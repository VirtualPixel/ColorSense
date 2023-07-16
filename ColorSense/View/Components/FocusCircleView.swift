//
//  FocusCircleView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct FocusCircleView: View {
    @EnvironmentObject private var cameraFeed: CameraFeed
    @Binding var showingSizeSlider: Bool
    @Binding var lastInteractionTime: Date
    
    var body: some View {
        ZStack {
            if showingSizeSlider {
                createOverlayToDismissSlider()
            }
            
            VStack {
                createFocusButton()
                createSizeSlider()
            }
        }
    }
    
    private func createOverlayToDismissSlider() -> some View {
        Color.black
            .ignoresSafeArea()
            .opacity(0.00001)
            .onTapGesture {
                withAnimation {
                    showingSizeSlider = false
                }
            }
    }
    
    private func createFocusButton() -> some View {
        Button(action: toggleSliderVisibility) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: 50, height: 50)
                    .opacity(0.0000001)
                
                Circle()
                    .strokeBorder(.white, lineWidth: (cameraFeed.region > 20 ? 3 : cameraFeed.region * 0.15))
                    .frame(width: cameraFeed.region, height: cameraFeed.region)
            }
        }
    }
    
    private func toggleSliderVisibility() {
        withAnimation {
            showingSizeSlider.toggle()
            sliderValueChanged(nil)
        }
    }
    
    private func sliderValueChanged(_ value: CGFloat?) {
        lastInteractionTime = Date()
        autoHideSlider()
    }
    
    private func createSizeSlider() -> some View {
        if showingSizeSlider {
            return Slider(value: $cameraFeed.region, in: 5...300)
                .padding([.horizontal, .bottom])
                .onChange(of: cameraFeed.region) {
                    sliderValueChanged(nil)
                }
                .eraseToAnyView()
        } else {
            return EmptyView().eraseToAnyView()
        }
    }
    
    private func autoHideSlider() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if showingSizeSlider && Date().timeIntervalSince(lastInteractionTime) > 5 {
                withAnimation {
                    showingSizeSlider = false
                }
            }
        }
    }
}

struct FocusCircleView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        FocusCircleView(showingSizeSlider: .constant(false), lastInteractionTime: .constant(Date()))
            .environmentObject(cameraFeed)
    }
}
