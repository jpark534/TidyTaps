//
//  MonthsView.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-04.
//

import SwiftUI

struct MonthsView: View {
    @StateObject private var vm = MonthsViewModel()
    @Environment(\.presentationMode) private var presentationMode

    private let colors = [ Color("Yellow"), Color("LightGreen") ]
    private let columns = [ GridItem(.flexible(), spacing: 24),
                            GridItem(.flexible(), spacing: 24) ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // top bar
                HStack {
                    Button { presentationMode.wrappedValue.dismiss() } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text("Tidy taps")
                        .font(.custom("Poppins-Semibold", size: 34))
                        .tracking(10)
                    Spacer()
                }
                .padding([.horizontal, .top], 16)

                // grid
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(Array(vm.months.enumerated()), id: \.element.id) { idx, group in
                        NavigationLink(
                            destination: MainView(monthLabel: group.label) // or pass group.interval if you prefer
                        ) {
                            VStack {
                                Text(group.label.uppercased())
                                    .font(.custom("Poppins-Medium", size: 24))
                                Text("\(group.count) photos")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .opacity(0.7)
                            }
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 30).fill(colorForCell(at: idx)))
                            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color("AccentDark"), lineWidth: 2))
                            .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color("Background"))
        .ignoresSafeArea(edges: .bottom)
        .onAppear { vm.load() }     // ← fetch real months
    }

    private func colorForCell(at idx: Int) -> Color {
        let row = idx / 2, col = idx % 2
        return colors[(row + col) % colors.count]
    }
}

