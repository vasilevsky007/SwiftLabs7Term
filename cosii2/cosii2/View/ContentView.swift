//
//  ContentView.swift
//  cosii1
//
//  Created by Alex on 27.09.23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: Cosii1AppSwiftUI
    
    @State var fileURL: URL?
    @State var currentError: LocalizedError?
    @State var errorShown = false
    
    @State private var gmin: Float = 0
    @State private var gmax: Float = 155
    @State private var fmin: Float = 100
    @State private var fmax: Float = 181
    @State private var thresfold: Float = 340
    @State private var minPixelsInArea: Float = 200
    @State private var numberOfClusters: Float = 6
    
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
                                    .foregroundColor(.red)
                            }
                    }
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
                                    Text(String(Int(app.outputImage!.size.width)) + " x " + String(Int(app.outputImage!.size.height))).foregroundColor(.red)
                                }
                        }
                    }
                }
                
                VStack {
                    if app.binaryImage != nil {
                        VStack {
                            HStack {
                                Text("Бинарное изображение").frame(height: 30, alignment: .center)
//                                Button ("Сохранить") {
//                                    do {
//                                        try app.saveImage(to: fileURL)
//                                    } catch {
//                                        withAnimation {
//                                            currentError = error as? LocalizedError
//                                            errorShown = true
//                                        }
//                                    }
//                                }
                            }
                            Image(nsImage: app.binaryImage!)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
                                .overlay(alignment: .topTrailing) {
                                    Text(String(Int(app.binaryImage!.size.width)) + " x " + String(Int(app.binaryImage!.size.height))).foregroundColor(.red)
                                }
                                .overlay(alignment: .topLeading) {
                                    ZStack(alignment: .topLeading) {
                                        ForEach(app.model.binaryRepresentation!.areasProperties) { area in
                                            Text(String(app.model.binaryRepresentation!.areasProperties.firstIndex(where: {
                                                $0.id == area.id
                                            })!))
                                                .foregroundColor(.white)
                                                .padding(.top, area.centerOfMassY)
                                                .padding(.leading, area.centerOfMassX)
                                        }
                                    }
                                }
                        }
                    }
                }
                if app.model.binaryRepresentation != nil {
                    if app.model.binaryRepresentation!.areasProperties.count != 0 {
                        ScrollView {
                            Text("Свойства объектов").font(.title)
                            ForEach(app.model.binaryRepresentation!.areasProperties) { area in
                                DisclosureGroup {
                                    VStack(alignment: .leading) {
                                        Text("Площадь: \(area.figureArea)")
                                        Text("Периметр: \(area.perimeter)")
                                        Text("Центр Масс X: \(area.centerOfMassX) Y: \(area.centerOfMassY)")
                                        Text("Компактность: \(area.compactness)")
                                        Text("Вытянутость: \(area.elongation)")
                                        Text("M02: \(area.m02)")
                                        Text("M20: \(area.m20)")
                                        Text("M11: \(area.m11)")
                                    }
                                } label: {
                                    Text(String(app.model.binaryRepresentation!.areasProperties.firstIndex(where: { $0.id == area.id })!)).font(.headline)
                                }
                            }
                            if (app.model.clusters != nil){
                                Text("Кластеры").font(.title)
                                ForEach(Array(app.model.clusters!.keys), id: \.self) { cluster in
                                    DisclosureGroup {
                                        Text(app.model.clusters![cluster]!.description)
                                    } label: {
                                        Text(cluster.description)
                                    }
                                }
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
                        }
                    }
                    Button("Фильтр Min") {
                        Task (priority: .userInitiated) {
                            await app.applyFilterMin()
                        }
                    }
                    Button("Фильтр Max") {
                        Task (priority: .userInitiated) {
                            await app.applyFilterMax()
                        }
                    }
                    Button("Фильтр Min-Max") {
                        Task (priority: .userInitiated) {
                            await app.applyFilterMinMax()
                        }
                    }
                }
                
                VStack {
                    Text("Пороговая яркость пикселя:")
                    Slider(value: $thresfold, in: 0...765)
                    Text("\(thresfold)")
                    Button("Конвертировать в бинарное") {
                        Task (priority: .userInitiated) {
                            await app.transformToBinary(thresholdLevel: thresfold)
                        }
                    }
                }  
                
                VStack {
                    Text("Количество пикселей в области:")
                    Slider(value: $minPixelsInArea, in: 0...2000)
                    HStack {
                        if (app.isProcessingAreas){
                            ProgressView()
                        }
                        Text("\(minPixelsInArea)")
                    }
                    Button("выделить области") {
                        Task (priority: .userInitiated) {
                            await app.identifyAreas(minPixelsInArea: Int(minPixelsInArea))
                        }
                    }
                    HStack {
                        Text("\(numberOfClusters)")
                        Slider(value: $numberOfClusters, in: 0...14)
                    }
                    Button("выделить кластеры") {
                        Task (priority: .userInitiated) {
                            await app.identifyClusters(numberOfClusters: Int(numberOfClusters))
                        }
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

#Preview {
    ContentView()
        .environmentObject(Cosii1AppSwiftUI())
}
