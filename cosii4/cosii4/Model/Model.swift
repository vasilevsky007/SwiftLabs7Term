//
//  Model.swift
//  cosii4
//
//  Created by Alex on 18.10.23.
//

import Foundation

struct Model: Codable {
    var isLearning = false
    
    var currentError = 0.0
    var currentEpoch = 0
    
    struct Epoch: Identifiable, Codable {
        let id: Int
        let error: Double
    }
    
    var epochs: [Epoch] = []
    
    var inputs: [BinaryImage] = []
    var targets: [[Double]] = []
    
    var mlp = MultilayerPerceptron(inputSize: 36, hiddenSize: 64, outputSize: 5, learningRate: 0.1, epochs: 100)
    
    mutating func clear() {
        self.isLearning = false
        self.currentEpoch = 0
        self.currentError = 0.0
        
        self.inputs = []
        self.targets = []
        self.epochs = []
        
    }
}

