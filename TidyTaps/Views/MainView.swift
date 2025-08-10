import SwiftUI
import Photos


// MARK: - Settings Page
//settings (4 different orders of action button) *REMINDER* to go thru comments bc im so tired proper english not working


enum ActionButtonKind: String, CaseIterable, Hashable {
    case keep, delete, undo
}

enum ActionButtonOrder: Int, CaseIterable, Identifiable {
    case check_x_undo = 0
    case undo_x_check = 1
    case x_undo_check = 2
    case check_undo_x = 3

    var id: Int { rawValue }

    var kinds: [ActionButtonKind] {
        switch self {
        case .check_x_undo: return [.keep, .delete, .undo]
        case .undo_x_check: return [.undo, .delete, .keep]
        case .x_undo_check: return [.delete, .undo, .keep]
        case .check_undo_x: return [.keep, .undo, .delete]
        }
    }

    static var `default`: ActionButtonOrder { .undo_x_check }
}



// MARK: - Main Page

struct MainView: View {
    /// like "Mar 2025" passed from MonthsView
    let monthLabel: String

    @StateObject private var vm = MainViewModel()
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("actionOrder") private var actionOrderRaw: Int = ActionButtonOrder.default.rawValue
    private var selectedOrder: ActionButtonOrder {
        ActionButtonOrder(rawValue: actionOrderRaw) ?? .default
    }


    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 12) {
                // Top bar
                HStack {
                    Spacer()
                    Text(monthLabel)
                        .font(.custom("Poppins-Semibold", size: 20))
                    Spacer().frame(width: 22) //
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
                // Actions (dynamic order)
                HStack(spacing: 24) {
                    ForEach(selectedOrder.kinds, id: \.self) { kind in
                        actionButton(kind)
                    }
                }
                .padding(.bottom, 12)

            }
        }
        .onAppear {
            vm.load(monthLabel: monthLabel)
        }
    }
    @ViewBuilder
    private func actionButton(_ kind: ActionButtonKind) -> some View {
        switch kind {
        case .undo:
            RoundIcon("arrow.uturn.backward.circle.fill") { vm.undo() }
                .opacity(vm.canUndo ? 1 : 0.4)
                .disabled(!vm.canUndo)

        case .delete:
            ZStack(alignment: .topTrailing) {
                RoundIcon("xmark.circle.fill") { vm.apply(.deleted) }
                if vm.deletedCount > 0 {
                    Text("\(vm.deletedCount)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle())
                        .offset(x: 10, y: -10)
                }
            }

        case .keep:
            RoundIcon("checkmark.circle.fill") { vm.apply(.kept) }
        }
    }

}


// MARK: - ViewModel

final class MainViewModel: ObservableObject {
    enum Action { case deleted, kept }

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

        // HIDE only deleted
        let deletedIDs = PhotoLibraryService.assetIDs(inAlbumTitled: AppAlbum.deleted)
        let hidden = deletedIDs

        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "mediaType == %d AND creationDate >= %@ AND creationDate < %@",
                                     PHAssetMediaType.image.rawValue, interval.start as NSDate, interval.end as NSDate)
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let result = PHAsset.fetchAssets(with: opts)
        var list: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            if !hidden.contains(asset.localIdentifier) { list.append(asset) }  // keep checked visible
        }

        DispatchQueue.main.async {
            self.assets = list
            self.index = 0
            self.lastActions.removeAll()
            self.deletedCount = 0
        }
    }



    func apply(_ action: Action) {
        guard let asset = currentAsset else { return }
        lastActions.append((asset, action, index))

        switch action {
            // (asset leaves this month pile because your MainView/MonthsView filter deletes)
        case .deleted:
            PhotoLibraryService.add(asset: asset, toAlbumTitled: AppAlbum.deleted)
            deletedCount += 1
        case .kept:
            PhotoLibraryService.add(asset: asset, toAlbumTitled: AppAlbum.checked) // ← track “checked”
        }

        // remove from current array so the next photo shows
        assets.remove(at: index)
        if index >= assets.count { index = max(0, assets.count - 1) }
    }

    func undo() {
        guard let last = lastActions.popLast() else { return }

        switch last.action {
        case .deleted:
            PhotoLibraryService.remove(asset: last.asset, fromAlbumTitled: AppAlbum.deleted)
            deletedCount = max(0, deletedCount - 1)
        case .kept:
            PhotoLibraryService.remove(asset: last.asset, fromAlbumTitled: AppAlbum.checked) // ← undo “checked”
        }

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

// Centralize the album titles so we don't typo them
enum AppAlbum {
    static let deleted  = "Deleted Folder - TidyTap"
    static let checked  = "Checked Folder - TidyTap"
}



enum PhotoLibraryService {

    // Find (or lazily create) an album by title
    private static func album(titled title: String) -> PHAssetCollection? {
        // 1) Try to find an existing album
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        var existing: PHAssetCollection?
        fetch.enumerateObjects { coll, _, stop in
            if coll.localizedTitle == title {
                existing = coll
                stop.pointee = true
            }
        }
        if let existing { return existing }

        // 2) Not found → create it
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

    // Add a single asset to an album
    static func add(asset: PHAsset, toAlbumTitled title: String) {
        guard let collection = album(titled: title) else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest(for: collection)?.addAssets([asset] as NSArray)
        }, completionHandler: nil)
    }

    // Remove a single asset from an album
    static func remove(asset: PHAsset, fromAlbumTitled title: String) {
        guard let collection = album(titled: title) else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest(for: collection)?.removeAssets([asset] as NSArray)
        }, completionHandler: nil)
    }

    // Get the set of asset localIdentifiers that live in an album (used to filter "reviewed")
    static func assetIDs(inAlbumTitled title: String) -> Set<String> {
        guard let collection = album(titled: title) else { return [] }
        let res = PHAsset.fetchAssets(in: collection, options: nil)
        var ids: Set<String> = []
        res.enumerateObjects { asset, _, _ in ids.insert(asset.localIdentifier) }
        return ids
    }
    
//    static func assetCount(inAlbumTitled title: String) -> Int {
//        guard let coll = album(titled: title) else { return 0 }
//        return PHAsset.fetchAssets(in: coll, options: nil).count
//    }
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
