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
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: 200)
            .padding(.vertical, 12)
            .background(fill)
            .overlay(
                Capsule()
                    .stroke(stroke, lineWidth: 2)
            )
            .cornerRadius(100)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

