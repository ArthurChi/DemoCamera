//
//  MainViewDependency.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/25.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import Foundation
import Swinject
import MetalKit
import Vincent
import Galilei

class MainViewDependency {
    private let container: Container
    
    init() {
        container = AppDependency.shared.makeChildContainer()
        
        container.register(Render.self) { resolver in
            let renderResource = resolver.resolve(RenderDeivceResource.self)!
            return .init(renderResource: renderResource)
        }
        
        container.register(MTKView.self) { resolver in
            let device = resolver.resolve(RenderDeivceResource.self)?.device
            return .init(frame: .zero, device: device)
        }
        
        container.register(MainCameraViewModel.self) { resolver in
            let cameraManager = resolver.resolve(CameraManager.self)!
            let render = resolver.resolve(Render.self)!
            return MainCameraViewModel(cameraManager: cameraManager, render: render)
        }
        
        container.register(MetalViewModel.self) { resolver in
            let cameraManager = resolver.resolve(CameraManager.self)!
            let render = resolver.resolve(Render.self)!
            return .init(cameraManager: cameraManager, renderInfoProvider: render)
        }
        
        container.register(MetalViewController.self) { resolver in
            let vm = resolver.resolve(MetalViewModel.self)!
            let mtkView = resolver.resolve(MTKView.self)!
            return .init(viewModel: vm, metalView: mtkView)
        }
        
        container.register(MainCameraViewController.self) { resolver in
            let vm = resolver.resolve(MainCameraViewModel.self)!
            let mtkVC = resolver.resolve(MetalViewController.self)!
            return MainCameraViewController(viewModel: vm, metalVC: mtkVC)
        }
    }
    
    func makeMainViewController() -> MainCameraViewController {
        container.resolve(MainCameraViewController.self)!
    }
}
