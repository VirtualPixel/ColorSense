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
        NavigationStack {
            ScrollView {
                VStack {
                    Circle()
                        .foregroundColor(viewModel.color)
                        .frame(width: 150, height: 150)
                        .padding(.top, 50)
                    
                    Text("\(UIColor(viewModel.color).exactName)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("\(UIColor(viewModel.color).simpleName) Family")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    GroupBox(label: Text("Color Details").font(.title2)) {
                        VStack(alignment: .leading) {
                            detailText(title: "RGB", value: "R: \(viewModel.rbg.red) G: \(viewModel.rbg.green) B: \(viewModel.rbg.blue)")
                            detailText(title: "Hex", value: "\(viewModel.hex)")
                            detailText(title: "HSL", value: "Hue: \(viewModel.hsl.hue) Saturation: \(viewModel.hsl.saturation) Lightness: \(viewModel.hsl.lightness)")
                            detailText(title: "CMYK", value: "Cyan: \(viewModel.cmyk.cyan) Magenta: \(viewModel.cmyk.magenta) Yellow: \(viewModel.cmyk.yellow) Key: \(viewModel.cmyk.key)")
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 600)
                    
                    GroupBox(label: Text("Pantone").font(.title2)) {
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
                                .padding(.horizontal, 2)
                                .frame(width: 110, height: 110)
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
                    }
                    .padding()
                    .frame(maxWidth: 600)
                }
            }
            .onAppear {
                cameraFeed.stop()
            }
            .onDisappear {
                cameraFeed.start()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        NavigationLink {
                            PalletListView(colorToAdd: viewModel.hex)
                        } label: {
                            HStack {
                                Text("Add color to pallet")
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
                }
            }
        }
    }
    
    init(color: Color) {
        _viewModel = ObservedObject(initialValue: ViewModel(color: color))
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
        .contextMenu {
            Button {
                UIPasteboard.general.string = value
            } label: {
                Text("Copy to clipboard")
                Image(systemName: "doc.on.doc")
            }
        }
    }
    
    private func createImage(color: UIColor, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
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
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        ColorDetailView(color: Color.init(hex: "000000"))
            .environmentObject(cameraFeed)
    }
}
