//
//  ColorDetailView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct ColorDetailView: View {
    @EnvironmentObject private var camera: CameraModel
    @ObservedObject private var viewModel: ViewModel
    
    @AppStorage("showRgb") var showRgb = true
    @AppStorage("showHex") var showHex = true
    @AppStorage("showHsl") var showHsl = true
    @AppStorage("showCmyk") var showCmyk = true
    @AppStorage("showSwiftUI") var showSwiftUI = true
    @AppStorage("showUIKit") var showUIKit = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    colorCircleView()
                    colorNameView()
                    colorFamilyView()
                    colorDetailsGroupBox()
                    complimentaryColorsGroupBox()
                    accessibilityColorList()
                    pantoneGroupBox()
                }
            }
            .toolbar { toolbarContent() }
            .onAppear {
                camera.isPausingColorProcessing = true
            }
        }
    }
    
    init(color: Color, showAddToPalette: Bool = true) {
        _viewModel = ObservedObject(initialValue: ViewModel(color: color, showAddToPalette: showAddToPalette))
    }
    
    // MARK: - UI Components
    
    private func colorCircleView() -> some View {
        Circle()
            .foregroundColor(viewModel.color)
            .frame(width: UIScreen.main.bounds.width / 2.5, height: UIScreen.main.bounds.width / 2.5)
    }
    
    private func colorNameView() -> some View {
        Text("\(UIColor(viewModel.color).exactName)")
            .font(.title)
            .fontWeight(.bold)
            .padding(.top, 20)
            .padding(.horizontal, 40)
    }
    
    private func colorFamilyView() -> some View {
        Text("\(UIColor(viewModel.color).simpleName) Family")
            .font(.title2)
            .foregroundColor(.secondary)
            .padding([.bottom, .horizontal], 25)
    }
    
    private func colorDetailsGroupBox() -> some View {
        GroupBox(label: Text("Color Details").font(.title2)) {
            VStack(alignment: .leading) {
                if (showRgb) { detailText(title: "RGB", value: "R: \(viewModel.rgb.red) G: \(viewModel.rgb.green) B: \(viewModel.rgb.blue)") }
                if (showHex) { detailText(title: "Hex", value: "\(viewModel.hex)") }
                if (showHsl) { detailText(title: "HSL", value: "Hue: \(viewModel.hsl.hue) Saturation: \(viewModel.hsl.saturation) Lightness: \(viewModel.hsl.lightness)") }
                if (showCmyk) { detailText(title: "CMYK", value: "Cyan: \(viewModel.cmyk.cyan) Magenta: \(viewModel.cmyk.magenta) Yellow: \(viewModel.cmyk.yellow) Key: \(viewModel.cmyk.key)") }
                Divider()
                if (showSwiftUI) { detailText(title: "SwiftUI", value: viewModel.swiftUI) }
                if (showUIKit) { detailText(title: "UIKit", value: viewModel.uiKit) }
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: 700)
    }
    
    private func pantoneGroupBox() -> some View {
        ZStack {
            
            GroupBox(label: Text("Pantone").font(.title2)) {
                HStack {
                    ForEach(viewModel.pantone) { color in
                        VStack(alignment: .center) {
                            Text(color.name)
                                .foregroundStyle(Color(hex: color.value).isDark() ? .white : .black)
                            Spacer()
                            Text(color.value)
                                .font(.footnote)
                                .background(
                                    Capsule()
                                        .foregroundStyle(.ultraThinMaterial)
                                        .padding(-3)
                                )
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 2)
                        .frame(width: 90, height: 90)
                        .background (
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundStyle(Color(hex: color.value))
                        )
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = color.value
                            } label: {
                                Text("Copy to clipboard")
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }
                }
                .isProFeature()
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: 700)
    }
    
    private func complimentaryColorsGroupBox() -> some View {
        ZStack {
            
            GroupBox(label: Text("Pair With Colors").font(.title2)) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.complimentaryColors) { color in
                            VStack(alignment: .center) {
                                Text(UIColor(color).simpleName)
                                    .foregroundStyle(color.isDark() ? .white : .black)
                                Spacer()
                                Text(color.toHex())
                                    .font(.footnote)
                                    .background(
                                        Capsule()
                                            .foregroundStyle(.ultraThinMaterial)
                                            .padding(-3)
                                    )
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 2)
                            .frame(width: 90, height: 90)
                            .background (
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(color)
                            )
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = color.toHex()
                                } label: {
                                    Text("Copy to clipboard")
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                        }
                    }
                }
                .isProFeature()
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: 700)
    }
    
    private func accessibilityColorList() -> some View {
        ZStack {
            
            GroupBox(label: Text("Accessibility View").font(.title2)) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.colorVisionsSimulations) { color in
                            VStack(alignment: .center) {
                                Text(color.type)
                                    .foregroundStyle(color.color.isDark() ? .white : .black)
                                Spacer()
                                Text(color.color.toHex())
                                    .font(.footnote)
                                    .background(
                                        Capsule()
                                            .foregroundStyle(.ultraThinMaterial)
                                            .padding(-3)
                                    )
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 2)
                            .frame(width: 90, height: 90)
                            .background (
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(color.color)
                            )
                        }
                    }
                }
                .isProFeature()
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: 700)
    }
    
    private func detailText(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
                .fontWeight(.bold)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = value
            } label: {
                Text("Copy to clipboard")
                Image(systemName: "doc.on.doc")
            }
        }
    }
    
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if viewModel.showAddToPalette {
                Menu {
                    NavigationLink {
                        PaletteListView(colorToAdd: viewModel.hex)
                    } label: {
                        HStack {
                            Text("Add color to palette")
                            Spacer()
                            Image(systemName: "plus")
                        }
                    }
                    
                    ShareColor(color: viewModel.color, labelStyle: .withText)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            } else {
                ShareColor(color: viewModel.color)
            }
        }
    }
}

struct ColorDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ColorDetailView(color: Color.init(hex: "2A2A1A"))
            .environmentObject(PreviewCameraModel())
            .environmentObject(EntitlementManager())
    }
}
