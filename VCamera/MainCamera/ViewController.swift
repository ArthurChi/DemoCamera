//
//  ViewController.swift
//  VCamera
//
//  Created by VassilyChi on 2019/12/15.
//  Copyright © 2019 VassilyChi. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    private let btn = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(btn)
        btn.setTitle("camera", for: .normal)
        btn.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
        btn.addTarget(self, action: #selector(btnDidClicked(_:)), for: .touchUpInside)
    }
    
    @objc
    private func btnDidClicked(_ sender: UIButton) {
//        let mainVC = MainCameraViewController()
//        self.navigationController?.pushViewController(mainVC, animated: true)
    }
}
