//
//  BinaryImage.swift
//  cosii4
//
//  Created by Alex on 18.10.23.
//

import Foundation

struct BinaryImage: Codable {
    let width: Int
    let height: Int
    private(set) var data: [BinaryPixel]
    
    init(width: Int = 6, height: Int = 6, data: [Bool]? = nil) {
        self.width = width
        self.height = height
        self.data = []
        for i in 0..<width*height {
            if let dataUnwrapped = data {
                self.data.append(BinaryPixel(id: i, value: dataUnwrapped[i]))
            } else {
                self.data.append(BinaryPixel(id: i, value: false))
            }
        }
    }
    
    mutating func togglePixel(id: Int) {
        data[id].value.toggle()
    }
}

struct BinaryPixel: Identifiable, Codable {
    let id: Int
    var value: Bool
}
