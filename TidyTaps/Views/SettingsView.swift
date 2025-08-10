//
//  SettingsView.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-10.
//

import SwiftUI

private struct OrderRow: View {
    let order: ActionButtonOrder
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 24) {
            ForEach(order.kinds, id: \.self) { kind in
                icon(for: kind)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color("AccentLight")))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? Color("Yellow") : Color("AccentDark"),
                        lineWidth: isSelected ? 6 : 2)
        )
        .overlay(alignment: .bottom) {
            if isSelected {
                Text("Selected")
                    .font(.custom("Poppins-Semibold", size: 12))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color("Yellow")))
                    .overlay(Capsule().stroke(Color("AccentDark"), lineWidth: 2))
                    .offset(y: 12)
            }
        }
    }

    @ViewBuilder
    private func icon(for kind: ActionButtonKind) -> some View {
        Group {
            switch kind {
            case .undo:
                Image(systemName: "arrow.uturn.backward.circle.fill")
            case .delete:
                Image(systemName: "xmark.circle.fill")
            case .keep:
                Image(systemName: "checkmark.circle.fill")
            }
        }
        .font(.system(size: 34))
        .foregroundColor(.primary)
        .background(
            Circle()
                .fill(Color("LightGreen").opacity(0.6))
                .frame(width: 56, height: 56)
        )
    }

}

struct SettingsView: View {
    @AppStorage("actionOrder") private var actionOrderRaw: Int = ActionButtonOrder.default.rawValue

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(ActionButtonOrder.allCases) { option in
                    Button {
                        actionOrderRaw = option.rawValue
                    } label: {
                        OrderRow(order: option, isSelected: actionOrderRaw == option.rawValue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color("Background").ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
