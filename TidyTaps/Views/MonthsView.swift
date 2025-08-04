//
//  MonthsView.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-04.
//

import SwiftUI

struct MonthsView: View {
    // this comes from your data source: only months with photos
    let months: [String]
    

    // to pop back to HomepageView
    @Environment(\.presentationMode) private var presentationMode

    private let colors = [
        Color("Yellow"),
        Color("LightGreen")
    ]

    // two flexible columns
    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top bar: home button + title
                HStack {
                    Button {
                        
                        presentationMode.wrappedValue.dismiss()
                    } label: {
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

                // Grid of month-year buttons
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(Array(months.enumerated()), id: \.element) { idx, monthYear in
                        NavigationLink(destination: PhotoGridView(month: monthYear)) {
                            Text(monthYear.uppercased())
                                .font(.custom("Poppins-Medium", size: 28))
                                .frame(height: 140)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(colorForCell(at: idx))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color("AccentDark"), lineWidth: 2)
                                )
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
    }
    private func colorForCell(at idx: Int) -> Color {
        let row = idx / 2
        let col = idx % 2
        return colors[(row+col) % colors.count]
    }
}

// dummy placeholder for your photo‐grid screen
struct PhotoGridView: View {
    let month: String
    var body: some View {
        Text("Photos for \(month)")
            .navigationTitle(month)
            .font(.custom("Poppins-Semibold", size: 24))
    }
}

struct MonthsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MonthsView(months: [
                "Mar 2025","Feb 2025","Jan 2025","Dec 2024",
                "Nov 2024","Oct 2024","Sept 2024","Aug 2024",
                "Jul 2024","Jun 2024","May 2024","Apr 2024","Mar 2024","Feb 2024","Jan 2024","Dec 2023","Nov 2023",
            ])
        }
    }
}
