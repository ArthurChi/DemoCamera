//
//  RenderProtocols.swift
//  Authority
//
//  Created by VassilyChi on 2020/8/10.
//

import Foundation
import Combine
import MetalKit
import CoreMedia

//public protocol RenderCustomer: ObserverType where Element == RenderTexture {}

public enum ImageOrientation {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
}

public struct RenderTexture {
    public let width: Int
    public let height: Int
    
    public let sourceImage: CIImage
    public let timeStamp: CMTime
    
    public let format: CMFormatDescription
    
    public init(sourceImage: CIImage, formatDesc: CMFormatDescription, timeStamp: CMTime = .now()) {
        self.sourceImage = sourceImage
        format = formatDesc
        self.timeStamp = timeStamp
        let videoFormat = CMVideoFormatDescriptionGetDimensions(formatDesc)
        width = Int(videoFormat.width)
        height = Int(videoFormat.height)
    }
}

public protocol RenderSource {
    var textureBufferPublisher: AnyPublisher<RenderTexture, Never> { get }
}


public extension CMTime {
    static func now() -> CMTime {
        return CMTimeMake(value: Int64(CACurrentMediaTime() * Double(NSEC_PER_SEC)), timescale: Int32(NSEC_PER_SEC))
    }
}
