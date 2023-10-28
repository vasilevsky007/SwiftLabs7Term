//
//  Cosii4AppSwiftUI.swift
//  cosii4
//
//  Created by Alex on 18.10.23.
//

import SwiftUI

@MainActor class Cosii4AppSwiftUI: ObservableObject {
    @Published var model: Model
    
    var currentEpoch: Int {
        model.currentEpoch
    }
    var currentError: Double {
        model.currentError
    }
    var epochs: [Model.Epoch] {
        model.epochs
    }
    
    private func startLearning() {
        model.isLearning = true
    }
    private func endLearning() {
        model.isLearning = false
    }
    private func updateEpochs(epoch: Int, error: Double) {
        model.currentEpoch = epoch
        model.currentError = error
        model.epochs.append(.init(id: epoch, error: error))
    }
    
    
    
    init() {
        do {
            let fileUrl = try FileManager.default.url(for: .documentDirectory,
                                                      in: .allDomainsMask,
                                                      appropriateFor: nil,
                                                      create: true)
                .appendingPathComponent("COSII4_DATA", conformingTo: .directory)
                .appendingPathComponent("model.dat", conformingTo: .data)
            let data = try Data(contentsOf: fileUrl)
            self.model = try PropertyListDecoder().decode(Model.self, from: data)
        } catch {
            print("Ошибка при загрузке модели: \(error)")
            self.model = Model()
        }
    }
    
    func save() {
        do {
            let data = try PropertyListEncoder().encode(model)
            let fileUrl = try FileManager.default.url(for: .documentDirectory,
                                                      in: .allDomainsMask,
                                                      appropriateFor: nil,
                                                      create: true)
                .appendingPathComponent("COSII4_DATA", conformingTo: .directory)
                .appendingPathComponent("model.dat", conformingTo: .data)
            try data.write(to: fileUrl)
            print("Модель успешно сохранена.")
        } catch {
            print("Ошибка при сохранении модели: \(error.localizedDescription)")
        }
    }
    
    func clearModel() {
        model.clear()
    }
    
    func addSample(_ image: BinaryImage, selecledClass: Int) {
        model.inputs.append(image)
        var target = Array(repeating: 0.0, count: 5)
        target[selecledClass] = 1.0
        model.targets.append(target)
    }

    
    //MARK: NEW ONE
    func train(hiddenSize: Double, learningRate: Double, epochs: Double) async {
        model.mlp = MultilayerPerceptron(inputSize: 36, hiddenSize: Int(hiddenSize), outputSize: 5, learningRate: learningRate, epochs: Int(epochs))
        model.epochs = []
        let inputData: [[Double]] = model.inputs.map { binaryImage in
            return binaryImage.data.map { binaryPixel in
                return binaryPixel.value ? 1.0 : 0.0
            }
        }
        let targetData: [[Double]] = model.targets
        startLearning()
        await Task.detached(priority: .high) {
            await self.model.mlp.train(inputData: inputData, targetData: targetData) { epoch ,error in
                Task (priority: .userInitiated) {
                    await self.updateEpochs(epoch: epoch, error: error)
                }
            }
        }.value
        endLearning()
    }
    
    func predict(image: BinaryImage) -> [Double]  {
        let input: [Double] = image.data.map { binaryPixel in
            binaryPixel.value ? 1.0 : 0.0
        }
        return model.mlp.predict(input: input)
    }
}
