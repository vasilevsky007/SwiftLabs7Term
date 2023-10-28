//
//  BinaryImageView.swift
//  cosii4
//
//  Created by Alex on 25.10.23.
//

import SwiftUI

struct BinaryImageView: View {
    var image: BinaryImage
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 20, maximum: 1000)), count: 6), content: {
            ForEach(image.data) { pixel in
                Rectangle().aspectRatio(1, contentMode: .fit)
                    .foregroundColor(pixel.value ? .black : .white)
                    .onTapGesture {
                        //image.togglePixel(id: pixel.id)
                    }
            }
            
        })
    }
}

#Preview {
    BinaryImageView(image: BinaryImage())
}
