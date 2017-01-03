//
//  NSImageColors.swift
//  https://github.com/jathu/UIImageColors
//
//  Created by Jathu Satkunarajah (@jathu) on 2015-06-11 - Toronto
//  Original Cocoa version by Panic Inc. - Portland
//

import Cocoa

public struct ImageColors {
    public var background: NSColor!
    public var primary: NSColor!
    public var secondary: NSColor!
    public var detail: NSColor!
}

class PCCountedColor {
    let color: NSColor
    let count: Int
    
    init(color: NSColor, count: Int) {
        self.color = color
        self.count = count
    }
}

extension CGColor {
    var components: [CGFloat] {
        get {
            var red = CGFloat()
            var green = CGFloat()
            var blue = CGFloat()
            var alpha = CGFloat()
            NSColor(cgColor: self)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [red,green,blue,alpha]
        }
    }
}

extension NSColor {
    
    var isDarkColor: Bool {
        let RGB = self.cgColor.components
        return (0.2126 * RGB[0] + 0.7152 * RGB[1] + 0.0722 * RGB[2]) < 0.5
    }
    
    var isBlackOrWhite: Bool {
        let RGB = self.cgColor.components
        return (RGB[0] > 0.91 && RGB[1] > 0.91 && RGB[2] > 0.91) || (RGB[0] < 0.09 && RGB[1] < 0.09 && RGB[2] < 0.09)
    }
    
    func isDistinct(compareColor: NSColor) -> Bool {
        let bg = self.cgColor.components
        let fg = compareColor.cgColor.components
        let threshold: CGFloat = 0.25
        
        if fabs(bg[0] - fg[0]) > threshold || fabs(bg[1] - fg[1]) > threshold || fabs(bg[2] - fg[2]) > threshold {
            if fabs(bg[0] - bg[1]) < 0.03 && fabs(bg[0] - bg[2]) < 0.03 {
                if fabs(fg[0] - fg[1]) < 0.03 && fabs(fg[0] - fg[2]) < 0.03 {
                    return false
                }
            }
            return true
        }
        return false
    }
    
    func colorWithMinimumSaturation(minSaturation: CGFloat) -> NSColor {
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        if saturation < minSaturation {
            return NSColor(hue: hue, saturation: minSaturation, brightness: brightness, alpha: alpha)
        } else {
            return self
        }
    }
    
    func isContrastingColor(compareColor: NSColor) -> Bool {
        let bg = self.cgColor.components
        let fg = compareColor.cgColor.components
        
        let bgLum = 0.2126 * bg[0] + 0.7152 * bg[1] + 0.0722 * bg[2]
        let fgLum = 0.2126 * fg[0] + 0.7152 * fg[1] + 0.0722 * fg[2]
        
        let bgGreater = bgLum > fgLum
        let nom = bgGreater ? bgLum : fgLum
        let denom = bgGreater ? fgLum : bgLum
        let contrast = (nom + 0.05) / (denom + 0.05)
        return 1.6 < contrast
    }
    
}

extension NSImage {
    
    /**
     Get a `CGImage` from the NSImage
     */
    var cgImage: CGImage {
        let imageData = self.tiffRepresentation
        let source = CGImageSourceCreateWithData(imageData as! CFData, nil)
        let maskRef = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        
        return maskRef!
    }
    
    private func resizeForImageColors(newSize: CGSize) -> NSImage {
        let temp = NSImage(size: newSize)
        
        temp.lockFocus()
        
        self.draw(in: NSMakeRect(0, 0, temp.size.width, temp.size.height))
        
        temp.unlockFocus()
        
        let cgImage = temp.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let bitmapImage = NSBitmapImageRep(cgImage: cgImage!)
        
        let result = NSImage(size: newSize)
        result.addRepresentation(bitmapImage)
        
        return result
    }
    
    /**
     Get `ImageColors` from the image asynchronously (in background thread).
     Discussion: Use smaller sizes for better performance at the cost of quality colors. Use larger sizes for better color sampling and quality at the cost of performance.
     
     - parameter scaleDownSize:     Downscale size of image for sampling, if `CGSize.zero` is provided, the sample image is rescaled to a width of 250px and the aspect ratio height.
     - parameter completionHandler: `ImageColors` for this image.
     */
    public func getColors(scaleDownSize: CGSize = CGSize.zero, completionHandler: @escaping (ImageColors) -> Void) {
        DispatchQueue.global().async {
            let result = self.getColors(scaleDownSize: scaleDownSize)
            
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }
    
    /**
     Get `ImageColors` from the image synchronously (in main thread).
     Discussion: Use smaller sizes for better performance at the cost of quality colors. Use larger sizes for better color sampling and quality at the cost of performance.
     
     - parameter scaleDownSize: Downscale size of image for sampling, if `CGSize.zero` is provided, the sample image is rescaled to a width of 250px and the aspect ratio height.
     
     - returns: `ImageColors` for this image.
     */
    public func getColors(scaleDownSize: CGSize = CGSize.zero) -> ImageColors {
        
        var scaleDownSize = scaleDownSize
        
        if scaleDownSize == CGSize.zero {
            let ratio = self.size.width/self.size.height
            let r_width: CGFloat = 250
            scaleDownSize = CGSize(width: r_width, height: r_width/ratio)
        }
        
        var result = ImageColors()
        
        let image = self.resizeForImageColors(newSize: scaleDownSize)
        
        let cgImage = image.cgImage
        let width = cgImage.width
        let height = cgImage.height
        
        let bytesPerPixel: Int = 4
        let bytesPerRow: Int = width * bytesPerPixel
        let bitsPerComponent: Int = 8
        let randomColorsThreshold = Int(CGFloat(height)*0.01)
        let sortedColorComparator: Comparator = { (main, other) -> ComparisonResult in
            let m = main as! PCCountedColor, o = other as! PCCountedColor
            if m.count < o.count {
                return ComparisonResult.orderedDescending
            } else if m.count == o.count {
                return ComparisonResult.orderedSame
            } else {
                return ComparisonResult.orderedAscending
            }
        }
        let blackColor = NSColor(red: 0, green: 0, blue: 0, alpha: 1)
        let whiteColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let raw = malloc(bytesPerRow * height)
        defer {
            free(raw)
        }
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(data: raw, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            fatalError("ImageColors.getColors failed: could not create CGBitmapContext")
        }
        let drawingRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        ctx.draw(cgImage, in: drawingRect)
        
        let data = ctx.data?.assumingMemoryBound(to: UInt8.self)
        
        let leftEdgeColors = NSCountedSet(capacity: height)
        let imageColors = NSCountedSet(capacity: width * height)
        
        for x in 0..<width {
            for y in 0..<height {
                let pixel = ((width * y) + x) * bytesPerPixel
                let color = NSColor(
                    red: CGFloat((data?[pixel+1])!)/255,
                    green: CGFloat((data?[pixel+2])!)/255,
                    blue: CGFloat((data?[pixel+3])!)/255,
                    alpha: 1
                )
                
                // A lot of images have white or black edges from crops, so ignore the first few pixels
                if 5 <= x && x <= 10 {
                    leftEdgeColors.add(color)
                }
                
                imageColors.add(color)
            }
        }
        
        // Get background color
        var enumerator = leftEdgeColors.objectEnumerator()
        var sortedColors = NSMutableArray(capacity: leftEdgeColors.count)
        while let kolor = enumerator.nextObject() as? NSColor {
            let colorCount = leftEdgeColors.count(for: kolor)
            if randomColorsThreshold < colorCount  {
                sortedColors.add(PCCountedColor(color: kolor, count: colorCount))
            }
        }
        sortedColors.sort(comparator: sortedColorComparator)
        
        var proposedEdgeColor: PCCountedColor
        if 0 < sortedColors.count {
            proposedEdgeColor = sortedColors.object(at: 0) as! PCCountedColor
        } else {
            proposedEdgeColor = PCCountedColor(color: blackColor, count: 1)
        }
        
        if proposedEdgeColor.color.isBlackOrWhite && 0 < sortedColors.count {
            for i in 1..<sortedColors.count {
                let nextProposedEdgeColor = sortedColors.object(at: i) as! PCCountedColor
                if (CGFloat(nextProposedEdgeColor.count)/CGFloat(proposedEdgeColor.count)) > 0.3 {
                    if !nextProposedEdgeColor.color.isBlackOrWhite {
                        proposedEdgeColor = nextProposedEdgeColor
                        break
                    }
                } else {
                    break
                }
            }
        }
        result.background = proposedEdgeColor.color
        
        // Get foreground colors
        enumerator = imageColors.objectEnumerator()
        sortedColors.removeAllObjects()
        sortedColors = NSMutableArray(capacity: imageColors.count)
        let findDarkTextColor = !result.background.isDarkColor
        
        while var kolor = enumerator.nextObject() as? NSColor {
            kolor = kolor.colorWithMinimumSaturation(minSaturation: 0.15)
            if kolor.isDarkColor == findDarkTextColor {
                let colorCount = imageColors.count(for: kolor)
                sortedColors.add(PCCountedColor(color: kolor, count: colorCount))
            }
        }
        sortedColors.sort(comparator: sortedColorComparator)
        
        for curContainer in sortedColors {
            let kolor = (curContainer as! PCCountedColor).color
            
            if result.primary == nil {
                if kolor.isContrastingColor(compareColor: result.background) {
                    result.primary = kolor
                }
            } else if result.secondary == nil {
                if !result.primary.isDistinct(compareColor: kolor) || !kolor.isContrastingColor(compareColor: result.background) {
                    continue
                }
                
                result.secondary = kolor
            } else if result.detail == nil {
                if !result.secondary.isDistinct(compareColor: kolor) || !result.primary.isDistinct(compareColor: kolor) || !kolor.isContrastingColor(compareColor: result.background) {
                    continue
                }
                
                result.detail = kolor
                break
            }
        }
        
        let isDarkBackgound = result.background.isDarkColor
        
        if result.primary == nil {
            result.primary = isDarkBackgound ? whiteColor:blackColor
        }
        
        if result.secondary == nil {
            result.secondary = isDarkBackgound ? whiteColor:blackColor
        }
        
        if result.detail == nil {
            result.detail = isDarkBackgound ? whiteColor:blackColor
        }
        
        return result
    }
    
    /**
     Get current image's `ImageColors` as a handy var
     */
    public var colors: ImageColors {
        return getColors()
    }
    
}

