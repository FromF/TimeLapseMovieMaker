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
/**
 NSParameterAssert(imagePaths);
 NSParameterAssert(path);
 NSAssert((imagePaths.count > 0), @"Set least one image.");
 
 NSFileManager *fileManager = [NSFileManager defaultManager];
 
 // 既にファイルがある場合は削除する
 if ([fileManager fileExistsAtPath:path]) {
     [fileManager removeItemAtPath:path error:nil];
 }
 
 // 最初の画像から動画のサイズ指定する
 CGSize size = CGSizeMake(1920, 1080);
 
 NSError *error = nil;
 
 self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                              fileType:AVFileTypeQuickTimeMovie
                                                 error:&error];
 
 if (error) {
     NSLog(@"%@", [error localizedDescription]);
     return;
 }
 
 NSDictionary *outputSettings =
 @{
   AVVideoCodecKey  : AVVideoCodecH264,
   AVVideoWidthKey  : @(size.width),
   AVVideoHeightKey : @(size.height),
   };
 
 AVAssetWriterInput *writerInput = [AVAssetWriterInput
                                    assetWriterInputWithMediaType:AVMediaTypeVideo
                                    outputSettings:outputSettings];
 
 [self.videoWriter addInput:writerInput];
 
 NSDictionary *sourcePixelBufferAttributes =
 @{
   (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32ARGB),
   (NSString *)kCVPixelBufferWidthKey           : @(size.width),
   (NSString *)kCVPixelBufferHeightKey          : @(size.height),
   };
 
 AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                  assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                  sourcePixelBufferAttributes:sourcePixelBufferAttributes];
 
 writerInput.expectsMediaDataInRealTime = YES;
 
 // 動画生成開始
 if (![self.videoWriter startWriting]) {
     NSLog(@"Failed to start writing.");
     return;
 }
 
 [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
 
 CVPixelBufferRef buffer = NULL;
 
 int frameCount = 0;
 int durationForEachImage = 1;
 int32_t fps = (int32_t)self.fps;
 
 for (NSString *imagePath in imagePaths) {
     @autoreleasepool {  //メモリーがループ内では解放されないので明示して解放させる
         if (adaptor.assetWriterInput.readyForMoreMediaData) {
             UIImage *image = [self getJpegFile:imagePath Size:size];
             if (image == nil) {
                 NSLog(@"getJpegFile Fail");
                 continue;
             }
             
             CMTime frameTime = CMTimeMake((int64_t)frameCount * durationForEachImage, fps);
             
             buffer = [self pixelBufferFromCGImage:image.CGImage];
             
             if (![adaptor appendPixelBuffer:buffer withPresentationTime:frameTime]) {
                 NSLog(@"Failed to append buffer. [image : %@]", image);
             }
             
             if(buffer) {
                 CVBufferRelease(buffer);
             }
             
             frameCount++;
         }
     }
 }
 
 // 動画生成終了
 [writerInput markAsFinished];
 [self.videoWriter finishWritingWithCompletionHandler:^{
     NSLog(@"Finish writing!");
     // 動画生成終了通知
     dispatch_semaphore_signal(semaphore_);
 }];
 // 動画生成終了待ち
 dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
 CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
 //カメラロール保存
 UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
 //カメラロール保存完了待ち
 dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
 
 
 **/
    
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
