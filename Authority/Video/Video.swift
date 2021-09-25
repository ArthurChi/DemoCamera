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
    /// 相机权限相关
    public struct Camera {
        /// 相机权限是否可用
        public static var isAvaliable: Bool {
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        }
        
        /// 请求相机权限
        /// - Returns: 请求结果的publisher
        public static func requestAuthority() -> AnyPublisher<Bool, AuthorityError> {
            Future<Bool, AuthorityError>.init { promise in
                AVCaptureDevice.requestAccess(for: .video) { result in
                    if result {
                        promise(.success(result))
                    } else {
                        promise(.failure(AuthorityError.accessDeny))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
    }
}
