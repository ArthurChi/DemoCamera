//
//  EditorImageViewModel.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/24.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import Vincent
import CoreImage
import Combine
import Galilei

class EditorImageViewModel {
    
    let ratio: CameraRatio
    let image: CIImage
    private let render: Render
    private let ciContext = CIContext()
    
    init(inputImage: CIImage, render: Render, ratio: CameraRatio) {
        image = inputImage
        self.render = render
        self.ratio = ratio
    }
}

extension EditorImageViewModel {
    func outputImage() -> CIImage {
        return render.renderImage(image)
    }
    
    func outputImage() -> UIImage {
        let cgImage = ciContext.createCGImage(outputImage(), from: image.extent)
        return UIImage(cgImage: cgImage!)
    }
}
