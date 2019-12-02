//
//  ViewController.swift
//  PhotoAlbumPortfolio2
//
//  Created by Gheta on 24/03/2019.
//  Copyright © 2019 Mohammed Omer. All rights reserved.
//

// importing relevant libraries
import UIKit
import CoreML
import Vision
import AVKit

// Main view controller
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    

    // Sharing button which allows user to share photo on social platforms
    @IBAction func sharingButton(_ sender: Any) {
        let activityItem: [AnyObject] = [self.displayImage.image ?? displayImage, detectLabel.text  as AnyObject,  faceLabel.text  as AnyObject]
        let avc = UIActivityViewController(activityItems: activityItem as [AnyObject], applicationActivities: nil)
        self.present(avc, animated: true, completion: nil)
    }
    
    // Model used: VGG15
    let model = VGG16()

    // Audio button which plays text displayed on the screen
    @IBAction func audioButton(_ sender: Any) {
        self.ReadText(myText: detectLabel.text!, myLang: "en-US")
        self.ReadText(myText: faceLabel.text!, myLang: "en-US")
    }
    
    // Read text function
    func ReadText(myText: String, myLang: String){
        let utterance = AVSpeechUtterance(string: myText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
    // Live detection button which heads onto the live detection page
    @IBAction func liveDetection(_ sender: Any) {
        performSegue(withIdentifier: "secondPageIdentifier", sender: self)
    }
    
    // Image view that displays the image
    @IBOutlet weak var displayImage: UIImageView!
    
    // Photo button to improt a photo from user gallery
    @IBAction func photoButton(_ sender: Any) {
        getphoto()
    }

    
    // Detetct object button which detects object in the image
    @IBAction func detectObjectButton(_ sender: Any) {
        guard let image = displayImage.image, let ciImage = CIImage(image: image) else {
            return
            
        }
        
        objectDetection(image: ciImage)
        
    }
    
    
    // Save function which saves the photo onto the gallery
    @IBAction func savingPhoto(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(self.displayImage.image!, nil, "image:didFinishSavingWithError:contextInfo:", nil)

    }
    
    // Detect label that detetcts object in image
    @IBOutlet weak var detectLabel: UILabel!
    // Face detection label
    @IBOutlet weak var faceLabel: UILabel!
    
    // Object detetction function
    func objectDetection(image: CIImage){
        detectLabel.text = "Detecting The Object..."
        // Error hndling if object cannot be detetcted
        guard let model = try? VNCoreMLModel(for: model.model) else {fatalError("cannot detect")}
        let request = VNCoreMLRequest(model: model) { (request,error) in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else{fatalError()}
            
            DispatchQueue.main.async {
                self.detectLabel.text = "\(Int(topResult.confidence * 100))% \(topResult.identifier)"
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async{
            do{
                try handler.perform([request])
            }catch{
                print(error)
            }
        }
    }
    
    // Camera functionw which allows user to open up phone camera
    @IBAction func cameraButton(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let alertController = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        // ALert stating camera is not avaiable
        let cancelAction = UIAlertAction(title: "Camera is not available", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        
        // If camera is available take photo alert will show up
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Take Photo", style:.default, handler:{(_) in imagePicker.sourceType = .camera; self.present(imagePicker,animated:true,completion:nil)
        })
            
            alertController.addAction(cameraAction)
        }
        present(alertController, animated: true, completion: nil)
    }
    
    // Get photo function which gets the image
    func getphoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info [.originalImage] as? UIImage else { return }
        displayImage.image = selectedImage
        
        dismiss(animated: true, completion: nil)
        
        identifyFacesWithLandmarks(image: selectedImage)
    }
    
    // Function which checks image to see if faces are detected
    func identifyFacesWithLandmarks(image: UIImage) {
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [ : ])
        
        faceLabel.text = "Detecting the faces..."
        
        let request = VNDetectFaceLandmarksRequest(completionHandler: handleFaceLandmarksRecognition)
        try! handler.perform([request])
    }
    
    
    func handleFaceLandmarksRecognition(request: VNRequest, error: Error?) {
        guard let foundFaces = request.results as? [VNFaceObservation] else {
            fatalError ("Problem loading picture to examine faces")
        }
        
        // Count face function which will siplay how many faces detecteed
        faceLabel.text = "Found \(foundFaces.count) faces"
        
        for faceRectangle in foundFaces {
            
            guard let landmarks = faceRectangle.landmarks else {
                continue
            }
            
            var landmarkRegions: [VNFaceLandmarkRegion2D] = []
            
            if let faceContour = landmarks.faceContour {
                landmarkRegions.append(faceContour)
            }
            if let leftEye = landmarks.leftEye {
                landmarkRegions.append(leftEye)
            }
            if let rightEye = landmarks.rightEye {
                landmarkRegions.append(rightEye)
            }
            if let nose = landmarks.nose {
                landmarkRegions.append(nose)
            }
            
            drawImage(source: displayImage.image!, boundary: faceRectangle.boundingBox, faceLandmarkRegions: landmarkRegions)
            
        }
    }
    
    
    // Drawing picture imported onto UIImage
    func drawImage(source: UIImage, boundary: CGRect, faceLandmarkRegions: [VNFaceLandmarkRegion2D])  {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)
        
        // Doint the color
        var fillColor = UIColor.green
        fillColor.setStroke()
        
        let rectangleWidth = source.size.width * boundary.size.width
        let rectangleHeight = source.size.height * boundary.size.height
        
        context.addRect(CGRect(x: boundary.origin.x * source.size.width, y:boundary.origin.y * source.size.height, width: rectangleWidth, height: rectangleHeight))
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        fillColor = UIColor.red
        fillColor.setStroke()
        context.setLineWidth(2.0)
        for faceLandmarkRegion in faceLandmarkRegions {
            var points: [CGPoint] = []
            for i in 0..<faceLandmarkRegion.pointCount {
                let point = faceLandmarkRegion.normalizedPoints[i]
                let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                points.append(p)
            }
            
            let facialPoints = points.map { CGPoint(x: boundary.origin.x * source.size.width + $0.x * rectangleWidth, y: boundary.origin.y * source.size.height + $0.y * rectangleHeight) }
            context.addLines(between: facialPoints)
            context.drawPath(using: CGPathDrawingMode.stroke)
        }
        
        let modifiedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        displayImage.image = modifiedImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

}

