//
//  HomepageView.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-03.
//

import SwiftUI

struct HomepageView: View {
    // In a real app this might come from your data model
    @State private var deletedCount: Int = 18

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                
                // MARK: Logo Header
                HStack(spacing: 8) {
                    Text("Tidy")
                        .font(.largeTitle).fontWeight(.semibold)
                    // replace "hand.tap" with custom asset name if needed
                    Image("logo")
                        .imageScale(.large)
                    Text("Taps")
                        .font(.largeTitle).fontWeight(.semibold)
                }
                .foregroundColor(.primary)

                Spacer()

                // MARK: Buttons
                VStack(spacing: 20) {
                    
                    // Start
                    NavigationLink(destination: /* Your StartView() */ Text("Start screen")) {
                        Text("Start")
                    }
                    .buttonStyle(
                        CapsuleButtonStyle(
                            fill: Color("AccentLight"),    // define in Assets.xcassets
                            stroke: Color("AccentDark")
                        )
                    )

                    // Deleted + Badge
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: /* Your DeletedView() */ Text("Deleted screen")) {
                            Text("Deleted")
                        }
                        .buttonStyle(
                            CapsuleButtonStyle(
                                fill: .clear,
                                stroke: Color("AccentDark")
                            )
                        )

                        if deletedCount > 0 {
                            Text("\(deletedCount)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle().foregroundColor(.red))
                                .offset(x: 12, y: -12)
                        }
                    }

                    // Settings
                    NavigationLink(destination: /* Your SettingsView() */ Text("Settings screen")) {
                        Text("Settings")
                    }
                    .buttonStyle(
                        CapsuleButtonStyle(
                            fill: .clear,
                            stroke: Color("AccentDark")
                        )
                    )
                }

                Spacer()
            }
            .padding()
            .background(Color("Background")) // define your light green here
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
        }
    }
}

struct HomepageView_Previews: PreviewProvider {
    static var previews: some View {
        HomepageView()
    }
}
