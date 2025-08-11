//
//  DeletedBadgeVM.swift
//  TidyTaps
//
//  Created by Julia Park on 2025-08-10.
//
//**    MAYBE FOR FUTURE SCOPE WILL KEEP THIS HERE. ITS CUZ IT KEPT CRASHING SO I GAVE UP **
//import Foundation
//import Photos
//import Combine
//
//final class DeletedBadgeVM: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
//    @Published var count: Int = 0
//
//    override init() {
//        super.init()
//        PHPhotoLibrary.shared().register(self)
//        refresh()
//    }
//    deinit { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
//
//    func refresh() {
//        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
//        guard status == .authorized || status == .limited else {
//            count = 0; return
//        }
//        count = PhotoLibraryService.assetCount(inAlbumTitled: AppAlbum.deleted)
//    }
//
//    // fires whenever assets are added/removed (including album membership changes)
//    func photoLibraryDidChange(_ changeInstance: PHChange) {
//        DispatchQueue.main.async { self.refresh() }
//    }
//}
