//
//  EditorImageViewController.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/24.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import Combine
import SnapKit
import Galilei
import CombineCocoa

class EditorImageViewController: NiblessViewController {
    
    private var viewModel: EditorImageViewModel
    private var displayView: EditorImageDisplayView
    
    private var backBtn = UIButton()
    private var saveBtn = UIButton()
    
    private var events = [AnyCancellable]()
    
    deinit {
        print("deinit in vc abcs")
    }
    
    init(viewModel: EditorImageViewModel) {
        self.viewModel = viewModel
        displayView = .init(image: viewModel.outputImage())
        super.init()
     
        view.backgroundColor = .clear
        
        view.addSubview(displayView)
        view.addSubview(backBtn)
        view.addSubview(saveBtn)
        
        displayView.snp.makeConstraints { (maker) in
            let imageSize = viewModel.image.extent.size
            let ratio = imageSize.height / imageSize.width
            maker.left.right.equalTo(self.view)
            maker.top.equalTo(self.view).inset(self.topDistance(viewModel.ratio))
            maker.height.equalTo(self.displayView.snp.width).multipliedBy(ratio)
        }
        
        saveBtn.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.view)
            maker.bottom.equalTo(self.view).inset(50)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(self.saveBtn)
            maker.left.equalTo(self.view).inset(50)
        }
        
        backBtn.setTitle("back", for: .normal)
        saveBtn.setTitle("save", for: .normal)
        
        backBtn.tapPublisher
            .sink { [unowned self] _ in
                self.dismiss(animated: true, completion: nil)
            }
            .store(in: &events)
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
