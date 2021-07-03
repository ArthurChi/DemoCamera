//
//  RenderDeivceResource.swift
//  Pods
//
//  Created by VassilyChi on 2020/8/9.
//

import Foundation
import MetalKit

public let sharedRenderResource = RenderDeivceResource()

public class RenderDeivceResource {
    public let device: MTLDevice
    public private(set) var commandQueue: MTLCommandQueue
    public private(set) var library: MTLLibrary
    
    public private(set) var defaultContext: CIContext
    
    public init() {
        if let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue(),
            let library = device.makeDefaultLibrary() {
            self.device = device
            self.commandQueue = commandQueue
            self.library = library
            defaultContext = CIContext(mtlDevice: device)
        } else {
            fatalError()
        }
    }
    
    lazy var passthroughRenderState: MTLRenderPipelineState = generate(device: sharedRenderResource, vertexFunctionName:"oneInputVertex", fragmentFunctionName:"passthroughFragment", operationName:"Passthrough")
    
    private func generate(device: RenderDeivceResource, vertexFunctionName: String, fragmentFunctionName: String, operationName: String) -> MTLRenderPipelineState {
        guard let vertexFunction = device.library.makeFunction(name: vertexFunctionName) else {
            fatalError("\(operationName): could not compile vertex function \(vertexFunctionName)")
        }
        
        guard let fragmentFunction = device.library.makeFunction(name: fragmentFunctionName) else {
            fatalError("\(operationName): could not compile fragment function \(fragmentFunctionName)")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        descriptor.rasterSampleCount = 1
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        do {
            return try device.device.makeRenderPipelineState(descriptor: descriptor, options: [.bufferTypeInfo, .argumentInfo], reflection: nil)
        } catch {
            fatalError("Could not create render pipeline state for vertex:\(vertexFunctionName), fragment:\(fragmentFunctionName), error:\(error)")
        }
    }
}
