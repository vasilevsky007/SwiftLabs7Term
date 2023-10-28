//
//  ContentView.swift
//  cosii4
//
//  Created by Alex on 18.10.23.
//

import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var app: Cosii4AppSwiftUI
    
    @State private var inputImage = BinaryImage()
    @State private var selectedClass = 0
    @State private var learningRate = 0.1
    @State private var epochs = 100.0
    @State private var hiddenCount = 10.0
    @State private var predictions: [Double]?
    
    var body: some View {
        VStack {
            Button("Очистить модель", role: .destructive) {
                Task(priority: .userInitiated) {
                    app.clearModel()
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 20, maximum: 1000)), count: 6), content: {
                ForEach(inputImage.data) { pixel in
                    Rectangle().aspectRatio(1, contentMode: .fit)
                        .foregroundColor(pixel.value ? .black : .white)
                        .onTapGesture {
                            inputImage.togglePixel(id: pixel.id)
                        }
                }
                
            })
            Picker(selection: $selectedClass) {
                Text("L").tag(0)
                Text("U").tag(1)
                Text("T").tag(2)
                Text("O").tag(3)
                Text("K").tag(4)
            } label: {
                Text("Класс: ")
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            Button("Добавить сэмпл") {
                Task(priority: .userInitiated) {
                    app.addSample(inputImage, selecledClass: selectedClass)
                }
            }
            Text("cила обучения")
            Slider(value: $learningRate, in: 0.0...1.0) {
                Text("\(learningRate)")
            }
            
            Text("количество скрытых нейронов")
            Slider(
                    value: $hiddenCount,
                    in: 0...256,
                    step: 1
                ) {
                    TextField("100", value: $hiddenCount, formatter: NumberFormatter()).frame(width: 100)
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("256")
                }
            Text("количество поколений")
            Slider(
                    value: $epochs,
                    in: 0...10000,
                    step: 10
                ) {
                    TextField("100", value: $epochs, formatter: NumberFormatter()).frame(width: 100)
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("10000")
                }
            HStack {
                Button{
                    Task {
                        await app.train(hiddenSize: hiddenCount, learningRate: learningRate, epochs: epochs)
                        print(app.model.mlp)
                    }
                } label: {
                    HStack {
                        if app.model.isLearning{
                            ProgressView()
                        }
                        Text("Обучить МЛП")
                    }
                }
                
                Text("Текущее поколение: \(app.currentEpoch) Текущая ошибка: \(app.currentError)")
            }
            HStack {
                Button("Распознать образ") {
                    Task(priority: .userInitiated) {
                        predictions = app.predict(image: inputImage)
                    }
                }
                if let predictionsUnwrapped = predictions {
                    Text("L: \(predictionsUnwrapped[0]*100)% U: \(predictionsUnwrapped[1]*100)% T: \(predictionsUnwrapped[2]*100)% O: \(predictionsUnwrapped[3]*100)% K: \(predictionsUnwrapped[4]*100)%")
                }
            }
            if (!app.epochs.isEmpty) {
                Text("ошибка от поколения")
                Chart(app.epochs) { epoch in
                    LineMark (
                        x: .value("Epoch", epoch.id),
                        y: .value("Error", epoch.error)
                    )
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(Cosii4AppSwiftUI())
}
