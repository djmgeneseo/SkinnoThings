//
//  ViewController.swift
//  Text Detection Starter Project
//
//  Created by Sai Kambampati on 6/21/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

// https://www.appcoda.com/vision-framework-introduction/

/* There are 3 steps to implement Vision in your app, whic are:

    Requests – Requests are when you request the framework to detect something for you.
    Handlers – Handlers are when you want the framework to perform something after the request is made or “handle” the request.
    Observations – Observations are what you want to do with the data provided with you.
 
*/

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    // initializes an object of AVCaptureSession that performs a real-time or offline capture. (requisite when performing actions based on a live stream)
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        startLiveVideo()
        startTextDetection()
    }
    
    //the bounds of the image view is not yet finalized in viewWillAppear()
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }

    // connect the session to our device.
    func startLiveVideo() {
        //1 We begin by modifying the settings of our AVCaptureSession. Then, we set the AVMediaType as video because we want a live stream so it should always be continuously running.
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        //2 Next, we define the device input and output. The input is what the camera is seeing and the output is what the video should appear as. We want the video to appear as a kCVPixelFormatType_32BGRA which is a type of video format. You can learn more about pixel format types here. Lastly, we add the input and output to the AVCaptureSession.
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        //3 Finally, we add a sublayer containing the video preview to the imageView and get the session running.
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
        
        session.startRunning()
    }
    
    // In this function, we create a constant textRequest that is a VNDetectTextRectanglesRequest. Basically it is just a specific type of VNRequest that only looks for rectangles with some text in them. When the framework has completed this request, we want it to call the function detectTextHandler. We also want to know exactly what the framework has recognized which is why we set the property reportCharacterBoxes equal to true. Finally, we set the variable requests created earlier to textRequest.
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
    }
    
    // we begin by defining a constant observations which will contain all the results of our VNDetectTextRectanglesRequest. Next, we define another constant named result which will go through all the results of the request and transform them into the type of VNTextObservation.
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }
        
        let result = observations.map({$0 as? VNTextObservation})
        
        // handle result of request:
        // We begin by having the code run asynchronously. First, we remove the bottommost layer in our imageView (if you noticed, we were adding a lot of layers to our imageView). Next, we check to see if a region exists within the results from our VNTextObservation. Now, we call in our function which draws a box around the region, or as we defined it, the word. Then, we check to see if there are character boxes within the region. If there are, we call in the function which draws a box around each letter.
        DispatchQueue.main.async() {
            self.imageView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {
                    continue
                }
                
                self.highlightWord(box: rg)
                
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        self.highlightLetters(box: characterBox)
                    }
                }
            }
        } //DispatchQueue.main.async()
        
    }
    
    //while we told the VNDetectTextRectanglesRequest to report the character boxes, we never told it how to do so. This is what we’ll accomplish next.
    // In this function we begin by defining a constant named boxes which is a combination of all the characterBoxes our request has found. Then, we define some points on our view to help us position our boxes. Finally, we create a CALayer with the given constraints defined and apply it to our imageView
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }
        
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCord = maxX * imageView.frame.size.width
        let yCord = (1 - minY) * imageView.frame.size.height
        let width = (minX - maxX) * imageView.frame.size.width
        let height = (minY - maxY) * imageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        
        imageView.layer.addSublayer(outline)
    }
    
    
    // Next, let’s create the boxes for each letter. Similar to the code we wrote earlier, we use the VNRectangleObservation to define our constraints that will make outlining the box easier. Now, we have all our function laid out. The final step is connecting all the dots.
    func highlightLetters(box: VNRectangleObservation) {
        let xCord = box.topLeft.x * imageView.frame.size.width
        let yCord = (1 - box.topLeft.y) * imageView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * imageView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * imageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        imageView.layer.addSublayer(outline)
    }
    
} //ViewController

// Now the last step in connecting the dots is to run our Vision code with the live stream. We need to take the video output and convert it into a CMSampleBuffer. It’s our last part of the code. The extension adopts the AVCaptureVideoDataOutputSampleBufferDelegate protocol. Basically what this function does is that it checks if the CMSampleBuffer exists and is giving an AVCaptureOutput. Next, we create a variable requestOptions which is a dictionary for the type VNImageOption. VNImageOption is a type of structure that can hold the properties and data from the camera. Finally we create a VNImageRequestHandler object and perform the text request that we create earlier.
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}

