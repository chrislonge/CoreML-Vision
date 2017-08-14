//
//  ViewController.swift
//  VisionMLStarter
//
//  Created by Longe, Chris on 8/13/17.
//  Copyright © 2017 Longe, Chris. All rights reserved.
//

import UIKit
// Import Core ML and Vision frameworks
import CoreML
import Vision

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    // Step 1. Connect Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var modelSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Step 5. Grab CIImage from UIImageView and run the detect object or scene function.
        guard
            let image = imageView.image,
            let ciImage = CIImage(image: image) else {
            fatalError("Couldn't convert UIImage to CIImage")
        }
        
        detectScene(image: ciImage)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    // Step 2. Create Image Picker Action
    @IBAction func selectImageTouched(_ sender: UIButton) {
        
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .savedPhotosAlbum
        present(pickerController, animated: true)
    }
    
    // Step 6. Add Segemented Control Action
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        
        guard
            let image = imageView.image,
            let ciImage = CIImage(image: image) else {
                fatalError("Couldn't convert UIImage to CIImage")
        }
        detectScene(image: ciImage)
    }
}

// Leave this protocol blank. It is required for the UIImagePickerController
extension ViewController: UINavigationControllerDelegate {
}

// Step 3. Implement UIImagePickerControllerDelegate in an Extension
extension ViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("couldn't load image from Photos")
        }
        
        imageView.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("Couldn't convert UIImage to CIImage")
        }
        
        dismiss(animated: true)
        
        // TODO: Call function to detect object or scenen in image.
        detectScene(image: ciImage)
    }
}

// Step 4. Write function that detects the dominant objects or the scene of an image in an extension.
extension ViewController {
    
    func detectScene(image: CIImage) {
        resultLabel.text = "Detecting scene..."
        
        // A: Create a Core ML Model based on segmented control
        var mlModel: VNCoreMLModel!
        
        if modelSegmentedControl.selectedSegmentIndex == 0 {
            guard let model = try? VNCoreMLModel(for: GoogLeNetPlaces().model) else {
              fatalError("Couldn't load GoogLeNetPlaces ML model")
            }
            mlModel = model
        } else {
            guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
                fatalError("Couldn't load Resnet50 ML model")
            }
            mlModel = model
        }
        
        // B: Create a Vision request
        let request = VNCoreMLRequest(model: mlModel) { request, error in
            guard
                let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("Unexpected result type from VNCoreMLRequest")
            }
            
            DispatchQueue.main.async {
                self.resultLabel.text = "\(topResult.identifier). Confidence: \(Int(topResult.confidence * 100))%"
            }
        }
        
        // C: Create and Run a request handler
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
}
