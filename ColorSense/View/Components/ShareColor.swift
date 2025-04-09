//
//  ShareColor.swift
//  ColorSense
//
//  Created by Justin Wells on 4/9/25.
//

import SwiftUI

enum ShareColorLabelStyle {
    case withText, withoutText
}

struct ShareColor<LabelContent: View>: View {
    let color: Color
    let labelContent: LabelContent

    var body: some View {
        ShareLink(item: color.toImage(),
                  subject: Text("A wild color has appeared!"),
                  message: Text("\(color.uiColor.exactName)\nCheck out this color in ColorSense:\nColorSense://color?colorHex=\(color.toHex().replacingOccurrences(of: "#", with: ""))"),
                  preview: SharePreview("Shared from ColorSense",
                                        image: color.toImage())) {
            labelContent
        }
    }

    init(color: Color, @ViewBuilder label: () -> LabelContent) {
        self.color = color
        self.labelContent = label()
    }
}

extension ShareColor where LabelContent == AnyView {
    init(color: Color,
         labelStyle: ShareColorLabelStyle = .withoutText) {

        self.color = color

        switch labelStyle {
        case .withText:
            self.labelContent = AnyView(
                HStack {
                    Text("Share Color")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
            )
        case .withoutText:
            self.labelContent = AnyView(
                Image(systemName: "square.and.arrow.up")
            )
        }
    }
}

#Preview {
    ShareColor(color: .purple)
}
