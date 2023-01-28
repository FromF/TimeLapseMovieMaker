//
//  FileModel.swift
//  TimeLapseMovieMaker
//
//  Created by 藤治仁 on 2023/01/28.
//

import Foundation

class FileModel: NSObject {
    private var importDirectoryName: URL {
        let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directoryPath
    }
    
    func createImportFileList() -> [URL]? {
        var importFileList: [URL] = []
        let fileManager = FileManager.default
        do {
            let list = try fileManager.contentsOfDirectory(at: importDirectoryName, includingPropertiesForKeys: nil)
            for file in list {
                if file.absoluteString.hasSuffix("jpg") {
                    print("\(#fileID) \(#function) \(#line) movieFile:\(file)")
                    importFileList.append(file)
                }
                if file.absoluteString.hasSuffix("png") {
                    print("\(#fileID) \(#function) \(#line) movieFile:\(file)")
                    importFileList.append(file)
                }
            }
            return importFileList
        } catch {
            print("エラー\(error)")
        }
        
        return nil
    }
}
