//
//  ViewModel.swift
//  cosii1
//
//  Created by Alex on 27.09.23.
//

import SwiftUI
import Algorithms

@MainActor class Cosii1AppSwiftUI: ObservableObject {
    @Published private(set) var model = Model()
    
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
    
    func adavanceBrightnessCounters(pixel: Pixel, isPreparingInput: Bool) {
        if isPreparingInput {
            model.inputBrignesses.R[Int(pixel.r)]! += 1
            model.inputBrignesses.G[Int(pixel.g)]! += 1
            model.inputBrignesses.B[Int(pixel.b)]! += 1
        } else {
            model.outputBrignesses.R[Int(pixel.r)]! += 1
            model.outputBrignesses.G[Int(pixel.g)]! += 1
            model.outputBrignesses.B[Int(pixel.b)]! += 1
        }
    }
    
    func loadImage(from url: URL?) throws {
        if url != nil {
            try withAnimation {
                try model.sourceFileData = Data(contentsOf: url!)
            }
            Task(priority: .high) {
                if inputImage != nil {
                    await prepareBrigtnessLevels(isPreparingInput: true)
                }
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
    
    func prepareBrigtnessLevels(isPreparingInput: Bool) async {
        if isPreparingInput {
            model.inputBrignesses.clearAllLevels()
        } else {
            model.outputBrignesses.clearAllLevels()
        }
        guard let image = isPreparingInput ? inputImage : outputImage else { return; }
        guard let tiffData = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffData) else { return; }
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        let bytesPerRow = bitmap.bytesPerRow
        let bitsPerPixel = bitmap.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8
        
        guard let pixelData = bitmap.bitmapData else {
            fatalError("Failed to get pixel data")
        }
        await withTaskGroup(of: Void.self) { group in
            for x in 0..<width {
                group.addTask {
                    for y in 0..<height {
                        let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
                        await self.adavanceBrightnessCounters(pixel:
                                                    Pixel(r: UInt8(pixelData[pixelOffset + 0]),
                                                          g: UInt8(pixelData[pixelOffset + 1]),
                                                          b: UInt8(pixelData[pixelOffset + 2]),
                                                          a: UInt8(pixelData[pixelOffset + 3])), isPreparingInput: isPreparingInput)
                        
                       
                    }
                }
            }
            
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
                            let red = Int(UInt8(pixelData[pixelOffset + 0]))
                            let newRed = Int( (Float(red) * ( (gmax - gmin) / (fmax - fmin))) > 255 ? 255 : (Float(red) * ( (gmax - gmin) / (fmax - fmin)))) + Int(gmin)
                            pixelData[pixelOffset + 0] = UInt8(newRed > 255 ? 255 : newRed) // Красный
                            
                            let green = UInt8(pixelData[pixelOffset + 1])
                            let newGreen = Int( (Float(green) * ( (gmax - gmin) / (fmax - fmin))) > 255 ? 255 : (Float(green) * ( (gmax - gmin) / (fmax - fmin)))) + Int(gmin)
                            pixelData[pixelOffset + 1] = UInt8(newGreen > 255 ? 255 : newGreen)// Зеленый
                            
                            let blue = pixelData[pixelOffset + 2]
                            let newBlue = Int( (Float(blue) * ( (gmax - gmin) / (fmax - fmin))) > 255 ? 255 : (Float(blue) * ( (gmax - gmin) / (fmax - fmin)))) + Int(gmin)
                            pixelData[pixelOffset + 2] = UInt8(newBlue > 255 ? 255 : newBlue) // Синий
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
    
}
