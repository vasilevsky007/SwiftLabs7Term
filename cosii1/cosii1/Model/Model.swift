//
//  Model.swift
//  cosii1
//
//  Created by Alex on 27.09.23.
//

import Foundation

struct Model {
    var sourceFileData: Data?
    var outputFileData: Data?
    var sourcePixelArray: [Pixel]?
    
    struct Brightnesses {
        //value:count
        var R: [Int:Int] = [:]
        var G: [Int:Int] = [:]
        var B: [Int:Int] = [:]
        
        init() {
            self.R = [:]
            self.G = [:]
            self.B = [:]
            for i in 0...255 {
                self.R.updateValue(0, forKey: i)
                self.G.updateValue(0, forKey: i)
                self.B.updateValue(0, forKey: i)
            }
        }
        mutating func clearAllLevels() {
            for i in 0...255 {
                self.R.updateValue(0, forKey: i)
                self.G.updateValue(0, forKey: i)
                self.B.updateValue(0, forKey: i)
            }
        }
    }
    var inputBrignesses = Brightnesses()
    var outputBrignesses = Brightnesses()
}
