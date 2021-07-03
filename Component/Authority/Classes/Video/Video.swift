//
//  Video.swift
//  Pods-VCamera
//
//  Created by VassilyChi on 2019/12/18.
//

import Foundation
import AVFoundation
import Combine

extension Authority {
    public struct Camera {
        public static var isAvaliable: Bool {
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        }
        
        public static func requestAuthority() -> AnyPublisher<Bool, Never> {
            Future<Bool, Never>.init { promise in
                AVCaptureDevice.requestAccess(for: .video) { result in
                    promise(.success(result))
                }
            }
            .eraseToAnyPublisher()
        }
    }
}
