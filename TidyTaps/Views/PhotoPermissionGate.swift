//
//  PhotoPermissionGate.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-10.
//
import SwiftUI
import Photos
import PhotosUI   // for presentLimitedLibraryPicker(from:)


struct PhotoPermissionGate<Content: View>: View {
    @State private var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    let content: () -> Content

    var body: some View {
        Group {
            switch status {
            case .authorized:
                content()

            case .limited:
                // App works; show a small banner to manage selection if they want
                LimitedAccessChrome(onManage: presentLimitedPicker) {
                    content()
                }

            case .notDetermined:
                SoftAsk(onAllow: requestAuth, onSkip: { })

            case .denied, .restricted:
                DeniedChrome(onOpenSettings: openSettings, onRefresh: refresh)

            @unknown default:
                DeniedChrome(onOpenSettings: openSettings, onRefresh: refresh)
            }
        }
        .onAppear(perform: refresh)
    }

    // MARK: - Actions

    private func refresh() {
        status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    private func requestAuth() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
            DispatchQueue.main.async { refresh() }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func presentLimitedPicker() {
        // Available iOS 14+
        guard #available(iOS 14, *),
              let root = keyWindowRootViewController()
        else { return }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: root)
    }

    private func keyWindowRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }
}

// MARK: - Mini UI pieces (style to taste)

private struct SoftAsk: View {
    var onAllow: () -> Void
    var onSkip:  () -> Void
    @State private var wave = false

    var body: some View {
        
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 28) {
                
                // 👋 emoji
                Text("👋")
                    .font(.system(size: 96))
                    .rotationEffect(.degrees(wave ? 12 : -12))
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: wave)
                    .onAppear { wave = true }
                    .padding(.top, 24)
                    .accessibilityLabel("Waving hand")

                //  headline
                Text("Hey there,\nwelcome to TidyTaps!")
                    .font(.custom("Poppins-Semibold", size: 28))
                    .foregroundStyle(.accentDark)
                    .multilineTextAlignment(.center)
                    

                // why access is need bullet pts
                VStack(spacing: 10) {
                    Text("To help you quickly tidy your camera roll, we need permission to access your photos.")
                        .font(.custom("Poppins-Regular", size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.accentDark)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("See photos by month", systemImage: "calendar")
                        Label("Mark keep or delete fast", systemImage: "checkmark.circle")
                        Label("Undo anytime", systemImage: "arrow.uturn.backward")
                    }
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundStyle(.accentDark)
                    .frame(maxWidth: 340, alignment: .leading)
                    .padding(.top, 6)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    
                    Button(action: onAllow){
                        Text("Allow Photos")
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(
                        CapsuleButtonStyle(
                            fill: Color("Yellow"),
                            stroke: Color("AccentDark"),
                            lineWidth: 4
                        )
                    )

//                    Button(action: onSkip) {
//                        Text("Not now")s
//                            .foregroundStyle(.black)
//                    }
//                    .buttonStyle(
//                        CapsuleButtonStyle(
//                            fill: Color("AccentLight"),
//                            stroke: Color("AccentDark"),
//                            lineWidth: 4
//                        )
//                    )

                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                // Tiny privacy line
                Text("We don’t upload or share your photos. Access stays on your device.")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.lightGreen)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
            }
        }
    }
}

private struct DeniedChrome: View {
    var onOpenSettings: () -> Void
    var onRefresh: () -> Void

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "lock.slash")
                    .font(.system(size: 44))
                    

                Text("Photos Access Needed")
                    .font(.custom("Poppins-Semibold", size: 26))
                    .foregroundStyle(.accentDark)

                Text("You chose “Don’t Allow.” To organize your photos, please enable Photos access in Settings.")
                    .font(.custom("Poppins-Regular", size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .foregroundStyle(.accentDark)

                Spacer()

                VStack(spacing: 12) {
                    
                    Button(action: onOpenSettings){
                        Text("Open Settings")
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(
                        CapsuleButtonStyle(
                            fill: Color("Yellow"),
                            stroke: Color("AccentDark"),
                            lineWidth: 4
                        )
                    )

//                    Button("I enabled it — Refresh", action: onRefresh)
//                        .buttonStyle(
//                            CapsuleButtonStyle(
//                                fill: Color("AccentLight"),
//                                stroke: Color("AccentDark"),
//                                lineWidth: 4
//                            )
//                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}


private struct LimitedAccessChrome<Content: View>: View {
    var onManage: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            content()

            HStack {
                Text("Limited Photos Access")
                    .font(.subheadline)
                Spacer()
                Button("Manage", action: onManage)
            }
            .padding(10)
            .background(.ultraThinMaterial)
        }
    }
}
