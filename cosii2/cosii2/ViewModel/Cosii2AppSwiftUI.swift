//
//  ViewModel.swift
//  cosii1
//
//  Created by Alex on 27.09.23.
//

import SwiftUI
//import Algorithms

@MainActor class Cosii1AppSwiftUI: ObservableObject {
    @Published private(set) var model = Model()
    
    func changeBinaryPixel(pixelOffset: Int, value: Bool) {
        model.binaryRepresentation?.data[pixelOffset] = value
    }
    
    var isProcessingAreas: Bool {
        return model.isProcessingAreas
    }
    
    var inputImage: NSImage? {
        if let data = model.sourceFileData {
            NSImage(data: data)
        } else {
            nil
        }
    }
    
    var outputImage: NSImage? {
        if let data = model.outputFileData {
            NSImage(data: data)
        } else {
            nil
        }
    }
    
    var binaryImage: NSImage? {
        if let data = model.binaryOutputFileData {
            NSImage(data: data)
        } else {
            nil
        }
    }
    
    func loadImage(from url: URL?) throws {
        if url != nil {
            try withAnimation {
                try model.sourceFileData = Data(contentsOf: url!)
            }
        }
        else {
            throw MyError.openNilURL
        }
    }
    
    func saveImage(to url: URL?) throws {
        if let unwrappedUrl = url {
            var changedUrl = unwrappedUrl.deletingPathExtension().absoluteString + "_edited.png"
            print(changedUrl)
            for _ in 0..<7 {
                changedUrl.removeFirst()
            }
            print (FileManager()
                .createFile(atPath: changedUrl, contents: model.outputFileData))
        }
        else {
            throw MyError.openNilURL
        }
    }
    
    func applyProcessing(gmin: Float, gmax: Float, fmin: Float, fmax: Float) async {
        guard let inputImage = self.inputImage else { return }
        if let tiffData = inputImage.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffData) {
            // Получение данных пикселей
            let width = bitmap.pixelsWide
            let height = bitmap.pixelsHigh
            let bytesPerRow = bitmap.bytesPerRow
            let bitsPerPixel = bitmap.bitsPerPixel
            let bytesPerPixel = bitsPerPixel / 8
            
            guard let pixelData = bitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            
            // Применение преобразования к каждому пикселю
            await withTaskGroup(of: Void.self) { group in
                for x in 0..<width {
                    group.addTask {
                        for y in 0..<height {
                            let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
                            
                            // Разбор компонентов цвета (RGBA)
                            let red = Float(pixelData[pixelOffset + 0])
                            let newRed = (red - fmin) / (fmax - fmin) * (gmax - gmin) + gmin
                            pixelData[pixelOffset + 0] = UInt8(newRed > 255.0 ? 255.0 : (newRed > 0.0 ? newRed : 0.0)) // Красный
                            
                            let green = Float(pixelData[pixelOffset + 1])
                            let newGreen = (green - fmin) / (fmax - fmin) * (gmax - gmin) + gmin
                            pixelData[pixelOffset + 1] = UInt8(newGreen > 255.0 ? 255.0 : (newGreen > 0.0 ? newGreen : 0.0)) // Зеленый
                            
                            let blue = Float(pixelData[pixelOffset + 2])
                            let newBlue = (blue - fmin) / (fmax - fmin) * (gmax - gmin) + gmin
                            pixelData[pixelOffset + 2] = UInt8(newBlue > 255.0 ? 255.0 : (newBlue > 0.0 ? newBlue : 0.0)) // Синий
                            // pixelData[pixelOffset + 3] = newValue // Альфа (если нужно)
                            
                        }
                    
                    }
                }
            }
            
            // Извлечение PNGData из NSBitmapImageRep
            let pngData = bitmap.representation(using: .png, properties: [:])
            model.outputFileData = pngData
        } else { return }
    }
    
    func applyFilterMin() async {
        guard let inputImage = self.inputImage else { return }
        if let tiffData = inputImage.tiffRepresentation, let inputBitmap = NSBitmapImageRep(data: tiffData), let outputBitmap = NSBitmapImageRep(data: tiffData) {
            // Получение данных пикселей
            let width = inputBitmap.pixelsWide
            let height = inputBitmap.pixelsHigh
            let bytesPerRow = inputBitmap.bytesPerRow
            let bitsPerPixel = inputBitmap.bitsPerPixel
            let bytesPerPixel = bitsPerPixel / 8
            guard let pixelDataInput = inputBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            guard let pixelDataOutput = outputBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            
            // Применение min фильтра к каждому пикселю
            await withTaskGroup(of: Void.self) { group in
                for y in 0..<height {
                    group.addTask {
                        for x in 0..<width {
                            var minR: UInt8 = 255;
                            var minG: UInt8 = 255;
                            var minB: UInt8 = 255;
                            for dy in  -1...1 {
                                for dx in -1...1 {
                                    let newX = x + dx;
                                    let newY = y + dy;
                                    if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
                                        let pixelOffset = (newY * bytesPerRow) + (newX * bytesPerPixel)
                                        minR = min(minR, UInt8(pixelDataInput[pixelOffset + 0]));
                                        minG = min(minG, UInt8(pixelDataInput[pixelOffset + 1]));
                                        minB = min(minB, UInt8(pixelDataInput[pixelOffset + 2]));
                                    }
                                }
                            }
                            let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
                            pixelDataOutput[pixelOffset + 0] = UInt8(minR)
                            pixelDataOutput[pixelOffset + 1] = UInt8(minG)
                            pixelDataOutput[pixelOffset + 2] = UInt8(minB)
                        }
                    }
}
            }

            // Извлечение PNGData из NSBitmapImageRep
            let pngData = outputBitmap.representation(using: .png, properties: [:])
            model.outputFileData = pngData
            } else { return }
    }
    
    func applyFilterMax() async {
        guard let inputImage = self.inputImage else { return }
        if let tiffData = inputImage.tiffRepresentation, let inputBitmap = NSBitmapImageRep(data: tiffData), let outputBitmap = NSBitmapImageRep(data: tiffData) {
            // Получение данных пикселей
            let width = inputBitmap.pixelsWide
            let height = inputBitmap.pixelsHigh
            let bytesPerRow = inputBitmap.bytesPerRow
            let bitsPerPixel = inputBitmap.bitsPerPixel
            let bytesPerPixel = bitsPerPixel / 8
            guard let pixelDataInput = inputBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            guard let pixelDataOutput = outputBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            
            // Применение max фильтра к каждому пикселю
            await withTaskGroup(of: Void.self) { group in
                for y in 0..<height {
                    group.addTask {
                        for x in 0..<width {
                            var minR: UInt8 = 0;
                            var minG: UInt8 = 0;
                            var minB: UInt8 = 0;
                            for dy in  -1...1 {
                                for dx in -1...1 {
                                    let newX = x + dx;
                                    let newY = y + dy;
                                    if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
                                        let pixelOffset = (newY * bytesPerRow) + (newX * bytesPerPixel)
                                        minR = max(minR, UInt8(pixelDataInput[pixelOffset + 0]));
                                        minG = max(minG, UInt8(pixelDataInput[pixelOffset + 1]));
                                        minB = max(minB, UInt8(pixelDataInput[pixelOffset + 2]));
                                    }
                                }
                            }
                            let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
                            pixelDataOutput[pixelOffset + 0] = UInt8(minR)
                            pixelDataOutput[pixelOffset + 1] = UInt8(minG)
                            pixelDataOutput[pixelOffset + 2] = UInt8(minB)
                        }
                    }
                }
            }
            
            // Извлечение PNGData из NSBitmapImageRep
            let pngData = outputBitmap.representation(using: .png, properties: [:])
            model.outputFileData = pngData
            } else { return }
    }
    
    func applyFilterMinMax() async {
        guard let inputImage = self.inputImage else { return }
        let processedImageAfterMin: NSImage
        if let tiffData = inputImage.tiffRepresentation, let inputBitmap = NSBitmapImageRep(data: tiffData), let outputBitmap = NSBitmapImageRep(data: tiffData) {
            // Получение данных пикселей
            let width = inputBitmap.pixelsWide
            let height = inputBitmap.pixelsHigh
            let bytesPerRow = inputBitmap.bytesPerRow
            let bitsPerPixel = inputBitmap.bitsPerPixel
            let bytesPerPixel = bitsPerPixel / 8
            guard let pixelDataInput = inputBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            guard let pixelDataOutput = outputBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            
            // Применение min фильтра к каждому пикселю
            await withTaskGroup(of: Void.self) { group in
                for y in 0..<height {
                    group.addTask {
                        for x in 0..<width {
                            var minR: UInt8 = 255;
                            var minG: UInt8 = 255;
                            var minB: UInt8 = 255;
                            for dy in  -1...1 {
                                for dx in -1...1 {
                                    let newX = x + dx;
                                    let newY = y + dy;
                                    if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
                                        let pixelOffset = (newY * bytesPerRow) + (newX * bytesPerPixel)
                                        minR = min(minR, UInt8(pixelDataInput[pixelOffset + 0]));
                                        minG = min(minG, UInt8(pixelDataInput[pixelOffset + 1]));
                                        minB = min(minB, UInt8(pixelDataInput[pixelOffset + 2]));
                                    }
                                }
                            }
                            let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
                            pixelDataOutput[pixelOffset + 0] = UInt8(minR)
                            pixelDataOutput[pixelOffset + 1] = UInt8(minG)
                            pixelDataOutput[pixelOffset + 2] = UInt8(minB)
                        }
                    }
}
            }

            // Извлечение PNGData из NSBitmapImageRep
            let pngData = outputBitmap.representation(using: .png, properties: [:])
            processedImageAfterMin = NSImage(data: pngData!)!
            } else { return }
        

        if let tiffData = processedImageAfterMin.tiffRepresentation, let inputBitmap = NSBitmapImageRep(data: tiffData), let outputBitmap = NSBitmapImageRep(data: tiffData) {
            // Получение данных пикселей
            let width = inputBitmap.pixelsWide
            let height = inputBitmap.pixelsHigh
            let bytesPerRow = inputBitmap.bytesPerRow
            let bitsPerPixel = inputBitmap.bitsPerPixel
            let bytesPerPixel = bitsPerPixel / 8
            guard let pixelDataInput = inputBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            guard let pixelDataOutput = outputBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            
            // Применение max фильтра к каждому пикселю
            await withTaskGroup(of: Void.self) { group in
                for y in 0..<height {
                    group.addTask {
                        for x in 0..<width {
                            var minR: UInt8 = 0;
                            var minG: UInt8 = 0;
                            var minB: UInt8 = 0;
                            for dy in  -1...1 {
                                for dx in -1...1 {
                                    let newX = x + dx;
                                    let newY = y + dy;
                                    if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
                                        let pixelOffset = (newY * bytesPerRow) + (newX * bytesPerPixel)
                                        minR = max(minR, UInt8(pixelDataInput[pixelOffset + 0]));
                                        minG = max(minG, UInt8(pixelDataInput[pixelOffset + 1]));
                                        minB = max(minB, UInt8(pixelDataInput[pixelOffset + 2]));
                                    }
                                }
                            }
                            let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
                            pixelDataOutput[pixelOffset + 0] = UInt8(minR)
                            pixelDataOutput[pixelOffset + 1] = UInt8(minG)
                            pixelDataOutput[pixelOffset + 2] = UInt8(minB)
                        }
                    }
                }
            }
            
            // Извлечение PNGData из NSBitmapImageRep
            let pngData = outputBitmap.representation(using: .png, properties: [:])
            model.outputFileData = pngData
            } else { return }
    }
    
    func transformToBinary(thresholdLevel: Float) async {
        guard let inputImage = self.inputImage else { return }
        if let tiffData = inputImage.tiffRepresentation, let binaryBitmap = NSBitmapImageRep(data: tiffData), let bitmap = NSBitmapImageRep(data: tiffData) {
            // Получение данных пикселей
            let width = bitmap.pixelsWide
            let height = bitmap.pixelsHigh
            let bytesPerRow = bitmap.bytesPerRow
            let bitsPerPixel = bitmap.bitsPerPixel
            let bytesPerPixel = bitsPerPixel / 8
            guard let pixelData = bitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            guard let binaryPixelData = binaryBitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            
            model.binaryRepresentation = BinaryImage(width: width, height: height)
            
            // Применение преобразования к каждому пикселю
//            await withTaskGroup(of: Void.self) { group in
                for x in 0..<width {
//                    group.addTask {
                        var pixel = Pixel(r: 0, g: 0, b: 0, a: 0)
                        for y in 0..<height {
                            let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
                            let binaryPixelOffset = (y * width) + (x)
                            
                            // Разбор компонентов цвета (RGBA)
                            pixel.r = (pixelData[pixelOffset + 0])
                            pixel.g = (pixelData[pixelOffset + 1])
                            pixel.b = (pixelData[pixelOffset + 2])
//                            pixel.a = (pixelData[pixelOffset + 3]) // Альфа (если нужно)
                            let pixelvalue = pixel.binaryRepresentation(thresholdLevel: Int(thresholdLevel))
                            await self.changeBinaryPixel(pixelOffset: binaryPixelOffset, value: pixelvalue)
                            binaryPixelData[pixelOffset + 0] = pixelvalue ? 255 : 0
                            binaryPixelData[pixelOffset + 1] = pixelvalue ? 255 : 0
                            binaryPixelData[pixelOffset + 2] = pixelvalue ? 255 : 0
                        }
//                    }
                }
//            }
            
            // Извлечение PNGData из NSBitmapImageRep
            let pngData = binaryBitmap.representation(using: .png, properties: [:])
            model.binaryOutputFileData = pngData
        } else { return }
    }
    
    
    
    func identifyAreas(minPixelsInArea: Int) async {
        let colors:[Color] = [.blue, .brown, .cyan, .gray, .green, .indigo, .mint, .orange, .pink, .purple, .red, .teal, .yellow]
        var areas = model.binaryRepresentation?.findConnectedComponents().filter{ $0.count > minPixelsInArea }
        
        guard let areasUnwrapped = areas else { return }
        guard let inputImage = self.binaryImage else { return }
        if let tiffData = inputImage.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffData) {
            // Получение данных пикселей
            let width = bitmap.pixelsWide
            let height = bitmap.pixelsHigh
            let bytesPerRow = bitmap.bytesPerRow
            let bitsPerPixel = bitmap.bitsPerPixel
            let bytesPerPixel = bitsPerPixel / 8
            guard let pixelData = bitmap.bitmapData else {
                fatalError("Failed to get pixel data")
            }
            model.isProcessingAreas = true
            for x in 0..<width {
                for y in 0..<height {
                    let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
                    pixelData[pixelOffset + 0] = 0
                    pixelData[pixelOffset + 1] = 0
                    pixelData[pixelOffset + 2] = 0
                }
            }
            let areasProperties = await withTaskGroup(of: BinaryImage.AreaProperties.self, returning: [BinaryImage.AreaProperties].self) { group in
                var areasProperties = [BinaryImage.AreaProperties]()
                for area in areasUnwrapped {
                    group.addTask {
                        let colornumber = (areasUnwrapped.firstIndex { element in
                            element.elementsEqual(area) { a, b in
                                a.x == b.x && a.y == b.y
                            }
                        })! % colors.count
                        let redComponent = UInt8(255 * colors[colornumber].resolve(in: .init()).red)
                        let greenComponent = UInt8(255 * colors[colornumber].resolve(in: .init()).green)
                        let blueComponent = UInt8(255 * colors[colornumber].resolve(in: .init()).blue)
                        
                        var sumX = 0.0
                        var sumY = 0.0
                        var perimeter = 0
                        
                        for pixel in area {
                            sumX += Double(pixel.x)
                            sumY += Double(pixel.y)
                            let pixelOffset = (pixel.y * bytesPerRow) + (pixel.x * bytesPerPixel)
                            pixelData[pixelOffset + 0] = redComponent
                            pixelData[pixelOffset + 1] = greenComponent
                            pixelData[pixelOffset + 2] = blueComponent
                            
                            for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                                let newX = pixel.x + dx
                                let newY = pixel.y + dy
                                
                                if await self.model.binaryRepresentation!.isPixelInRange(x: newX, y: newY) && !area.contains(where: { (x: Int, y: Int) in
                                    x == newX && y == newY
                                }) {
                                    perimeter += 1
                                }
                            }
                            
                        }
                        let figureArea = area.count
                        let centerOfMass = (x: sumX / Double(area.count), y: sumY / Double(area.count))
                        let compactness = pow(Double(perimeter), 2) / Double(figureArea)
                        
                        
                        let centralMomentOfComponent = {(component: [(x: Int, y: Int)], xOrder: Int, yOrder: Int) -> Double in
                            var centralMoment = 0.0
                            for point in component {
                                let x = Double(point.x)
                                let y = Double(point.y)
                                centralMoment += pow(x - centerOfMass.x, Double(xOrder)) * pow(y - centerOfMass.y, Double(yOrder))
                            }
                            return centralMoment
                        }
                        
                        let m20: Double = centralMomentOfComponent(area, 2, 0)
                        let m02: Double = centralMomentOfComponent(area, 0, 2)
                        let m11: Double = centralMomentOfComponent(area, 1, 1)
                        
//                        let elongation = (m20 + m02 + 2 * m11) / (m20 + m02)
                        let elongation = (m20 + m02 + sqrt((m20 - m02) * (m20 - m02)) + 4 * m11 * m11) / (m20 + m02 - sqrt((m20 - m02) * (m20 - m02)) + 4 * m11 * m11)
                        
                        return BinaryImage.AreaProperties(
                            figureArea: figureArea,
                            perimeter: perimeter,
                            centerOfMassX: centerOfMass.x,
                            centerOfMassY: centerOfMass.y,
                            compactness: compactness,
                            elongation: elongation,
                            m02: m02,
                            m20: m20,
                            m11: m11)
                    }
                }
                for await properties in group {
                    areasProperties.append(properties)
                }
                return areasProperties
            }
            model.isProcessingAreas = false
            model.binaryRepresentation?.areasProperties = areasProperties
            let pngData = bitmap.representation(using: .png, properties: [:])
            model.binaryOutputFileData = pngData
        }
    }
    
    func identifyClusters(numberOfClusters: Int) async {
        // Реализация функции для вычисления Евклидового расстояния между двумя точками
        func euclideanDistance(_ a: [Double], _ b: [Double]) -> Double {
            precondition(a.count == b.count, "Векторы должны иметь одинаковую длину")
            var sum = 0.0
            for i in 0..<a.count {
                sum += (a[i] - b[i]) * (a[i] - b[i])
            }
            return sqrt(sum)
        }

        // Реализация метода локтя для выбора оптимального числа кластеров
        func elbowMethod(data: [[Double]], maxK: Int) -> Int {
            var distortions = [Double]()

            for k in 1...maxK {
                var centroids = data.prefix(k).map { $0 }
                var assignments = Array(repeating: 0, count: data.count)

                for _ in 0..<100 { // Максимальное количество итераций
                    var newCentroids = Array(repeating: Array(repeating: 0.0, count: data[0].count), count: k)
                    var clusterCounts = Array(repeating: 0, count: k)

                    for i in 0..<data.count {
                        var minDistance = Double.greatestFiniteMagnitude
                        var cluster = 0

                        for j in 0..<k {
                            let distance = euclideanDistance(data[i], centroids[j])
                            if distance < minDistance {
                                minDistance = distance
                                cluster = j
                            }
                        }

                        newCentroids[cluster] = zip(newCentroids[cluster], data[i]).map(+)
                        clusterCounts[cluster] += 1
                        assignments[i] = cluster
                    }

                    for j in 0..<k {
                        if clusterCounts[j] > 0 {
                            newCentroids[j] = newCentroids[j].map { $0 / Double(clusterCounts[j]) }
                        }
                    }

                    if centroids == newCentroids {
                        break
                    } else {
                        centroids = newCentroids
                    }
                }

                var distortion = 0.0
                for i in 0..<data.count {
                    distortion += pow(euclideanDistance(data[i], centroids[assignments[i]]), 2)
                }
                distortions.append(distortion)
            }

            // Выбор оптимального числа кластеров с использованием метода локтя
            for k in 1..<distortions.count {
                if distortions[k] - distortions[k - 1] > 0.1 * distortions[0] {
                    return k
                }
            }

            return 1 // Если метод локтя не сработал, выбираем один кластер
        }

        // Реализация алгоритма k-средних
        func kMeans(data: [[Double]], k: Int, maxIterations: Int) -> ([Int], [[Double]]) {
            precondition(data.count >= k, "Число кластеров должно быть меньше или равно числу данных")

            // Инициализация начальных центроидов случайным образом
            var centroids = Array(data.shuffled().prefix(k))

            var assignments = Array(repeating: 0, count: data.count)
            
            for _ in 0..<maxIterations {
                // На этапе назначения каждая точка присваивается к ближайшему центроиду
                for i in 0..<data.count {
                    var minDistance = Double.greatestFiniteMagnitude
                    var cluster = 0
                    
                    for j in 0..<k {
                        let distance = euclideanDistance(data[i], centroids[j])
                        if distance < minDistance {
                            minDistance = distance
                            cluster = j
                        }
                    }
                    
                    assignments[i] = cluster
                }
                
                // На этапе обновления центроидов, каждый центроид пересчитывается как среднее всех точек в кластере
                var newCentroids = Array(repeating: Array(repeating: 0.0, count: data[0].count), count: k)
                var clusterCounts = Array(repeating: 0, count: k)
                
                for i in 0..<data.count {
                    let cluster = assignments[i]
                    newCentroids[cluster] = zip(newCentroids[cluster], data[i]).map(+)
                    clusterCounts[cluster] += 1
                }
                
                for j in 0..<k {
                    if clusterCounts[j] > 0 {
                        newCentroids[j] = newCentroids[j].map { $0 / Double(clusterCounts[j]) }
                    }
                }
                
                if centroids == newCentroids {
                    // Сходимость достигнута
                    break
                } else {
                    centroids = newCentroids
                }
            }
            
            return (assignments, centroids)
        }

        var data: [[Double]] = []
        for area in model.binaryRepresentation!.areasProperties {
            data.append([ Double(area.figureArea), Double(area.perimeter), area.compactness])
        }
        
        let k = numberOfClusters //elbowMethod(data: data, maxK: 14)
        let maxIterations = 100000

        let (assignments, centroids) = kMeans(data: data, k: k, maxIterations: maxIterations)
        print("Назначения: \(assignments)")
        print("Центроиды: \(centroids)")
        model.clusters = [:]
        for i in assignments.indices {
            var newValue = model.clusters![centroids[assignments[i]]] ?? []
            newValue.append(i)
            model.clusters?.updateValue(newValue, forKey: centroids[assignments[i]])
        }
    }
}
