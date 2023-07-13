//
//  ViewController.swift
//  ContinuityCamera
//
//  Created by sonson on 2023/07/10.
//

import UIKit
import AVKit

class ViewController: UIViewController, AVContinuityDevicePickerViewControllerDelegate {
    
    let session = AVCaptureSession()
    let previewLayer = AVPlayerViewController()

    private func authorize() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        // Determine if the user has previously authorized camera access.
        var isAuthorized = status == .authorized
        // If the system hasn't determined the user's authorization status,
        // explicitly prompt them for approval.
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        return isAuthorized
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            guard await authorize() else { return }
            if !session.isRunning {
                let vc = AVContinuityDevicePickerViewController()
                vc.delegate = self
                self.show(vc, sender: nil)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        print(#function)
        super.viewDidAppear(animated)
        
    }
    
    func continuityDevicePicker(_ pickerViewController: AVContinuityDevicePickerViewController, didConnect device: AVContinuityDevice) {
        print(pickerViewController)
        print(device)
        
        guard let device = device.videoDevices.first else { return }
        
        session.beginConfiguration()

        do {
            defer {
                session.commitConfiguration()
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
            previewLayer.backgroundColor = UIColor.black.cgColor
            previewLayer.frame = self.view.layer.frame
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.view.layer.addSublayer(previewLayer)
            Task {
                session.startRunning()
            }
        } catch {
            print(error)
        }
    }
}

