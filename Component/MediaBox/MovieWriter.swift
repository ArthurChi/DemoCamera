//
//  MovieWriter.swift
//  MediaBox
//
//  Created by VassilyChi on 2020/8/26.
//

import Foundation
import AVFoundation
import Vincent
import CoreImage
import Combine

public struct Buffer {
    var pixelBuffer: CVPixelBuffer
    var time: CMTime
}

public struct MovieWriterOption {
    var formatDest: CMFormatDescription
    
    public init(formatDest: CMFormatDescription) {
        self.formatDest = formatDest
    }
}

public class MovieWriter {
    
    private let writer: AVAssetWriter
    private let videoFrameSize: CGSize
    
    private let videoInput: AVAssetWriterInput
    private var videoInputAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var inputReadyObserver: NSKeyValueObservation?
    
    private var renderResource: RenderDeivceResource
    
    private var format: CMFormatDescription
    private let ciContext = CIContext()
    private lazy var result = allocateOutputBufferPool(with: self.format, outputRetainedBufferCountHint: 3)
    
    private var startTime: CMTime?
    
    private var movieWriterSubscription: Subscription?
    
    public init?(outputURL: URL, options: MovieWriterOption, renderResource: RenderDeivceResource) {
        do {
            writer = try .init(outputURL: outputURL, fileType: .mp4)
            let dimensions = CMVideoFormatDescriptionGetDimensions(options.formatDest)
            format = options.formatDest
            self.videoFrameSize = CGSize(width: Int(dimensions.width), height: Int(dimensions.height))
            self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
                AVVideoWidthKey: self.videoFrameSize.width,
                AVVideoHeightKey: self.videoFrameSize.height,
                AVVideoCodecKey: AVVideoCodecType.h264
            ])
            
            self.renderResource = renderResource
            
            setup()
        } catch {
            return nil
        }
    }
    
    deinit {
        print("writer \(#function)")
        inputReadyObserver?.invalidate()
    }
    
    private func setup() {
        if writer.canAdd(videoInput) {
            writer.add(videoInput)
            var settings = [String: Any]()
            settings[kCVPixelBufferWidthKey as String] = videoFrameSize.width
            settings[kCVPixelBufferHeightKey as String] = videoFrameSize.height
            settings[kCVPixelBufferPixelFormatTypeKey as String] = kCVPixelFormatType_32BGRA
            videoInputAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: settings)
            
            inputReadyObserver = videoInput.observe(\.isReadyForMoreMediaData) { [weak self] (input, change) in
                guard let self = self else { return }
                
                DispatchQueue.global().async {
                    print("input.isReadyForMoreMediaData", input.isReadyForMoreMediaData)
                }
            }
        }
    }
    
    public func add(buffer: Buffer) {
        if startTime == nil {
            startTime = buffer.time
            self.writer.startSession(atSourceTime: startTime!)
            print("add")
        }
        videoInputAdaptor?.append(buffer.pixelBuffer, withPresentationTime: buffer.time)
    }
}

public extension MovieWriter {
    func start() {
        self.writer.startWriting()
    }
    
    func finished() {
        videoInput.markAsFinished()
        
        writer.finishWriting {
            
        }
    }
}

extension MovieWriter: Subscriber {
    public typealias Input = RenderTexture
    
    public typealias Failure = Never
    
    public func receive(subscription: Subscription) {
        movieWriterSubscription = subscription
        subscription.request(.max(1))
    }
    
    public func receive(_ input: RenderTexture) -> Subscribers.Demand {
        let ciimage = input.sourceImage
        let time = input.timeStamp
        
        var pbuf: CVPixelBuffer?
        
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, self.result.outputBufferPool!, &pbuf)
        ciContext.render(ciimage, to: pbuf!)
        
        add(buffer: .init(pixelBuffer: pbuf!, time: time))
        return .max(1)
    }
    
    public func receive(completion: Subscribers.Completion<Never>) {
        movieWriterSubscription?.cancel()
        movieWriterSubscription = nil
        finished()
    }
}

func allocateOutputBufferPool(with inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) ->(
    outputBufferPool: CVPixelBufferPool?,
    outputColorSpace: CGColorSpace?,
    outputFormatDescription: CMFormatDescription?) {
        
        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
        if inputMediaSubType != kCVPixelFormatType_32BGRA {
            assertionFailure("Invalid input pixel buffer type \(inputMediaSubType)")
            return (nil, nil, nil)
        }
        
        let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
        var pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
            kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
            kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        print(Int(inputDimensions.width))
        print(Int(inputDimensions.height))
        
        // Get pixel buffer attributes and color space from the input format description.
        var cgColorSpace = CGColorSpaceCreateDeviceRGB()
        if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary? {
            let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]
            
            if let colorPrimaries = colorPrimaries {
                var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]
                
                if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
                    colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
                }
                
                if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
                    colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
                }
                
                pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
            }
            
            if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
                cgColorSpace = cvColorspace as! CGColorSpace
            } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
            }
        }
        
        // Create a pixel buffer pool with the same pixel attributes as the input format description.
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
        var cvPixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)
        guard let pixelBufferPool = cvPixelBufferPool else {
            assertionFailure("Allocation failure: Could not allocate pixel buffer pool.")
            return (nil, nil, nil)
        }
        
        preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)
        
        // Get the output format description.
        var pixelBuffer: CVPixelBuffer?
        var outputFormatDescription: CMFormatDescription?
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
        CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixelBuffer,
                                                         formatDescriptionOut: &outputFormatDescription)
        }
        pixelBuffer = nil
        
        return (pixelBufferPool, cgColorSpace, outputFormatDescription)
}

/// - Tag: AllocateRenderBuffers
private func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
    var pixelBuffers = [CVPixelBuffer]()
    var error: CVReturn = kCVReturnSuccess
    let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
    var pixelBuffer: CVPixelBuffer?
    while error == kCVReturnSuccess {
        error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            pixelBuffers.append(pixelBuffer)
        }
        pixelBuffer = nil
    }
    pixelBuffers.removeAll()
}
