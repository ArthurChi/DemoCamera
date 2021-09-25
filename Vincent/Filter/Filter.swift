//
//  Filter.swift
//  Pods
//
//  Created by VassilyChi on 2020/8/20.
//

import Foundation
import Metal
import Combine
import CoreImage

public protocol Filter {
    var name: String { get }
    func render(source: RenderTexture) -> RenderTexture
}

public class RosyFilter: Filter {
    
    public var name: String { "RosyFilter" }
    
    public init() {}
    
    public func render(source: RenderTexture) -> RenderTexture {
        let filter = CIFilter(name: "CISepiaTone", parameters: [
            kCIInputImageKey: source.sourceImage
        ])
        
        let outImage = filter!.outputImage!
        // TODO: CHIJIE - 应当使用新生成的desc
        return .init(sourceImage: outImage, formatDesc: source.format)
    }
}

public class EmptyFilter: Filter {
    
    public var name: String { "EmptyFilter" }
    
    public init() {}
    
    public func render(source: RenderTexture) -> RenderTexture {
        return source
    }
}
