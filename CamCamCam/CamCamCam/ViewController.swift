//
//  ViewController.swift
//  CamCam
//
//  Created by sonson on 2023/07/13.
//

import UIKit
import AVKit

func UIImageFromCMSamleBuffer(buffer:CMSampleBuffer, flip: Bool = false)-> UIImage? {
    let pixelBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(buffer)!
    var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    if flip {
        ciImage = ciImage.oriented(.downMirrored)
    }
    let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
    let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
    let imageRect:CGRect = CGRectMake(0,0,pixelBufferWidth, pixelBufferHeight)
    let ciContext = CIContext.init()
    if let cgimage = ciContext.createCGImage(ciImage, from: imageRect ) {
        return UIImage(cgImage: cgimage)
    }
    return nil
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let session = AVCaptureMultiCamSession()
    
    var captureOutputs: [AVCaptureVideoDataOutput] = []
    
    var imageViews: [UIImageView] = []
    
    func addcamera(device: AVCaptureDevice) -> AVCaptureVideoDataOutput? {
        session.beginConfiguration()

        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            session.addInput(deviceInput)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            let cameraQueue = DispatchQueue(label: "camera")
            output.setSampleBufferDelegate(self, queue: cameraQueue)
            output.alwaysDiscardsLateVideoFrames = true
            session.addOutput(output)

            session.commitConfiguration()

            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
            device.unlockForConfiguration()
            return output
            
        } catch {
            print(error)
            return nil
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if let output = output as? AVCaptureVideoDataOutput {
            if let index = self.captureOutputs.firstIndex(of: output) {
                
                DispatchQueue.main.async {
                    let flip = (index == 1)
                    if let image = UIImageFromCMSamleBuffer(buffer: sampleBuffer, flip: flip) {
                        self.imageViews[index].image = image
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .external], mediaType: .video, position: .unspecified)
        guard discoverySession.devices.count > 0 else { return }
        
        print(discoverySession.devices.count)
        
        if let output = addcamera(device: discoverySession.devices[0]) {
            captureOutputs.append(output)
        }
        if let output = addcamera(device: discoverySession.devices[1]) {
            captureOutputs.append(output)
        }
        if let output = addcamera(device: discoverySession.devices[2]) {
            captureOutputs.append(output)
        }
        if let output = addcamera(device: discoverySession.devices[3]) {
            captureOutputs.append(output)
        }
    
        Task.detached(priority: .userInitiated) {
            self.session.startRunning()
        }
        
        let h = self.view.frame.size.height
        let w = self.view.frame.size.width
        
        let imageView1 = UIImageView(frame: CGRect(x: 0, y: 0, width: w/2, height: h/2))
        imageView1.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imageView1)
        self.imageViews.append(imageView1)
            
        let imageView2 = UIImageView(frame: CGRect(x: w/2, y: 0, width: w/2, height: h/2))
        imageView2.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imageView2)
        self.imageViews.append(imageView2)
        
        let imageView3 = UIImageView(frame: CGRect(x: 0, y: h/2, width: w/2, height: h/2))
        imageView3.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imageView3)
        self.imageViews.append(imageView3)
        
        let imageView4 = UIImageView(frame: CGRect(x: w/2, y: h/2, width: w/2, height: h/2))
        imageView4.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imageView4)
        self.imageViews.append(imageView4)
    }
}

