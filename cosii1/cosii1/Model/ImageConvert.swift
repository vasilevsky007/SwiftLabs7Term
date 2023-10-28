//
//  RGBImage.swift
//  cosii1
//
//  Created by Alex on 27.09.23.
//

import Foundation
import AppKit

struct Pixel {
    var r: UInt8
    var g: UInt8
    var b: UInt8

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
}

extension NSImage {
    func pixelData() -> [Pixel] {
        let bmp = self.representations[0] as! NSBitmapImageRep
        var data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
        var r, g, b, a: UInt8
        var pixels: [Pixel] = []
        
        NSLog("%d", bmp.pixelsHigh)
        NSLog("%d", bmp.pixelsWide)
        for var row in 0..<bmp.pixelsHigh {
            for var col in 0..<bmp.pixelsWide {
                r = data.pointee
                data = data.advanced(by: 1)
                g = data.pointee
                data =  data.advanced(by: 1)
                b = data.pointee
                data =  data.advanced(by: 1)
                a = data.pointee
                data =  data.advanced(by: 1)
                pixels.append(Pixel(r: r, g: g, b: b, a: a))
            }
        }
        return pixels
    }
}

