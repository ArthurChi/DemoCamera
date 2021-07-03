//
//  PhotoCaptureProcessor.swift
//  VCamera
//
//  Created by VassilyChi on 2019/12/17.
//  Copyright © 2019 VassilyChi. All rights reserved.
//

import UIKit
import AVFoundation
import Combine

class PhotoCaptureProcessor: NSObject {
    
    private let captureSubject = PassthroughSubject<AVCapturePhoto, Error>()
    public var capturePublisher: AnyPublisher<AVCapturePhoto, Error> { captureSubject.eraseToAnyPublisher() }
    
    override init() {
        
    }
    
    deinit {
        print("processor deinit")
    }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            captureSubject.send(completion: .failure(error))
        } else {
            captureSubject.send(photo)
        }
    }
}
