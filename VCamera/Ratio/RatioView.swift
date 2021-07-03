//
//  RatioView.swift
//  VCamera
//
//  Created by VassilyChi on 2020/1/10.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import Galilei
import Combine
import CombineCocoa

public class RatioView: NiblessView {
    
    private var ratioChangeSubject = PassthroughSubject<CameraRatio, Never>()
    public var ratioChangePublisher: AnyPublisher<CameraRatio, Never> { ratioChangeSubject.eraseToAnyPublisher() }
    
    private var curTheme: Theme
    
    private var events = [AnyCancellable]()
    
    private let ratios: [CameraRatio] = [
        .full,
        .r9_16,
        .r3_4,
        .r1_1
    ]
    
    init(ratio: CameraRatio) {
        
        switch ratio {
        case .r1_1, .r3_4:
            curTheme = .white
        case .r9_16, .full:
            curTheme = .black
        }
        
        super.init(frame: .zero)
        
        setup()
    }
    
    private func setup() {
        
        var lastBtn: UIButton?
        
        let imageNames = ratios.map(ratioImageName)
        let btnStr = ratios.map(ratioName)
        
        for imageName in imageNames.enumerated() {
            let btn = RatioButton(ratio: ratios[imageName.offset])
            btn.setImage(UIImage(named: imageName.element), for: .normal)
            btn.setTitle(btnStr[imageName.offset], for: .normal)
            btn.setTitleColor(.black, for: .normal)
            addSubview(btn)
            
            btn.tapPublisher
                .map { _ in btn.ratio }
                .receive(subscriber: AnySubscriber(ratioChangeSubject))
            
            if let last = lastBtn {
                btn.snp.makeConstraints { (maker) in
                    maker.top.bottom.equalToSuperview()
                    maker.left.equalTo(last.snp.right)
                    maker.width.equalTo(last.snp.width)
                }
            } else {
                btn.snp.makeConstraints { (maker) in
                    maker.top.bottom.left.equalToSuperview()
                }
            }
            
            lastBtn = btn
        }
        
        lastBtn?.snp.makeConstraints({ (maker) in
            maker.right.equalToSuperview()
        })
    }
}

fileprivate extension RatioView {
    final class RatioButton: UIButton {
        var ratio: CameraRatio
        
        init(ratio: CameraRatio) {
            self.ratio = ratio
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    enum Theme {
        case black
        case white
        
        var modelImageSurfix: String {
            switch self {
            case .black:
                return "b_n"
            case .white:
                return "p"
            }
        }
    }
    
    private func ratioImageName(_ ratio: CameraRatio) -> String {
        let imageName: String
        switch ratio {
        case .r1_1:
            imageName = "more_ic_1_1_"
        case .r3_4:
            imageName = "more_ic_3_4_"
        case .r9_16:
            imageName = "more_ic_9_16_"
        case .full:
            imageName = "more_ic_full_"
        }
        
        return "\(imageName)\(curTheme.modelImageSurfix)"
    }
    
    private func ratioName(_ ratio: CameraRatio) -> String {
        switch ratio {
        case .r1_1:
            return "1:1"
        case .r3_4:
            return "3:4"
        case .r9_16:
            return "9:16"
        case .full:
            return "全屏"
        }
    }
}
