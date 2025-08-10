//
//  HomepageView.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-03.
//

import SwiftUI

struct HomepageView: View {
    // the deleted count in red bubble. for now its test number
//    @StateObject private var deletedBadge = DeletedBadgeVM()

    

    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                VStack(spacing: 40) {
                    Spacer(minLength: 80)
                    // MARK: Logo Header
                    HStack(alignment: .center, spacing: 0) {
                      
                      // 1) "T i d y" with big tracking
                      Text("Tidy")
                        .font(.custom("Poppins-Semibold", size: 45))
                        .tracking(14)          // adds 20pts between every letter
                        .foregroundColor(.primary)

                      // 2) Your logo, rotated/offset to lean into the "aps"
                      Image("logo")            // or Image(systemName: "hand.tap.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 87, height: 87)
                        .rotationEffect(.degrees(10))   // tilt it toward the right
                        .offset(x: 2, y:-5)                  // pull it left so it overlaps slightly

                      // 3) "a p s" with the same tracking
                      Text("aps")
                        .font(.custom("Poppins-Semibold", size: 45))
                        .tracking(12)
                        .foregroundColor(.primary)
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // MARK: Buttons
                    VStack(spacing: 20) {
                        
                        // Start
                        NavigationLink(destination: MonthsView()) {
                            Text("Start")
                                .font(.custom("Poppins-Medium", size: 23))
                                .fontWeight(.semibold)
                                .tracking(1)
                        }
                        .buttonStyle(
                            CapsuleButtonStyle(
                                fill: Color("Yellow"),
                                stroke: Color("AccentDark"),
                                lineWidth: 4
                            )
                        )
                        
                        // Deleted + Badge
                        ZStack(alignment: .topTrailing) {
                            NavigationLink(destination: DeletedView())  {
                                Text("Deleted")
                                    .font(.custom("Poppins-Medium", size: 23))
                                    .fontWeight(.semibold)
                                    .tracking(1)
                            }
                            .buttonStyle(
                                CapsuleButtonStyle(
                                    fill: Color("AccentLight"),
                                    stroke: Color("AccentDark"),
                                    lineWidth: 4
                                )
                            )
                            
//                            if deletedCount > 0 {
//                                Text("\(deletedCount)")
//                                    .font(.custom("Poppins-Medium", size: 18)).fontWeight(.semibold)
//                                
//                                    .foregroundColor(.white)
//                                    .padding(5)
//                                    .background(Circle().foregroundColor(.red))
//                                    .offset(x: 7, y: -10)
//                            }
                        }
                        
                        // Settings
                        NavigationLink(destination:SettingsView()) {
                            Text("Settings")
                                .font(.custom("Poppins-Medium", size: 23))
                                .fontWeight(.semibold)
                                .tracking(1)
                        }
                        
                        .buttonStyle(
                            CapsuleButtonStyle(
                                fill: Color("AccentLight"),
                                stroke: Color("AccentDark"),
                                lineWidth: 4
                            )
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationBarHidden(true)
        }
    }
}

struct HomepageView_Previews: PreviewProvider {
    static var previews: some View {
        HomepageView()
    }
}
