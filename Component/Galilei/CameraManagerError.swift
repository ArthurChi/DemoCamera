//
//  CameraManagerError.swift
//  Galilei
//
//  Created by VassilyChi on 2019/12/31.
//

import Foundation
import AVFoundation

public enum CameraManagerError: Error {
    case inputAddError(AVMediaType)
    case deviceInitError(AVMediaType)
    case resourceNotReady
}
