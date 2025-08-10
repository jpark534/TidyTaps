//
//  PhotoMonthsService.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-10.
//

import Foundation
import Photos

struct MonthGroup: Identifiable, Hashable {
    let id: String               // "MMM yyyy"
    let interval: DateInterval
    let total: Int               // total photos in that month
    let acted: Int               // count in (deleted ∪ checked)
    var isDone: Bool { acted >= total && total > 0 }
    var label: String { id }
}


final class MonthsViewModel: ObservableObject {
    @Published var months: [MonthGroup] = []

    func load() {
        // sets for acted photos
        let deletedIDs = PhotoLibraryService.assetIDs(inAlbumTitled: AppAlbum.deleted)
        let checkedIDs = PhotoLibraryService.assetIDs(inAlbumTitled: AppAlbum.checked)
        let actedIDs   = deletedIDs.union(checkedIDs)

        // fetch all images, newest to oldest
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: opts)

        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "MMM yyyy"

        // bucket: key -> (start, end, total, acted)
        var buckets: [String:(start: Date, end: Date, total: Int, acted: Int)] = [:]

        assets.enumerateObjects { asset, _, _ in
            guard let d = asset.creationDate else { return }
            let comps = cal.dateComponents([.year, .month], from: d)
            guard let start = cal.date(from: comps),
                  let end   = cal.date(byAdding: .month, value: 1, to: start) else { return }

            let key = fmt.string(from: start)
            var e = buckets[key] ?? (start, end, 0, 0)
            e.total += 1
            if actedIDs.contains(asset.localIdentifier) { e.acted += 1 }
            buckets[key] = e
        }

        let groups = buckets.map { key, v in
            MonthGroup(id: key, interval: DateInterval(start: v.start, end: v.end),
                       total: v.total, acted: v.acted)
        }.sorted { $0.interval.start > $1.interval.start }

        DispatchQueue.main.async { self.months = groups }
    }


}
