//
//  ViewController.swift
//  ocrTest
//
//  Created by David Murphy on 12/16/17.
//  Copyright © 2017 David Murphy. All rights reserved.
//

import UIKit
import TesseractOCR

// Protocals: must conform to them (below: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    //MARK: IBAction
    // Every time user clicks "take photo" button in main UI, show options to either choose a picture or to use the camera
    @IBAction func takePhotoButtonPressed(_ sender: Any) {
        // Shows keyboard
        view.endEditing(true)
        presentOption()
    }
    
    func presentOption() {
        
        let imageAction = UIAlertController(title: "Select an option", message: nil, preferredStyle: .actionSheet)
        
        // When user chooses "take photo"
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { (action)
            in
//            print("Camera Selected")
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
            
        }
        
        // When user chooses "choose existing"
        let libraryAction = UIAlertAction(title: "Choose Existing", style: .default) { (action)
            in
//            print("Library")
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        imageAction.addAction(cameraAction)
        imageAction.addAction(libraryAction)
        imageAction.addAction(cancelAction)
        
        // for ipads
        imageAction.popoverPresentationController?.sourceView = self.view
        imageAction.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        imageAction.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)

        present(imageAction, animated: true, completion: nil)
        
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Check if we have an image
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let scaledPhoto = selectedImage.scaleImage(640)
            
                activityIndicator.startAnimating()
                
                dismiss(animated: true, completion:  {
                    // function to recognize the image
                    // optional, so need to unwrap with '!'
                    self.recognizeText(image: scaledPhoto!)
                })
        }
    }
    
    func recognizeText(image: UIImage) {
        // "eng, fra, ger" etc for more languages
        if let tesseract = G8Tesseract(language: "eng") {
            
            tesseract.engineMode = .tesseractCubeCombined
            // read for line breaks
            tesseract.pageSegmentationMode = .auto
            // makes image black and white-helps ocr
            tesseract.image = image.g8_blackAndWhite()
            tesseract.recognize()
            textView.text = tesseract.recognizedText
        }
        activityIndicator.stopAnimating()
    }
}

// add another function to this class
extension UIImage {
    
    // the new function: scale an image
    func scaleImage(_ maxDimension: CGFloat) -> UIImage? {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        
        // "size" refers to image's size/height
        if size.width > size.height {
            // If image is landscape(?)
            let scaleFactor = size.height / size.width
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            // if image is portrait(?)
            let scaleFactor = size.width / size.height
            scaledSize.width = scaledSize.height * scaleFactor
        }
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}
