//
//  CapsuleButtonStyle.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-03.
//

import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    var fill: Color       // background fill color
    var stroke: Color     // border color
    var lineWidth: CGFloat = 2//lineWidth
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(fill)
            .overlay(
                Capsule()
                    .stroke(stroke, lineWidth: lineWidth)
            )
            .cornerRadius(100)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

