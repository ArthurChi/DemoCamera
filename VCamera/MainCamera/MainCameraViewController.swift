//
//  MainCameraViewController.swift
//  VCamera
//
//  Created by VassilyChi on 2020/7/30.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit
import Combine
import Galilei
import CombineCocoa

class MainCameraViewController: NiblessViewController {
    
    private var viewModel: MainCameraViewModel
    
    private let toolBar = CameraToolBar()
    
    private var editorDependency = EditorDependency()
    
    private lazy var ratioMenu: RatioView = {
        let view = RatioView(ratio: self.viewModel.cameraManager.cameraRatio)
        view.backgroundColor = .white
        view.alpha = 0
        return view
    }()
    
    private let dispatchQueue = DispatchQueue(label: "output")
    
    private var captureButton = CameraCaptureButton(type: .custom)
    
    private var mtkVC: MetalViewController
    
    private var changeCameraGes = UITapGestureRecognizer()
    private var focusGes = UITapGestureRecognizer()
    private var swipLeftGes = UISwipeGestureRecognizer()
    private var swipRightGes = UISwipeGestureRecognizer()
    
    private var events = [AnyCancellable]()
    
    init(viewModel: MainCameraViewModel, metalVC: MetalViewController) {
        self.viewModel = viewModel
        mtkVC = metalVC
        super.init()
    }
    
    deinit {
        print("\(self.classForCoder) deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        bindViewModel()
        
        viewModel
            .requireAuthority()
            .flatMap({ self.viewModel.requireCameraResource($0) })
            .receive(on: DispatchQueue.main, options: nil)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.viewModel.startCamera()
                case .failure(let err):
                    print(err)
                }
            } receiveValue: { _ in
                
            }
            .store(in: &events)
        
        viewModel
            .cameraManager
            .cameraDeviceSubjectAreaDidChangePublisher
            .map {
                MainCameraViewModelAction.changeFocusAuto
            }
            .receive(subscriber: self.viewModel.sink)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification, object: nil)
            .sink { _ in
                self.viewModel.cameraManager.start()
            }
            .store(in: &events)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification, object: nil)
            .sink { _ in
                self.viewModel.cameraManager.stop()
            }
            .store(in: &events)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        viewModel.cameraManager.stop()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.cameraManager.start()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        
        addChild(mtkVC)
        view.addSubview(mtkVC.view)
        view.addSubview(toolBar)
        view.addSubview(ratioMenu)
        
        view.addSubview(captureButton)
        captureButton.setTitle("拍照", for: .normal)
        captureButton.setTitleColor(.green, for: .normal)
        
        changeCameraGes.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(changeCameraGes)
        
        self.view.addGestureRecognizer(focusGes)

        swipLeftGes.direction = .left
        swipRightGes.direction = .right
        self.view.addGestureRecognizer(swipLeftGes)
        self.view.addGestureRecognizer(swipRightGes)
        
        ratioMenu.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(toolBar.snp.bottom).offset(30)
            maker.height.equalTo(90)
        }
        
        toolBar.snp.makeConstraints { (maker) in
            maker.top.left.right.equalTo(view.safeAreaLayoutGuide)
            maker.height.equalTo(44)
        }
        
        mtkVC.view.snp.makeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview()
        }
        
        captureButton.snp.makeConstraints { (maker) in
            maker.bottom.equalToSuperview().inset(30)
            maker.size.equalTo(CGSize(width: 50, height: 30))
            maker.centerX.equalToSuperview()
        }
    }
    
    private func bindViewModel() {
        viewModel
            .cameraManager
            .$cameraRatio
            .receive(on: DispatchQueue.main, options: nil)
            .sink { [weak self] _ in
                if self?.ratioMenu.alpha == 1 {
                    UIView.animate(withDuration: 0.3) {
                        self?.ratioMenu.alpha = 0
                    }
                }
            }
            .store(in: &self.events)
        
        ratioMenu
            .ratioChangePublisher
            .map({ MainCameraViewModelAction.changeRatio($0) })
            .receive(subscriber: self.viewModel.sink)
        
        // toolbar 点击
        toolBar
            .clickeObservable
            .sink(receiveValue: { [weak self] action in
                switch action {
                case .clickChangeCamera:
                    let _ = self?.viewModel.sink.receive(.changeCameraPos)
                case .clickRatio:
                    self?.ratioBarAnimation()
                }
            })
            .store(in: &self.events)
        
        // 反转摄像头
        changeCameraGes
            .tapPublisher
            .map({ _ in MainCameraViewModelAction.changeCameraPos })
            .receive(subscriber: self.viewModel.sink)
        
        // 拍照
        
        captureButton
            .actionPublisher
            .map { (btnAction) -> MainCameraViewModelAction in
                switch btnAction {
                case .tap:
                    return .takePhoto
                case .longPress(let state):
                    return .takeVideo(state)
                }
            }
            .receive(subscriber: self.viewModel.sink)
        
        self.viewModel.takePhotoObservable
            .receive(on: DispatchQueue.main, options: nil)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let err):
                    print(err)
                }
            }, receiveValue: { [weak self] image in
                if let self = self {
                    let editorVC = self.editorDependency.makeImageEditorVC(image)
                    editorVC.modalPresentationStyle = .fullScreen
                    self.present(editorVC, animated: true, completion: nil)
                }
            })
            .store(in: &events)
        
        // 变更焦点
        focusGes
            .tapPublisher
            .map { gesture -> MainCameraViewModelAction in
                let point = gesture.location(in: nil)
                return MainCameraViewModelAction.changeFocus(point)
            }
            .receive(subscriber: self.viewModel.sink)
        
        swipLeftGes
            .swipePublisher
            .map { _ in return MainCameraViewModelAction.changeFilter(.left) }
            .receive(subscriber: self.viewModel.sink)
        
        swipRightGes
            .swipePublisher
            .map { _ in return MainCameraViewModelAction.changeFilter(.right) }
            .receive(subscriber: self.viewModel.sink)
    }
    
    private func ratioBarAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.ratioMenu.alpha = abs(self.ratioMenu.alpha - 1)
        })
    }
}
