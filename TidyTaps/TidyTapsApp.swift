//
//  TidyTapsApp.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-02.
//

import SwiftUI
import Photos

@main
struct TidyTapsApp: App {

    init() {
        // Ask photos access at launch
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            switch status {
            case .authorized, .limited:
                // OK w access
                createTidyTapAlbums()
            default:
                // denied - showing nice msg later
                break
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            HomepageView()
        }
    }
}

// Create the two albums if missing(liked n deleted)
private func createTidyTapAlbums() {
    let titles = [
       // "Deleted Folder - TidyTap",
        "Checked Folder - TidyTap"
    ]
    PHPhotoLibrary.shared().performChanges {
        for title in titles {
            let opts = PHFetchOptions()
            opts.predicate = NSPredicate(format: "localizedTitle == %@", title)
            let res = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: opts)
            if res.firstObject == nil {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            }
        }
    }
}


