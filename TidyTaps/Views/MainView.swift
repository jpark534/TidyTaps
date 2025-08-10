import SwiftUI
import Photos

// MARK: - Main Page

struct MainView: View {
    /// like "Mar 2025" passed from MonthsView
    let monthLabel: String

    @StateObject private var vm = MainViewModel()
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 12) {
                // Top bar
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text(monthLabel)
                        .font(.custom("Poppins-Semibold", size: 20))
                    Spacer().frame(width: 22) // home icon. ts is def not where I want it to be but its an estimate
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Photo zonee
                GeometryReader { geo in
                    Group {
                        if let asset = vm.currentAsset {
                            AssetImageView(asset: asset)
                                .id(asset.localIdentifier)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .padding(.horizontal, 18)
                                .padding(.top, 8)
                        } else {
                            VStack(spacing: 10) {
                                Text("All done")
                                    .font(.custom("Poppins-Semibold", size: 22))
                                Text("No more photos in this month.")
                                    .font(.custom("Poppins-Regular", size: 16))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(height: 420) // photo height

                // Counter thingy
                if vm.remaining > 0 {
                    Text("\(vm.remaining)")               // <— remaining photos in the pile
                        .font(.custom("Poppins-Medium", size: 16))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color("AccentDark"), lineWidth: 1))
                        .padding(.bottom, 4)
                }

                // Action row
                HStack(spacing: 24) {
                    // Undo
                    RoundIcon("arrow.uturn.backward.circle.fill") {
                        vm.undo()
                    }
                    .opacity(vm.canUndo ? 1 : 0.4)
                    .disabled(!vm.canUndo)

                    // Keep
                    RoundIcon("checkmark.circle.fill") {
                        vm.apply(.kept)
                    }

                    // Delete (to Deleted album)
                    ZStack(alignment: .topTrailing) {
                        RoundIcon("xmark.circle.fill") {
                            vm.apply(.deleted)
                        }
                        if vm.remaining > 0 {
                            Text("\(vm.deletedCount)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }

                    // Like (to Liked album)
                    RoundIcon("heart.circle.fill") {
                        vm.apply(.liked)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            vm.load(monthLabel: monthLabel)
        }
    }
}


// MARK: - ViewModel

final class MainViewModel: ObservableObject {
    enum Action { case liked, deleted, kept }

    @Published var assets: [PHAsset] = []
    @Published var index: Int = 0
    @Published var deletedCount: Int = 0 //deleted count starting at 0

    private var lastActions: [(asset: PHAsset, action: Action, indexBefore: Int)] = []

    var currentAsset: PHAsset? { assets.indices.contains(index) ? assets[index] : nil }
    var remaining: Int { assets.count }             // shows total left in the pile
    var canUndo: Bool { !lastActions.isEmpty }

    // Load assets that fall inside the given month
    func load(monthLabel: String) {
        let interval = DateInterval.forMonthLabel(monthLabel)
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "mediaType == %d AND creationDate >= %@ AND creationDate < %@",
                                     PHAssetMediaType.image.rawValue, interval.start as NSDate, interval.end as NSDate)
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let result = PHAsset.fetchAssets(with: opts)
        var list: [PHAsset] = []
        list.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in list.append(asset) }

        DispatchQueue.main.async {
            self.assets = list
            self.index = 0
            self.lastActions.removeAll()
            self.deletedCount = 0 //resetting when loading another month
        }
    }

    func apply(_ action: Action) {
        guard let asset = currentAsset else { return }
        // record for undo
        lastActions.append((asset, action, index))

        switch action {
        case .liked:
            PhotoLibraryService.add(asset: asset, toAlbumTitled: "Liked Folder - TidyTap")
        case .deleted:
            PhotoLibraryService.add(asset: asset, toAlbumTitled: "Deleted Folder - TidyTap")
            deletedCount += 1   //increment delete icon count when pressed
        case .kept:
            break
        }

        // remove from the pile
        assets.remove(at: index)
        if index >= assets.count { index = max(0, assets.count - 1) }
    }

    func undo() {
        guard let last = lastActions.popLast() else { return }
        // remove from album if needed
        switch last.action {
        case .liked:
            PhotoLibraryService.remove(asset: last.asset, fromAlbumTitled: "Liked Folder - TidyTap")
        case .deleted:
            PhotoLibraryService.remove(asset: last.asset, fromAlbumTitled: "Deleted Folder - TidyTap")
            deletedCount = max(0, deletedCount - 1) //when undo, minus da number
        case .kept:
            break
        }
        // reinsert at the spot it was
        let insertAt = min(last.indexBefore, assets.count)
        assets.insert(last.asset, at: insertAt)
        index = insertAt
    }
}

// MARK: - Photo Helpers

struct AssetImageView: View {
    let asset: PHAsset
    @State private var img: UIImage?

    var body: some View {
        Group {
            if let img {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: asset.localIdentifier) { _, _ in
                    img = nil
                    loadImage()
                }
    }

    private func loadImage() {
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .highQualityFormat
        opts.isSynchronous = false

        let size = UIScreen.main.bounds.size
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: size.width * 2, height: size.height * 2),
            contentMode: .aspectFit,
            options: opts
        ) { image, _ in
            DispatchQueue.main.async { self.img = image }
        }
    }
}


import Photos

enum PhotoLibraryService {

    // Find/orcreate an album by title
    private static func album(titled title: String) -> PHAssetCollection? {
        // 1) Try to find an existing album with this title
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        var existing: PHAssetCollection?
        fetch.enumerateObjects { coll, _, stop in
            if coll.localizedTitle == title {
                existing = coll
                stop.pointee = true
            }
        }
        if let existing { return existing }

        // 2) Not found → then create it
        var placeholder: PHObjectPlaceholder?
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                let req = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                placeholder = req.placeholderForCreatedAssetCollection
            }
        } catch {
            print("Failed to create album '\(title)': \(error)")
            return nil
        }

        guard let ph = placeholder else { return nil }
        let created = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [ph.localIdentifier], options: nil)
        return created.firstObject
    }

    static func add(asset: PHAsset, toAlbumTitled title: String) {
        guard let collection = album(titled: title) else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest(for: collection)?.addAssets([asset] as NSArray)
        }, completionHandler: nil)
    }

    static func remove(asset: PHAsset, fromAlbumTitled title: String) {
        guard let collection = album(titled: title) else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest(for: collection)?.removeAssets([asset] as NSArray)
        }, completionHandler: nil)
    }
}


// MARK: - UI Bits

private func RoundIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: systemName)
            .font(.system(size: 34))
            .frame(width: 66, height: 66)
            .background(
                Circle().fill(Color("LightGreen").opacity(0.9))
            )
            .overlay(
                Circle().stroke(Color("AccentDark"), lineWidth: 2)
            )
            .foregroundColor(.primary)
    }
}

// MARK: - Utilities

extension DateInterval {
    /// Accepts "Mar 2025", "FEB 2025" ca[ital
    static func forMonthLabel(_ label: String) -> DateInterval {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "MMM yyyy"

        // exact but change uppercase
        let monthStart = fmt.date(from: label) ?? fmt.date(from: label.uppercased()) ?? Date()

        var comps = Calendar.current.dateComponents([.year, .month], from: monthStart)
        comps.day = 1
        let start = Calendar.current.date(from: comps) ?? monthStart
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? start.addingTimeInterval(30*24*3600)
        return DateInterval(start: start, end: end)
    }
}
