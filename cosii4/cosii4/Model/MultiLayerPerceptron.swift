//
//  MultiLayerPerceptron.swift
//  cosii4
//
//  Created by Alex on 18.10.23.
//

import Foundation

// Класс для реализации многослойного персептрона
class MultilayerPerceptron: Codable {
    let inputSize: Int
    let hiddenSize: Int
    let outputSize: Int
    let learningRate: Double
    let epochs: Int
    
    var hiddenWeights: [[Double]]
    var outputWeights: [[Double]]
    
    init(inputSize: Int, hiddenSize: Int, outputSize: Int, learningRate: Double, epochs: Int) {
        self.inputSize = inputSize
        self.hiddenSize = hiddenSize
        self.outputSize = outputSize
        self.learningRate = learningRate
        self.epochs = epochs
        self.hiddenWeights = Array(repeating: Array(repeating: 0.0, count: hiddenSize), count: inputSize)
        self.outputWeights = Array(repeating: Array(repeating: 0.0, count: outputSize), count: hiddenSize)
        
        // Инициализируем веса случайными значениями
        for i in 0..<hiddenWeights.count {
            for j in 0..<hiddenWeights[i].count {
                hiddenWeights[i][j] = Double.random(in: -1...1)
            }
        }
        
        for i in 0..<outputWeights.count {
            for j in 0..<outputWeights[i].count {
                outputWeights[i][j] = Double.random(in: -1...1)
            }
        }
    }
    
    func sigmoid(_ x: Double) -> Double {
        return 1.0 / (1.0 + exp(-x))
    }
    
    func sigmoidDerivative(_ x: Double) -> Double {
        let fx = sigmoid(x)
        return fx * (1.0 - fx)
    }
    
    func train(inputData: [[Double]], targetData: [[Double]], updateEpochs: (_ epoch: Int, _ error: Double) -> Void) {
        for epoch in 0..<epochs {
            var totalError = 0.0
            for i in 0..<inputData.count {
                let input = inputData[i]
                let target = targetData[i]
                // Forward propagation
                var hiddenOutput = [Double](repeating: 0.0, count: hiddenSize)
                var finalOutput = [Double](repeating: 0.0, count: outputSize)
                
                for j in 0..<hiddenSize {
                    hiddenOutput[j] = sigmoid(
                        zip(input, hiddenWeights.map { $0[j] })
                            .map { $0 * $1 }
                            .reduce(0, +)
                    )
                }
                
                for j in 0..<outputSize {
                    finalOutput[j] = sigmoid(
                        zip(hiddenOutput, outputWeights.map { $0[j] })
                            .map { $0 * $1 }
                            .reduce(0, +)
                    )
                }
                
                // Backpropagation
                var outputError = [Double](repeating: 0.0, count: outputSize)
                var hiddenError = [Double](repeating: 0.0, count: hiddenSize)
                
                for j in 0..<outputSize {
                    outputError[j] = target[j] - finalOutput[j]
                    totalError += 0.5 * (outputError[j] * outputError[j])
                }
                
                for j in 0..<hiddenSize {
                    hiddenError[j] = zip(outputWeights[j], outputError)
                        .map { $0 * $1 }
                        .reduce(0, +)
                }
                
                for j in 0..<outputSize {
                    let delta = outputError[j] * sigmoidDerivative(finalOutput[j])
                    for k in 0..<hiddenSize {
                        outputWeights[k][j] += learningRate * delta * hiddenOutput[k]
                    }
                }
                
                for j in 0..<hiddenSize {
                    let delta = hiddenError[j] * sigmoidDerivative(hiddenOutput[j])
                    for k in 0..<inputSize {
                        hiddenWeights[k][j] += learningRate * delta * input[k]
                    }
                }
            }
            updateEpochs(epoch + 1, totalError / Double(inputData.count))
        }
    }
    
    func predict(input: [Double]) -> [Double] {
        var hiddenOutput = [Double](repeating: 0.0, count: hiddenSize)
        var finalOutput = [Double](repeating: 0.0, count: outputSize)
        
        for j in 0..<hiddenSize {
            hiddenOutput[j] = sigmoid(
                zip(input, hiddenWeights.map { $0[j] })
                    .map { $0 * $1 }
                    .reduce(0, +)
            )
        }
        
        for j in 0..<outputSize {
            finalOutput[j] = sigmoid(
                zip(hiddenOutput, outputWeights.map { $0[j] })
                    .map { $0 * $1 }
                    .reduce(0, +)
            )
        }
        
        return finalOutput
    }
}
