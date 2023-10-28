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
    var binaryOutputFileData: Data?
    var isProcessingAreas = false
    var clusters: [[Double]:[Int]]?
    
    var binaryRepresentation: BinaryImage?
}
