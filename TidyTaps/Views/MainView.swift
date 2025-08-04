//
//  MainView.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-04.
//
import SwiftUI
import Photos

struct MainView: View {
    // injected when you push from MonthsView:
    let monthYear: String

    // the list of assets for that month
    @State private var assets: [PHAsset] = []
    @State private var currentIndex: Int = 0

    // stack of undone actions so Undo can restore
    private enum Action { case liked, deleted, kept }
    @State private var undoStack: [(asset: PHAsset, action: Action)] = []

    // to pop back home
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack {
            //  ─── Top Bar ─────────────────────
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text(monthYear)
                    .font(.custom("Poppins-Semibold", size: 20))
            }
            .padding()

            //  ─── Photo Display ───────────────
            GeometryReader { geo in
                if let asset = assets[safe: currentIndex] {
                    PhotoView(asset: asset)
                        .frame(width: geo.size.width,
                               height: geo.size.height * 0.6)
                } else {
                    Text("No more photos")
                        .font(.title2)
                }
            }

            //  ─── Counter ─────────────────────
            Text("\(currentIndex+1) of \(assets.count)")
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.8))
                .cornerRadius(20)

            //  ─── Action Buttons ─────────────
            HStack(spacing: 24) {
                // Undo
                Button {
                    undoLastAction()
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 36))
                }

                // Like
                Button {
                    applyAction(.liked)
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36))
                }

                // Delete
                Button {
                    applyAction(.deleted)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                }

                // Keep
                Button {
                    applyAction(.kept)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                }
            }
            .padding(.bottom)
        }
        .onAppear(perform: loadAssets)
        .background(Color("Background").ignoresSafeArea())
    }

    // MARK: Helpers ────────────────────────────────────

    private func loadAssets() {
        // fetch assets from the photo library whose creation date matches monthYear
        // e.g. parse monthYear into DateInterval then use PHFetchOptions
        // for simplicity, here’s a stub:
        let fetchOptions = PHFetchOptions()
        // configure fetchOptions.predicate to match monthYear...
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        assets = (0..<result.count).compactMap { result.object(at: $0) }
    }

    private func applyAction(_ action: Action) {
        guard let asset = assets[safe: currentIndex] else { return }

        // record it so we can undo
        undoStack.append((asset: asset, action: action))

        switch action {
        case .liked:
            addAsset(asset, toAlbum: "Liked Folder - TidyTap")
        case .deleted:
            addAsset(asset, toAlbum: "Deleted Folder - TidyTaps")
        case .kept:
            break
        }

        // remove from our array and advance
        assets.remove(at: currentIndex)
        if currentIndex >= assets.count {
            currentIndex = max(0, assets.count - 1)
        }
    }

    private func undoLastAction() {
        guard let last = undoStack.popLast() else { return }
        let (asset, action) = last

        // remove from the album if we had added it
        if action != .kept {
            removeAsset(asset, fromAlbum: action == .liked
                        ? "Liked Folder - TidyTap"
                        : "Deleted Folder - TidyTaps")
        }

        // re-insert asset at its prior index
        assets.insert(asset, at: currentIndex)
    }

    private func addAsset(_ asset: PHAsset, toAlbum title: String) {
        PHPhotoLibrary.shared().performChanges {
            guard let collection =
               PHAssetCollection.fetchAssetCollections(
                 with: .album, subtype: .any,
                 options: PHFetchOptions()
               ).firstObject(where: { $0.localizedTitle == title }),
                  let req = PHAssetCollectionChangeRequest(for: collection)
            else { return }
            req.addAssets([asset] as NSArray)
        }
    }

    private func removeAsset(_ asset: PHAsset, fromAlbum title: String) {
        PHPhotoLibrary.shared().performChanges {
            guard let collection =
               PHAssetCollection.fetchAssetCollections(
                 with: .album, subtype: .any,
                 options: PHFetchOptions()
               ).firstObject(where: { $0.localizedTitle == title }),
                  let req = PHAssetCollectionChangeRequest(for: collection)
            else { return }
            req.removeAssets([asset] as NSArray)
        }
    }
}

// A small helper view to render a PHAsset as an Image
struct PhotoView: View {
    let asset: PHAsset
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let img = uiImage {
                Image(uiImage: img)
                  .resizable()
                  .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            PHImageManager.default()
              .requestImage(
                for: asset,
                targetSize: UIScreen.main.bounds.size,
                contentMode: .aspectFit,
                options: options
              ) { img, _ in
                self.uiImage = img
              }
        }
    }
}

// Array safe index
extension Array {
    subscript (safe i: Index) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}

