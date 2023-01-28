//
//  UIImageExtension.swift
//  TimeLapseMovieMaker
//
//  Created by 藤治仁 on 2023/01/28.
//

import UIKit

extension UIImage {
    func resize(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        let scaleWidth = self.size.width / size.width
        let scaleHeight = self.size.height / size.height
        let scale = min(scaleWidth, scaleHeight)
        let resizedSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        self.draw(in: CGRect(
            x: (size.width - resizedSize.width) / 2.0,
            y: (size.height - resizedSize.height) / 2.0,
            width: resizedSize.width,
            height: resizedSize.height)
        )
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func ciImage() -> CIImage? {
        if let ciImage = self.ciImage {
            return ciImage
        }
        if let cgImage = self.cgImage {
            return CIImage(cgImage: cgImage)
        }
        return nil
    }

    func pixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        guard let ciImage = self.ciImage() else {
            return pixelBuffer
        }
        let attributes: [String : Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(self.size.width),
                                         Int(self.size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attributes as CFDictionary,
                                         &pixelBuffer
        )
        
        guard let pixelBuffer = pixelBuffer,
              status == kCVReturnSuccess else {
            return pixelBuffer
        }

        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let _ = CGContext(data: pixelData,
                                      width: Int(self.size.width),
                                      height: Int(self.size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            return pixelBuffer
        }

        let ciContext = CIContext()
        ciContext.render(ciImage, to: pixelBuffer)

        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        return pixelBuffer
    }
    
}
