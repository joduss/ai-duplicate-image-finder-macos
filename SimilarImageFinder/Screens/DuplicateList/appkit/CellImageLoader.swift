//

import Foundation
import Combine
import AppKit

class CellImageLoader {
    
    private var task: Task<(), Never>?
    
    public func load(url: URL, completed: @escaping (NSImage) -> (), width: Int, height: Int) {
        task = Task.detached {
            
            guard !Task.isCancelled else { return }
            
            guard let image = try? CellImageLoader.loadImage(url: url, width: width, height: height) else {
                return
            }
                
            guard !Task.isCancelled else { return }
            
            DispatchQueue.main.async {
                completed(image)
            }
        }
    }
    
    public func cancel() {
        task?.cancel()
    }
    
    private class func loadImage(url: URL, width: Int, height: Int) throws -> NSImage? {
        try Task.checkCancellation()

        guard let image = NSImage(contentsOf: url) else {return nil}
        
        try Task.checkCancellation()
        return try self.resize(image: image, width: width, height: height)
    }
    
    private class func resize(image: NSImage, width: Int, height: Int) throws -> NSImage? {
        let resizedImg = NSImage(size: NSSize(width: width, height: height))
        resizedImg.lockFocus()
        
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        
        let ct = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        let ctx = NSGraphicsContext(cgContext: ct, flipped: false)
        ctx.imageInterpolation = NSImageInterpolation.medium
        
        try Task.checkCancellation()
        
        image.draw(in: NSRect(x: 0, y: 0, width: width, height: height),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        
        resizedImg.unlockFocus()
        
        return resizedImg
    }
}
