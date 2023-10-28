//
//  ContentView.swift
//  cosii1
//
//  Created by Alex on 27.09.23.
//

import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var app: Cosii1AppSwiftUI
    
    @State var fileURL: URL?
    @State var currentError: LocalizedError?
    @State var errorShown = false
    
    @State private var gmin: Float = 0
    @State private var gmax: Float = 255
    @State private var fmin: Float = 0
    @State private var fmax: Float = 255
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack {
                        Text("Выбор файла для загрузки")
                        Menu(fileURL?.absoluteString ?? "Файл не выбран") {
                            Button("Выбрать файл") {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                if panel.runModal() == .OK {
                                    self.fileURL = panel.url
                                } else {
                                    fileURL = nil
                                }
                            }
                        }
                        Button("Открыть") {
                            do {
                                try app.loadImage(from: fileURL)
                            } catch {
                                withAnimation {
                                    currentError = error as? LocalizedError
                                    errorShown = true
                                }
                            }
                        }
                    }.frame(height: 30, alignment: .center)
                    if (app.inputImage != nil) {
                        Image(nsImage: app.inputImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .overlay(alignment: .topTrailing) {
                                Text(String(Int(app.inputImage!.size.width)) + " x " + String(Int(app.inputImage!.size.height)))
                                    .foregroundColor(.black)
                            }
                        Chart {
                            ForEach(app.model.inputBrignesses.R.sorted(by: >), id: \.key) { brigtness, count in
                                LineMark(
                                    x: .value("brigtness", brigtness),
                                    y: .value("count R", count),
                                    series: .value("Channel", "R")
                                )
                                .foregroundStyle(.red)
                            }
                            ForEach(app.model.inputBrignesses.G.sorted(by: >), id: \.key) { brigtness, count in
                                LineMark(
                                    x: .value("brigtness", brigtness),
                                    y: .value("count G", count),
                                    series: .value("Channel", "G")
                                )
                                .foregroundStyle(.green)
                            }
                            ForEach(app.model.inputBrignesses.B.sorted(by: >), id: \.key) { brigtness, count in
                                LineMark(
                                    x: .value("brigtness", brigtness),
                                    y: .value("count B", count),
                                    series: .value("Channel", "B")
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                VStack {
                    if app.outputImage != nil {
                        VStack {
                            HStack {
                                Text("Выходное изображение").frame(height: 30, alignment: .center)
                                Button ("Сохранить") {
                                    do {
                                        try app.saveImage(to: fileURL)
                                    } catch {
                                        withAnimation {
                                            currentError = error as? LocalizedError
                                            errorShown = true
                                        }
                                    }
                                }
                            }
                            Image(nsImage: app.outputImage!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .overlay(alignment: .topTrailing) {
                                    Text(String(Int(app.outputImage!.size.width)) + " x " + String(Int(app.outputImage!.size.height))).foregroundColor(.black)
                                }
                        }
                        Chart {
                            ForEach(app.model.outputBrignesses.R.sorted(by: >), id: \.key) { brigtness, count in
                                LineMark(
                                    x: .value("brigtness", brigtness),
                                    y: .value("count R", count),
                                    series: .value("Channel", "R")
                                )
                                .foregroundStyle(.red)
                            }
                            ForEach(app.model.outputBrignesses.G.sorted(by: >), id: \.key) { brigtness, count in
                                LineMark(
                                    x: .value("brigtness", brigtness),
                                    y: .value("count G", count),
                                    series: .value("Channel", "G")
                                )
                                .foregroundStyle(.green)
                            }
                            ForEach(app.model.outputBrignesses.B.sorted(by: >), id: \.key) { brigtness, count in
                                LineMark(
                                    x: .value("brigtness", brigtness),
                                    y: .value("count B", count),
                                    series: .value("Channel", "B")
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            Divider()
            HStack {
                Text("Параметры:")
                VStack {
                    Text("gmin:")
                    Slider(value: $gmin, in: 0...255)
                    Text("\(gmin)")
                }
                
                VStack {
                    Text("gmax:")
                    Slider(value: $gmax, in: 0...255)
                    Text("\(gmax)")
                }
                
                VStack {
                    Text("fmin:")
                    Slider(value: $fmin, in: 0...255)
                    Text("\(fmin)")
                }
                
                VStack {
                    Text("fmax:")
                    Slider(value: $fmax, in: 0...255)
                    Text("\(fmax)")
                }
                VStack {
                    Button("Обработать") {
                        Task (priority: .userInitiated) {
                            await app.applyProcessing(gmin: gmin, gmax: gmax, fmin: fmin, fmax: fmax)
                            await app.prepareBrigtnessLevels(isPreparingInput: false)
                        }
                    }
                    Button("Фильтр Min") {
                        Task (priority: .userInitiated) {
                            await app.applyFilterMin()
                            await app.prepareBrigtnessLevels(isPreparingInput: false)
                        }
                    }
                    Button("Фильтр Max") {
                        Task (priority: .userInitiated) {
                            await app.applyFilterMax()
                            await app.prepareBrigtnessLevels(isPreparingInput: false)
                        }
                    }
                    Button("Фильтр Min-Max") {
                        Task (priority: .userInitiated) {
                            await app.applyFilterMinMax()
                            await app.prepareBrigtnessLevels(isPreparingInput: false)
                        }
                    }
                }
                .alert(isPresented: $errorShown, error: LocalizedAlertError(error: currentError)) {
                    Button("OK") {
                        errorShown = false
                    }
                }
                
            }
        }

    }
}

#Preview {
    ContentView()
        .environmentObject(Cosii1AppSwiftUI())
}
