//
//  MainCameraViewModel.swift
//  VCamera
//
//  Created by VassilyChi on 2020/7/29.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import Combine
import Galilei
import AVFoundation
import Authority
import Photos
import Vincent
import MediaBox

enum SwipDirection {
    case left
    case right
}

enum MainCameraViewModelAction {
    case changeRatio(CameraRatio)
    case takePhoto
    case changeCameraPos
    case changeFocus(CGPoint)
    case changeFocusAuto
    case changeFilter(SwipDirection)
    case takeVideo(CameraCaptureButton.LongPressState)
}

class MainCameraViewModel {
    let cameraManager: CameraManager
    let render: Render
    private var photoCaptureProcessor: PhotoCaptureProcessor
    
    var movieWriter: MovieWriter?
    
    private var events = [AnyCancellable]()
    
    var takePhotoObservable: AnyPublisher<CIImage, Error> {
        photoCaptureProcessor
            .capturePublisher
            .map { (photo) -> CIImage in
                return CIImage(data: photo.fileDataRepresentation()!, options: [CIImageOption.applyOrientationProperty: true])!.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            }
            .eraseToAnyPublisher()
    }
    
    let renderResource = RenderDeivceResource()
    
    let filters: [Filter] = [ RosyFilter(), EmptyFilter() ]
    var filterIndex = 0
    
    private var format: CMFormatDescription?
    
    private var subscription: Subscription?
    
    // MARK: - METHODS
    
    init(cameraManager: CameraManager, render: Render) {
        self.cameraManager = cameraManager
        self.render = render
        photoCaptureProcessor = .init()
    }
    
    deinit {
        subscription?.cancel()
    }
    
    func requireAuthority() -> AnyPublisher<Bool, Error> {
        Authority.Camera
            .requestAuthority()
            .flatMap({ result -> AnyPublisher<Bool, AuthorityError> in
                if result {
                    return Authority.Audio.requestAuthority().eraseToAnyPublisher()
                } else {
                    return Fail<Bool, AuthorityError>(error: AuthorityError.accessDeny).eraseToAnyPublisher()
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func startCamera() {
        render.textureBufferPublisher
            .sink { [unowned self] renderTexture in
                self.format = renderTexture.format
            }
            .store(in: &events)
        cameraManager.setVideoOutputDelegate(render)
        cameraManager.start()
    }
}

extension MainCameraViewModel: Subscriber {
    
    typealias Input = MainCameraViewModelAction
    
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }
    
    func receive(_ input: MainCameraViewModelAction) -> Subscribers.Demand {
        doAction(input)
        return .unlimited
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        subscription?.cancel()
    }
    
    private func doAction(_ action: MainCameraViewModelAction) {
        switch action {
        case .changeRatio(let ratio):
            cameraManager.changeRatio(ratio)
        case .takePhoto:
            self.cameraManager.photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: photoCaptureProcessor)
        case .changeCameraPos:
            self.cameraManager.changePosition()
        case .changeFocus(let point):
            let cameraPoint = self.cameraManager.videoDataOutput?.metadataOutputRectConverted(fromOutputRect: .init(origin: point, size: .zero)).origin ?? CGPoint.init(x: 0.5, y: 0.5)
            self.cameraManager.focus(with: .autoFocus, exposureMode: .autoExpose, at: cameraPoint, monitorSubjectAreaChange: true)
        case .changeFocusAuto:
            self.cameraManager.focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: .init(x: 0.5, y: 0.5), monitorSubjectAreaChange: false)
        case .changeFilter(let direction):
            
            switch direction {
            case .left:
                filterIndex = (filterIndex + 1) % filters.count
            case .right:
                if filterIndex == 0 {
                    filterIndex = filters.count - 1
                } else {
                    filterIndex -= 1
                }
            }
            
            render.changeFilter(filter: filters[filterIndex])
            
        case .takeVideo(let state):
            switch state {
            case .begin:
                print("movie writer开始写入")
                let options = MovieWriterOption(formatDest: format!)
                let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let a = url.appendingPathComponent("\(Date().timeIntervalSince1970).mp4")
                movieWriter = MovieWriter(outputURL: a, options: options, renderResource: renderResource)
                movieWriter?.start()
                render.textureBufferPublisher.subscribe(movieWriter!)
            case .end:
                print("movie writer写入结束")
                movieWriter?.receive(completion: .finished)
                movieWriter = nil
            }
        }
    }
}

// MARK: take photo
extension MainCameraViewModel {
    private func save(photo: AVCapturePhoto) -> AnyPublisher<Void, Never> {
        return Future<Void, Never>.init { promise in
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                let creationRequest = PHAssetCreationRequest.forAsset()
                let image = CIImage(data: photo.fileDataRepresentation()!, options: [CIImageOption.applyOrientationProperty: true])!.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                let data = UIImage(ciImage: self.render.renderImage(image)).pngData()!
                creationRequest.addResource(with: .photo, data: data, options: options)
                promise(.success(()))
            })
        }
        .eraseToAnyPublisher()
    }
}
