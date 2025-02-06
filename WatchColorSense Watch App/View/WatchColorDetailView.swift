//
//  ColorDetailView.swift
//  WatchColorSense Watch App
//
//  Created by Justin Wells on 7/31/23.
//

import SwiftUI

struct WatchColorDetailView: View {
    @ObservedObject private var viewModel: ViewModel
    
    var body: some View {
        GeometryReader { geo in
            NavigationStack {
                List {
                    HStack {
                        Spacer()
                        Circle()
                            .foregroundColor(viewModel.color)
                            .frame(width: geo.size.width / 2, height: geo.size.width / 2)
                        Spacer()
                    }
                    
                    Text("\(UIColor(viewModel.color).exactName)")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    Text("\(UIColor(viewModel.color).simpleName) Family")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 25)
                    Section(header: Text("Color Details").font(.title2)) {
                        VStack(alignment: .leading) {
                            detailText(title: "RGB", value: "R: \(viewModel.rbg.red) G: \(viewModel.rbg.green) B: \(viewModel.rbg.blue)")
                            detailText(title: "Hex", value: "\(viewModel.hex)")
                            detailText(title: "HSL", value: "Hue: \(viewModel.hsl.hue) Saturation: \(viewModel.hsl.saturation) Lightness: \(viewModel.hsl.lightness)")
                            detailText(title: "CMYK", value: "Cyan: \(viewModel.cmyk.cyan) Magenta: \(viewModel.cmyk.magenta) Yellow: \(viewModel.cmyk.yellow) Key: \(viewModel.cmyk.key)")
                        }
                    }
                    
                    Section(header: Text("Pantone").font(.title2)) {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(viewModel.pantone) { color in
                                    VStack(alignment: .center) {
                                        Text(color.name)
                                            .bold()
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
                                    //.padding(.horizontal, 2)
                                    .frame(width: 90, height: 90)
                                    .background (
                                        RoundedRectangle(cornerRadius: 12)
                                            .foregroundStyle(Color(hex: color.value))
                                    )
                                }
                            }
                        }
                    }
                    .isProFeature()
                    
                    Section(header: Text("Complimentary Colors").font(.title2)) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.complimentaryColors) { color in
                                    VStack(alignment: .center) {
                                        Text(UIColor(color).simpleName)
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
                                }
                            }
                        }
                    }
                    .isProFeature()
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        if viewModel.showAddToPalette {
                            HStack {
                                NavigationLink {
                                    WatchPaletteListView(colorToAdd: viewModel.hex)
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
            }
        }
    }
    
    init(color: Color, showAddToPalette: Bool = true) {
        _viewModel = ObservedObject(initialValue: ViewModel(color: color, showAddToPalette: showAddToPalette))
    }
    
    // Custom view for detail text
    func detailText(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
                .fontWeight(.bold)
                .frame(width: 80, alignment: .leading)
            Text(value)
        }
        .padding(.vertical, 4)
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

#Preview {
    WatchColorDetailView(color: Color.blue)
}
