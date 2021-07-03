//
//  MetalViewModel.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/11.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import Foundation
import Galilei
import Combine
import Vincent
import simd
import MetalKit
import AVFoundation
import CoreImage

class MetalViewModel: NSObject {
    
    private let cameraManager: CameraManager
    private let renderInfoProvider: RenderInfoProvider
    
    private let drawableSizeSubject: PassthroughSubject<CGSize, Never> = .init()
    var drawableSizePublisher: AnyPublisher<CGSize, Never> { drawableSizeSubject.eraseToAnyPublisher() }
    
    private var modelMatrix: float4x4 = matrix_identity_float4x4
    
    var pixelFormat: MTLPixelFormat { renderInfoProvider.pixelFormat }
    
    var ratioChange: AnyPublisher<CameraRatio, Never> {
        cameraManager
            .$cameraRatio
            .removeDuplicates()
            .receive(on: DispatchQueue.main, options: nil)
            .handleEvents(receiveOutput: { ratio in
                self.modelMatrix = matrix_identity_float4x4
                switch ratio {
                case .r1_1:
                    self.modelMatrix.scale(1, y: 4.0/3.0, z: 1)
                case .full:
                    self.modelMatrix.scale(3.0/4.0, y: 1, z: 1)
                default:
                    break
                }
            })
            .eraseToAnyPublisher()
    }
    var ratio: CameraRatio { return cameraManager.cameraRatio }
    
    private var vertexesBuffer: MTLBuffer!
    private var textureBuffer: MTLBuffer!
    
    private var renderPipelineState: MTLRenderPipelineState?
    private var textTure: RenderTexture?
    
    private let vertexesData: [Float] = [
        1.0, -1.0, 0.0, 1.0,
        -1.0, -1.0, 0.0, 1.0,
        -1.0, 1.0, 0.0, 1.0,
        
        1.0, -1.0, 0.0, 1.0,
        -1.0, 1.0, 0.0, 1.0,
        1.0, 1.0, 0.0, 1.0,
    ]
    
    private let textureData: [Float] = [
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
        
        1.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
    ]
    
    init(cameraManager: CameraManager, renderInfoProvider: RenderInfoProvider) {
        self.cameraManager = cameraManager
        self.renderInfoProvider = renderInfoProvider
        
        super.init()
        
        setup()
        
        setupRenderPipelineState()
    }
    
    private func setup() {
        vertexesBuffer = renderInfoProvider.resource.device.makeBuffer(bytes: vertexesData, length: vertexesData.count * MemoryLayout<Float>.stride, options: [.storageModeShared])
        textureBuffer = renderInfoProvider.resource.device.makeBuffer(bytes: textureData, length: textureData.count * MemoryLayout<Float>.size, options: [.storageModeShared])
        
        renderInfoProvider
            .textureBufferPublisher
            .handleEvents(receiveOutput: { renderTexture in
                self.textTure = renderTexture
            })
            .map { CGSize.init(width: $0.width, height: $0.height) }
            .receive(subscriber: AnySubscriber(self.drawableSizeSubject))
    }
    
    private func setupRenderPipelineState() {
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.sampleCount = 1
        pipelineDescriptor.colorAttachments[0].pixelFormat = renderInfoProvider.pixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        
        /**
         *  Vertex function to map the texture to the view controller's view
         */
        pipelineDescriptor.vertexFunction = renderInfoProvider.resource.library.makeFunction(name:"vertexShader")
        /**
         *  Fragment function to display texture's pixels in the area bounded by vertices of `mapTexture` shader
         */
        pipelineDescriptor.fragmentFunction = renderInfoProvider.resource.library.makeFunction(name:"samplingShader")
        
        do {
            renderPipelineState = try renderInfoProvider.resource.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch {
            assertionFailure("Failed creating a render state pipeline. Can't render the texture without one.")
            return
        }
    }
}

// MARK: - RENDER

extension MetalViewModel: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        
        guard
            let sourceTexture = self.textTure,
            let currentRenderPassDescriptor = view.currentRenderPassDescriptor,
            let currentDrawable = view.currentDrawable,
            let renderPipelineState = renderPipelineState,
            let commandBuffer = renderInfoProvider.resource.commandQueue.makeCommandBuffer()
        else { return }
        
        let targetTexture = generateTexture(from: sourceTexture)
        let transformedImg = sourceTexture.sourceImage.transformed(by: .init(scaleX: 1, y: -1))
        sharedRenderResource.defaultContext.render(transformedImg, to: targetTexture, commandBuffer: commandBuffer, bounds: transformedImg.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor) else { return }
        
        encoder.pushDebugGroup("RenderFrame")
        encoder.setRenderPipelineState(renderPipelineState)

        encoder.setVertexBuffer(vertexesBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        encoder.setVertexBytes(&modelMatrix, length: MemoryLayout<float4x4>.size, index: 2)
        encoder.setFragmentTexture(targetTexture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.popDebugGroup()
        encoder.endEncoding()

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    private func generateTexture(from sourceTexture: RenderTexture) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: sourceTexture.width,
                                                                         height: sourceTexture.height,
                                                                         mipmapped: false)
        
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        guard let targetTexture = sharedRenderResource.device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Could not create texture of size: (\(sourceTexture.width), \(sourceTexture.height))")
        }
        
        return targetTexture
    }
}

extension CGSize {
    func transRatio(_ ratio: CameraRatio) -> CGSize {
        switch ratio {
        case .r1_1:
            return .init(width: width, height: width)
        case .r3_4:
            return .init(width: width, height: width * 4 / 3.0)
        case .r9_16:
            return .init(width: width, height: width * 16 / 9)
        case .full:
            let width = height * 3.0 / 4.0
            return .init(width: width, height: height)
        }
    }
}
