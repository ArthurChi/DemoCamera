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
    
    var sink: Subscribers.Sink<MainCameraViewModelAction, Never>!
    
    // MARK: - METHODS
    
    init(cameraManager: CameraManager, render: Render) {
        self.cameraManager = cameraManager
        self.render = render
        photoCaptureProcessor = .init()
        sink = .init(receiveCompletion: { [weak self] completion in
            self?.receive(completion: completion)
        }, receiveValue: { [weak self] value in
            self?.receive(value)
        })
    }
    
    func requireAuthority() -> AnyPublisher<Bool, Never> {
        Authority.Camera.requestAuthority()
            .zip(Authority.Audio.requestAuthority()) { result1, result2 in
                return result1 && result2
            }
            .eraseToAnyPublisher()
    }
    
    func requireCameraResource(_ authorityIsReady: Bool) -> AnyPublisher<Void, Error> {
        if authorityIsReady {
            return self.cameraManager.readyResources()
        } else {
            return Fail.init(error: CameraManagerError.resourceNotReady).eraseToAnyPublisher()
        }
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

extension MainCameraViewModel {
    
    func receive(_ input: MainCameraViewModelAction) {
        doAction(input)
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        
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
                // TODO: CHIJIE
//                movieWriterBag = render.textureBufferObserver.debug().bind(to: movieWriter!)
            case .end:
                print("movie writer写入结束")
                movieWriter?.finished()
                movieWriter = nil
                // TODO: CHIJIE
//                movieWriterBag?.dispose()
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
