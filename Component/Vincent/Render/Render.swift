//
//  Render.swift
//  Vincent
//
//  Created by VassilyChi on 2020/8/19.
//

import Foundation
import Combine
import AVFoundation
import CoreImage

public protocol RenderInfoProvider: RenderSource {
    var resource: RenderDeivceResource { get }
    var pixelFormat: MTLPixelFormat { get }
}

public class Render: NSObject, RenderInfoProvider {
    
    private var textureBufferSubject = PassthroughSubject<RenderTexture, Never>()
    public var textureBufferPublisher: AnyPublisher<RenderTexture, Never> { self.textureBufferPublisher.map({ self.filter.render(source: $0) }).eraseToAnyPublisher() }
    
    private var filter: Filter = RosyFilter()
    
    public private(set) var resource: RenderDeivceResource
    
    public let pixelFormat: MTLPixelFormat = .bgra8Unorm
    
    public init(renderResource: RenderDeivceResource) {
        resource = renderResource
        super.init()
    }
    
    public func changeFilter(filter: Filter) {
        self.filter = filter
        print(filter.name)
    }
}

// MARK: PHOTO
public extension Render {
    func renderImage(_ sourceImage: CIImage) -> CIImage {
        // TODO: CHIJIE
        return sourceImage
//        let source = RenderTexture(sourceImage: sourceImage, width: Int(sourceImage.extent.size.width), height: Int(sourceImage.extent.size.height))
//        return filter.render(source: source).sourceImage
    }
}

extension Render: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let desc = CMSampleBufferGetFormatDescription(sampleBuffer) {
            
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let texture = RenderTexture(sourceImage: CIImage(cvImageBuffer: imageBuffer), formatDesc: desc, timeStamp: time)
            self.textureBufferSubject.send(texture)
        }
    }
}
