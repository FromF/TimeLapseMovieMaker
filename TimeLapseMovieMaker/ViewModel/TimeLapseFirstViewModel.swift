//
//  TimeLapseFirstViewModel.swift
//  TimeLapseMovieMaker
//
//  Created by 藤治仁 on 2023/01/28.
//

import SwiftUI
import Photos

class TimeLapseFirstViewModel: NSObject, ObservableObject {
    @Published var importFileList: [URL] = []
    @Published var isProgress = false
    private let fileModel = FileModel()
    private let movieMaker = MovieMaker()
    
    func createImportFileList() {
        if let importFileList = fileModel.createImportFileList() {
            self.importFileList = importFileList
        }
    }
    
    @MainActor func executeTimeLapse() {
        guard let moviePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("TimeLapse.mp4")  else {
            return
        }
        Task {
            isProgress = true
            do {
                try await movieMaker.makeMovieFromImages(imagePaths: importFileList, moviePath: moviePath)
                
                try await PHPhotoLibrary.shared().performChanges {
                    _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: moviePath)
                }
            } catch {
                print("\(#fileID) \(#function) \(#line) failed \(error.localizedDescription)")
            }
            isProgress = false
        }
    }

}
