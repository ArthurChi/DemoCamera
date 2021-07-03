//
//  AppDependency.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/11.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import Foundation
import Swinject
import AVFoundation
import Galilei
import Vincent

class AppDependency {
    
    static let shared = AppDependency()
    
    private let container: Container
    
    private init() {
        container = .init(parent: nil, defaultObjectScope: .container, behaviors: [], registeringClosure: { _ in })
        
        container.register(RenderDeivceResource.self) { _ in
            return sharedRenderResource
        }
        
        container.register(CameraManager.self) { _ in
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified).devices
            return CameraManager(devices: devices)
        }
    }
    
    func makeChildContainer(objectScrope: ObjectScope = .graph) -> Container {
        return .init(parent: self.container, defaultObjectScope: objectScrope, behaviors: [], registeringClosure: { _ in })
    }
}
