//
//  PhotoMonthsService.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-10.
//

import Foundation
import Photos

struct MonthGroup: Identifiable, Hashable {
    let id: String              // "MMM yyyy", like "Mar 2025"
    let interval: DateInterval  // start of month → next month
    let count: Int              // number of images in that month
    var label: String { id }
}

final class MonthsViewModel: ObservableObject {
    @Published var months: [MonthGroup] = []

    func load() {
        // Fetch all images ordered newest to oldest
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: opts)

        // Group by calendar month
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "MMM yyyy"

        var buckets: [String:(start: Date, end: Date, count: Int)] = [:]

        assets.enumerateObjects { asset, _, _ in
            guard let d = asset.creationDate else { return }
            let comps = cal.dateComponents([.year, .month], from: d)
            guard let start = cal.date(from: comps),
                  let end = cal.date(byAdding: .month, value: 1, to: start) else { return }

            let key = fmt.string(from: start)        // "Mar 2025"
            var entry = buckets[key] ?? (start, end, 0)
            entry.count += 1
            buckets[key] = entry
        }

        // Map to MonthGroup and sort newest first
        let groups = buckets.map { key, v in
            MonthGroup(id: key, interval: DateInterval(start: v.start, end: v.end), count: v.count)
        }.sorted { $0.interval.start > $1.interval.start }

        DispatchQueue.main.async { self.months = groups }
    }
}
