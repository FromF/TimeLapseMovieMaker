//
//  MovieMaker.swift
//  TimeLapseMovieMaker
//
//  Created by 藤治仁 on 2023/01/28.
//

import Foundation
import AVFoundation
import UIKit

class MovieMaker: NSObject {
    enum MovieMakerError: Error {
        case startWriteFail
    }

    private let movieSize = CGSize(width: 1920, height: 1080)
    private let movieFPS = 30
    
    func makeMovieFromImages(imagePaths: [URL], moviePath: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // 出力する動画ファイルが存在する場合は一旦削除する
            do {
                try FileManager.default.removeItem(at: moviePath)
            } catch {
                print("\(#fileID) \(#function) \(#line) Could not remove file (or file doesn't exist) \(error.localizedDescription)")
            }
            
            do {
                let videoWriter = try AVAssetWriter(outputURL: moviePath, fileType: .mov)
                let outPutSetings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: movieSize.width,
                    AVVideoHeightKey: movieSize.height
                ]
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outPutSetings)
                videoWriter.add(writerInput)
                
                let sourcePixelBufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                    kCVPixelBufferWidthKey as String: movieSize.width,
                    kCVPixelBufferHeightKey as String: movieSize.height
                ]
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
                
                writerInput.expectsMediaDataInRealTime = true
                
                // 動画生成開始
                if videoWriter.startWriting() == false {
                    throw MovieMakerError.startWriteFail
                }
                
                videoWriter.startSession(atSourceTime: CMTime.zero)
                
                var frameCount = 0
                let durationForEachImage = 1
                
                for imagePath in imagePaths {
                    autoreleasepool {
                        if adaptor.assetWriterInput.isReadyForMoreMediaData {
                            if let data = try? Data(contentsOf: imagePath),
                               let image = UIImage(data: data)?.resize(size: movieSize),
                               let pixelBuffer = image.pixelBuffer() {
                                
                                let frameTime = CMTimeMake(value: Int64(frameCount * durationForEachImage), timescale: Int32(movieFPS))
                                if adaptor.append(pixelBuffer, withPresentationTime: frameTime) == false {
                                    print("\(#fileID) \(#function) \(#line) failed to append pixelBuffer \(imagePath)")
                                }
                                frameCount += 1
                            } else {
                                print("\(#fileID) \(#function) \(#line) Could not open Image \(imagePath)")
                            }
                        }
                    }
                }
                
                // 動画生成終了
                writerInput.markAsFinished()
                videoWriter.finishWriting {
                    print("\(#fileID) \(#function) \(#line) finish movie")
                    continuation.resume()
                }
            } catch {
                print("\(#fileID) \(#function) \(#line) Could not create movie \(error)")
            }
        }
    }
}
