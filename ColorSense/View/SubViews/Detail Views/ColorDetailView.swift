//
//  ColorDetailView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct ColorDetailView: View {
    @EnvironmentObject private var cameraFeed: CameraFeed
    @ObservedObject private var viewModel: ViewModel
    
    var body: some View {
        GeometryReader { geo in
            NavigationStack {
                ScrollView {
                    VStack {
                        colorCircleView(geometry: geo)
                        colorNameView()
                        colorFamilyView()
                        colorDetailsGroupBox()
                        pantoneGroupBox()
                        complimentaryColorsGroupBox()
                    }
                }
                .toolbar { toolbarContent() }
                .onAppear {
                    cameraFeed.stop()
                }
                .onDisappear {
                    cameraFeed.start()
                }
            }
        }
    }
    
    init(color: Color, showAddToPalette: Bool = true) {
        _viewModel = ObservedObject(initialValue: ViewModel(color: color, showAddToPalette: showAddToPalette))
    }
    
    // MARK: - UI Components
    
    private func colorCircleView(geometry: GeometryProxy) -> some View {
        Circle()
            .foregroundColor(viewModel.color)
            .frame(width: geometry.size.width / 2, height: geometry.size.width / 2)
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
                detailText(title: "RGB", value: "R: \(viewModel.rgb.red) G: \(viewModel.rgb.green) B: \(viewModel.rgb.blue)")
                detailText(title: "Hex", value: "\(viewModel.hex)")
                detailText(title: "HSL", value: "Hue: \(viewModel.hsl.hue) Saturation: \(viewModel.hsl.saturation) Lightness: \(viewModel.hsl.lightness)")
                detailText(title: "CMYK", value: "Cyan: \(viewModel.cmyk.cyan) Magenta: \(viewModel.cmyk.magenta) Yellow: \(viewModel.cmyk.yellow) Key: \(viewModel.cmyk.key)")
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
            }
            .isProFeature()
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
                    
                    ShareLink(item: Image(uiImage: createImage(color: UIColor(viewModel.color))),
                              subject: Text("Interesting color"),
                              message: Text("\(UIColor(viewModel.color).exactName)\nCheck out this color in ColorSense:\nColorSense://color?colorHex=\(viewModel.hex.replacingOccurrences(of: "#", with: ""))"),
                              preview: SharePreview("Shared from ColorSense",
                                                    image: Image(uiImage: createImage(color: UIColor(viewModel.color))))) {
                        HStack {
                            Text("Share Color")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            } else {
                ShareLink(item: Image(uiImage: createImage(color: UIColor(viewModel.color))),
                          subject: Text("Interesting color"),
                          message: Text("\(UIColor(viewModel.color).exactName)\nCheck out this color in ColorSense:\nColorSense://color?colorHex=\(viewModel.hex.replacingOccurrences(of: "#", with: ""))"),
                          preview: SharePreview("Shared from ColorSense",
                                                image: Image(uiImage: createImage(color: UIColor(viewModel.color))))) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            
        }
    }
    
    private func createImage(color: UIColor, size: CGSize = CGSize(width: 256, height: 256)) -> UIImage {
        let rect = CGRect(origin: CGPoint(), size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}

struct ColorDetailView_Previews: PreviewProvider {
    static let entitlementsManager = EntitlementManager()
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        ColorDetailView(color: Color.init(hex: "2A2A1A"))
            .environmentObject(cameraFeed)
            .environmentObject(entitlementsManager)
    }
}
