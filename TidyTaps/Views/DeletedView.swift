//
//  DeletedView.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-10.
//

import SwiftUI
import Photos

struct DeletedView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var vm = DeletedViewModel()

    @State private var showConfirm = false

    private let cols = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { presentationMode.wrappedValue.dismiss() } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 44)          // the bar
                .overlay(                                            // title sits centered over the bar
                    Text("Deleted")
                        .font(.custom("Poppins-Semibold", size: 28))
                        .tracking(8),
                    alignment: .center
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)


                // Grid
                
                
                ScrollView {
                    LazyVGrid(columns: cols, spacing: 16) {
                        ForEach(vm.assets, id: \.localIdentifier) { asset in
                            let isSelected = vm.selected == asset.localIdentifier

                            DeletedThumb(asset: asset)                // ⇦ auto-sizes by aspect
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.ultraThinMaterial) // full-tile blur
                                    }
                                }
                                .overlay(alignment: .center) {
                                    if isSelected {
                                        Button { vm.undo(asset) } label: {
                                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                                .font(.system(size: 28))
                                                .padding(10)
                                                .background(Circle().fill(Color("Yellow")))
                                                .overlay(Circle().stroke(Color("AccentDark"), lineWidth: 2))
                                        }
                                    }
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 14)) // tap area = tile
                                .onTapGesture { vm.selected = asset.localIdentifier }
                        }
                    }
                    .padding(.horizontal, 16)   // side margins
                    .padding(.top, 8)
                    .padding(.bottom, 24)


                    // Bottom action
                    if !vm.assets.isEmpty {
                        Button {
                            showConfirm = true
                        } label: {
                            Text("Permanently Delete")
                                .font(.custom("Poppins-Semibold", size: 18))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color("AccentDark"), lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                        }
                    } else {
                        Text("Nothing here :p")
                            .font(.custom("Poppins-Regular", size: 16))
                            .padding(.vertical, 24)
                    }
                }
            }
        }
        .onAppear { vm.load() }
        //permenant delete pop up
        .alert("Are you sure?", isPresented: $showConfirm) {
            Button("No", role: .cancel) { }
            Button("Yes", role: .destructive) { vm.permanentlyDeleteAll() }
        } message: {
            Text("You cannot undo this action.")
        }
    }
}

// MARK: - ViewModel

final class DeletedViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var selected: String? = nil

    private let albumTitle = "Deleted Folder - TidyTap"

    func load() {
        guard let collection = fetchAlbum(named: albumTitle) else {
            assets = []; return
        }
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(in: collection, options: opts)

        var list: [PHAsset] = []
        list.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in list.append(asset) }

        DispatchQueue.main.async {
            self.assets = list
            self.selected = nil
        }
    }

    func undo(_ asset: PHAsset) {
        remove(asset: asset, fromAlbum: albumTitle) { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.assets.removeAll { $0.localIdentifier == asset.localIdentifier }
                self.selected = nil
            }
        }
    }

    func permanentlyDeleteAll() {
        let arr = assets as NSArray
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(arr)   // moves to Photos “Recently Deleted” on USER photo app
        }) { [weak self] success, error in
            if success {
                DispatchQueue.main.async { self?.assets.removeAll() }
            } else if let error {
                print("Delete failed:", error)
            }
        }
    }

    // MARK: helpers

    private func fetchAlbum(named title: String) -> PHAssetCollection? {
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "localizedTitle == %@", title)
        let res = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: opts)
        return res.firstObject
    }

    private func remove(asset: PHAsset, fromAlbum title: String, completion: @escaping () -> Void) {
        guard let collection = fetchAlbum(named: title) else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest(for: collection)?.removeAssets([asset] as NSArray)
        }) { success, error in
            if success { completion() }
            else if let error { print("Remove failed:", error) }
        }
    }
}

// MARK: - Thumb view

private struct DeletedThumb: View {
    let asset: PHAsset
    @State private var image: UIImage?

    private var aspect: CGFloat {
        let w = max(1, CGFloat(asset.pixelWidth))
        let h = max(1, CGFloat(asset.pixelHeight))
        return w / h                           // width / height
    }

    var body: some View {
        ZStack {
            // reserve space using the true aspect ratio
            Color.clear
                .aspectRatio(aspect, contentMode: .fit)
                .background(Color.gray.opacity(0.08))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()             // show the whole photo
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: asset.localIdentifier) {
            let opts = PHImageRequestOptions()
            opts.deliveryMode = .highQualityFormat
            // pick a reasonable target size for the column width (~300px wide)
            let targetWidth: CGFloat = 600
            let targetSize = CGSize(width: targetWidth, height: targetWidth / aspect)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: opts
            ) { img, _ in
                self.image = img
            }
        }
    }
}

