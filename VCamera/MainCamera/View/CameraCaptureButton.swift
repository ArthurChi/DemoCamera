//
//  CameraCaptureButton.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/25.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import Combine
import CombineCocoa

class CameraCaptureButton: UIButton {
    enum Action {
        case tap
        case longPress(LongPressState)
    }
    
    enum LongPressState {
        case begin
        case end
    }
    
    private var actionSubject = PassthroughSubject<Action, Never>()
    public var actionPublisher: AnyPublisher<Action, Never> { return actionSubject.eraseToAnyPublisher() }
    
    private var longPressGes = UILongPressGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        longPressGes.minimumPressDuration = 1
        addGestureRecognizer(longPressGes)
        
        longPressGes.longPressPublisher
            .removeDuplicates { $0.state == $1.state }
            .flatMap { gesture -> AnyPublisher<LongPressState, Never> in
                if gesture.state == .began {
                    return Just(LongPressState.begin).eraseToAnyPublisher()
                } else if gesture.state == .ended {
                    return Just(LongPressState.end).eraseToAnyPublisher()
                } else {
                    return Empty().eraseToAnyPublisher()
                }
            }
            .map { Action.longPress($0) }
            .receive(subscriber: AnySubscriber(actionSubject))
            

        self.controlEventPublisher(for: .touchUpInside)
            .map { Action.tap }
            .receive(subscriber: AnySubscriber(actionSubject))
    }
}
