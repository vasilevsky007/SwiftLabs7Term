//
//  Image.swift
//  cosii2
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
    
    func binaryRepresentation (thresholdLevel: Int) -> Bool {
        return (Int(self.r) + Int(self.g) + Int(self.b)) > thresholdLevel
    }
}

struct BinaryImage {
    
    struct AreaProperties: Identifiable, Hashable {
        var id = UUID()
        var figureArea: Int
        var perimeter: Int
        var centerOfMassX: Double
        var centerOfMassY: Double
        var compactness: Double
        var elongation: Double
        var m02: Double
        var m20:Double
        var m11:Double
    }
    let width: Int
    let height: Int
    var data: [Bool]
    var areasProperties: [AreaProperties]
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.data = Array(repeating: false, count: width * height)
        self.areasProperties = []
    }
    
    func indexFor(x: Int, y: Int) -> Int {
        return y * width + x
    }
    
    func isPixelInRange(x: Int, y: Int) -> Bool {
        return x >= 0 && x < width && y >= 0 && y < height
    }
    
    func findConnectedComponents() -> [[(x: Int, y: Int)]] {
        var visited = Array(repeating: false, count: width * height)
        var components: [[(x: Int, y: Int)]] = []
        
        for y in 0..<height {
            for x in 0..<width {
                let currentIndex = indexFor(x: x, y: y)
                
                if !visited[currentIndex] && data[currentIndex] {
                    var currentComponent: [(x: Int, y: Int)] = []
                    var queue: [(x: Int, y: Int)] = [(x, y)]
                    
                    while !queue.isEmpty {
                        let (currentX, currentY) = queue.removeFirst()
                        let currentIndex = indexFor(x: currentX, y: currentY)
                        
                        if !visited[currentIndex] && data[currentIndex] {
                            visited[currentIndex] = true
                            currentComponent.append((currentX, currentY))
                            
                            // Проверяем соседние пиксели
                            for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                                let nextX = currentX + dx
                                let nextY = currentY + dy
                                
                                if isPixelInRange(x: nextX, y: nextY) {
                                    let nextIndex = indexFor(x: nextX, y: nextY)
                                    if !visited[nextIndex] && data[nextIndex] {
                                        queue.append((nextX, nextY))
                                    }
                                }
                            }
                        }
                    }
                    
                    if !currentComponent.isEmpty {
                        components.append(currentComponent)
                    }
                }
            }
        }
        
        return components
    }
    
}


