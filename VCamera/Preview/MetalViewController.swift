//
//  MetalViewController.swift
//  VCamera
//
//  Created by VassilyChi on 2019/12/25.
//  Copyright © 2019 VassilyChi. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation
import Galilei
import Combine
import CoreImage
import MetalPerformanceShaders
import SnapKit
import Vincent

class MetalViewController: UIViewController {
    
    private var metalView: MTKView
    private var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    private var viewH: Constraint!
    private var viewW: Constraint!
    private var viewTop: Constraint!
    
    private var viewModel: MetalViewModel
    
    private var events = [AnyCancellable]()
    
    init(viewModel: MetalViewModel, metalView: MTKView) {
        self.viewModel = viewModel
        self.metalView = metalView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalView.delegate = self.viewModel
        metalView.framebufferOnly = true
        metalView.colorPixelFormat = viewModel.pixelFormat
        metalView.contentScaleFactor = UIScreen.main.scale
        view.addSubview(metalView)
        blurView.alpha = 0
        view.addSubview(blurView)
        
        metalView.snp.makeConstraints { (maker) in
            let size = self.view.bounds.size.transRatio(viewModel.ratio)
            viewW = maker.width.equalTo(size.width).constraint
            viewH = maker.height.equalTo(size.height).constraint
            
            let top = self.topDistance(viewModel.ratio)
            viewTop = maker.top.equalToSuperview().inset(top).constraint
            maker.centerX.equalToSuperview()
        }
        
        blurView.snp.makeConstraints { (maker) in
            maker.center.size.equalToSuperview()
        }
        
        bindToVM()
    }
    
    private func bindToVM() {
        viewModel
            .ratioChange
            .sink(receiveValue: { [weak self] ratio in
                if let self = self {
                    self.viewW = self.viewW.update(offset: self.view.bounds.size.transRatio(ratio).width)
                    self.viewH = self.viewH.update(offset: self.view.bounds.size.transRatio(ratio).height)
                    self.viewTop = self.viewTop.update(offset: self.topDistance(ratio))
                    
                    self.blurView.alpha = 1
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.layoutIfNeeded()
                    }) { (_) in
                        UIView.animate(withDuration: 0.3, animations: {
                            self.blurView.alpha = 0
                        })
                    }
                }
            })
            .store(in: &events)
        
//        viewModel
//            .drawableSizeObservable
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] (size) in
//                self?.metalView.drawableSize = size
//            })
//        .disposed(by: bag)
    }
    
    private func topDistance(_ ratio: CameraRatio) -> CGFloat {
        switch ratio {
        case .full:
            return 0
        case .r1_1:
            let renderViewH = self.view.bounds.size.transRatio(ratio).height
            let viewH = self.view.bounds.height
            
            return (viewH - renderViewH) * 0.5
        default:
            return 100
        }
    }
}
