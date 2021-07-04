//
//  CameraManager.swift
//  VCamera
//
//  Created by VassilyChi on 2019/12/29.
//  Copyright © 2019 VassilyChi. All rights reserved.
//

import Foundation
import Authority
import AVFoundation
import Combine

public class CameraManager {
    
    private let operationQueue = DispatchQueue(label: "Galilei.CameraManager.operationQueue")
    private let sampleDataQueue = DispatchQueue(label: "Galilei.CameraManager.sampleDataQueue")
    
    public let session: AVCaptureSession = AVCaptureSession()
    
    @Published
    public private(set) var cameraRatio: CameraRatio = .r3_4
    
    @Published
    public private(set) var cameraPos: AVCaptureDevice.Position = .front
    
    private let cameraDeviceSubjectAreaDidChange: PassthroughSubject<Void, Never> = .init()
    public var cameraDeviceSubjectAreaDidChangePublisher: AnyPublisher<Void, Never> { cameraDeviceSubjectAreaDidChange.eraseToAnyPublisher()
    }
    
    private let devices: [AVCaptureDevice]
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    
    public private(set) var photoOutput: AVCapturePhotoOutput?
    public private(set) var videoDataOutput: AVCaptureVideoDataOutput?
    
    private var camptureSampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    private var currentDevice: AVCaptureDevice?
    
    public init(devices: [AVCaptureDevice]) {
        self.devices = devices
        addObserver()
    }
    
    public func start() {
        operationQueue.async {
            if self.session.isRunning { return }
            if self.videoDataOutput?.sampleBufferDelegate == nil,
                let delegate = self.camptureSampleBufferDelegate {
                self.videoDataOutput?.alwaysDiscardsLateVideoFrames = false
                self.videoDataOutput?.setSampleBufferDelegate(delegate , queue: self.sampleDataQueue)
            }
            self.session.startRunning()
        }
    }
    
    public func stop() {
        operationQueue.async {
            self.session.stopRunning()
        }
    }
    
    private func addObserver() {
        let subscriber = AnySubscriber.init(self.cameraDeviceSubjectAreaDidChange)
        NotificationCenter.default
            .publisher(for: .AVCaptureDeviceSubjectAreaDidChange, object: self.videoInput)
            .map { _ in () }
            .receive(subscriber: subscriber)
    }
}

extension CameraManager {
    public func setVideoOutputDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.camptureSampleBufferDelegate = delegate
        videoDataOutput?.alwaysDiscardsLateVideoFrames = false
        videoDataOutput?.setSampleBufferDelegate(delegate , queue: sampleDataQueue)
    }
}

// MARK: In Out
extension CameraManager {
    public func readyResources() -> AnyPublisher<Void, Error> {
        Future<Void, Error>.init { promise in
            self.operationQueue.async {
                self.session.beginConfiguration()

                do {
                    try self.addVideoInput(position: self.cameraPos)
                        .addAudioInput()
                        .addPhotoOutput()
                        .addVideOutput()
                    self.setupvideoDataOutputConnection(curPostion: self.cameraPos)
                    self.session.sessionPreset = Self.presetForRatio(self.cameraRatio)
                } catch let error {
                    promise(.failure(error))
                }

                self.session.commitConfiguration()
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    @discardableResult
    private func addVideoInput(position: AVCaptureDevice.Position) throws -> CameraManager {
        guard Authority.Camera.isAvaliable else { throw AuthorityError.accessDeny }
        guard let defaultDevice: AVCaptureDevice = devices.first(where: { $0.position == position }) else { throw CameraManagerError.deviceInitError(.video) }
        self.currentDevice = defaultDevice
        let input = try AVCaptureDeviceInput(device: defaultDevice)

        if session.canAddInput(input) {
            session.addInput(input)
            videoInput = input
            addObserver()
        }
        
        return self
    }
    
    @discardableResult
    private func addAudioInput() throws -> CameraManager {
        guard Authority.Audio.isAvaliable else { throw AuthorityError.accessDeny }
        guard let defaultDevice: AVCaptureDevice = AVCaptureDevice.default(for: .audio) else { throw CameraManagerError.deviceInitError(.audio) }

        let input = try AVCaptureDeviceInput(device: defaultDevice)

        if session.canAddInput(input) {
            session.addInput(input)
            audioInput = input
        }
        
        return self
    }
    
    @discardableResult
    public func addPhotoOutput() -> CameraManager {
        
        let photoOutput = AVCapturePhotoOutput()
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        self.photoOutput = photoOutput
        
        return self
    }
    
    @discardableResult
    public func addVideOutput() -> CameraManager {
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            
            videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
        }
        
        self.videoDataOutput = videoDataOutput
        
        return self
    }
    
    private func changeInput() throws {
        if let curVideoInput = self.videoInput {
            NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: self.videoInput)
            session.removeInput(curVideoInput)
        }
        
        try addVideoInput(position: self.cameraPos.togglePosition)
    }
    
    private func setupvideoDataOutputConnection(curPostion:  AVCaptureDevice.Position) {
        guard let connection = videoDataOutput?.connection(with: .video) else { return }
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        switch curPostion {
        case .back:
            connection.isVideoMirrored = false
        default:
            connection.isVideoMirrored = true
        }
    }
}

// MARK: control
public extension CameraManager {
    func changeRatio(_ ratio: CameraRatio) {
        self.operationQueue.async {
            self.session.beginConfiguration()

            if self.session.canSetSessionPreset(Self.presetForRatio(ratio)) {
                self.session.sessionPreset = Self.presetForRatio(ratio)
                self.cameraRatio = ratio
            }

            self.session.commitConfiguration()
        }
    }
    
    func changePosition() {
        self.operationQueue.async {
            self.session.beginConfiguration()

            do {
                try self.changeInput()
                self.cameraPos = self.cameraPos.togglePosition
                self.setupvideoDataOutputConnection(curPostion: self.cameraPos)
                self.session.commitConfiguration()
            } catch {
                self.session.commitConfiguration()
            }
        }
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        
        self.operationQueue.async {
            guard let videoDevice = self.videoInput?.device else { return }
            
            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                    videoDevice.focusPointOfInterest = devicePoint
                    videoDevice.focusMode = focusMode
                }
                
                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                    videoDevice.exposurePointOfInterest = devicePoint
                    videoDevice.exposureMode = exposureMode
                }
                
                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
}

extension CameraManager {
    static func presetForRatio(_ ratio: CameraRatio) -> AVCaptureSession.Preset {
        switch ratio {
        case .r3_4, .r1_1:
            return .photo
        default:
            return .hd1280x720
        }
    }
}

extension AVCaptureDevice.Position {
    var togglePosition: Self {
        switch self {
        case .back:
            return .front
        default:
            return .back
        }
    }
}
