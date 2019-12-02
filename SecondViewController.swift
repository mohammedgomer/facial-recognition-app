//
//  ViewController.swift
//  PhotoAlbumPortfolio2
//
//  Created by Gheta on 24/03/2019.
//  Copyright © 2019 Mohammed Omer. All rights reserved.

// Relevant libraries
import UIKit
import AVKit
import CoreML
import Vision

// Second view controller for the live detection page
class SecondViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Live detection label that displays the text of the object that is detected
    @IBOutlet weak var liveDetector: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Getting the live video capture
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // Constant for capturedevice
        guard let captureDevice = AVCaptureDevice.default(for: .video) else
        {
            return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else
        {
            return
        }
        
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        
        setupIdentifierConfidenceLabel()
    }
    
    
    fileprivate func setupIdentifierConfidenceLabel() {
        view.addSubview(liveDetector)
        liveDetector.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        liveDetector.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        liveDetector.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        liveDetector.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    // Capture output function
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else
        {
            return
        }
        
        guard let mobileNetModel = try? VNCoreMLModel (for: VGG16().model)
            else
        {
            return
        }
        let request = VNCoreMLRequest(model: mobileNetModel)
        { (finishedReq, err) in
            
            
            guard let results = finishedReq.results as?
                [VNClassificationObservation]
                else {
                    return
            }
            guard let firstObservation = results.first else
            {
                return
            }
            
            print(firstObservation.identifier, firstObservation.confidence)
            
            DispatchQueue.main.async {
                // Displaying label for the live detetction and percentage
                self.liveDetector.text = "\(firstObservation.confidence * 100)%\(firstObservation.identifier)"
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
}
