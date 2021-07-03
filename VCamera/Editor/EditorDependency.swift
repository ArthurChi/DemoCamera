//
//  EditorDependency.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/24.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import Foundation
import Swinject
import Vincent
import Galilei
import CoreImage

struct EditorDependency {
    private let container: Container
    
    init() {
        container = AppDependency.shared.makeChildContainer()
        
        container.register(EditorImageViewModel.self) { (resolver, arg1: CIImage) in
            let resource = resolver.resolve(RenderDeivceResource.self)!
            let render = Render(renderResource: resource)
            let cameraManager = resolver.resolve(CameraManager.self)!
            return EditorImageViewModel(inputImage: arg1, render: render, ratio: cameraManager.cameraRatio)
        }
        
        container.register(EditorImageViewController.self) { (resolver, arg1: CIImage) in
            let vm = resolver.resolve(EditorImageViewModel.self, argument: arg1)!
            return EditorImageViewController(viewModel: vm)
        }
    }
    
    func makeImageEditorVC(_ sourceImage: CIImage) -> EditorImageViewController {
        return container.resolve(EditorImageViewController.self, argument: sourceImage)!
    }
}
