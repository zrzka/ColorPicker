//
//  PickerViewController.swift
//  ColorPicker
//
//  Created by Robert Vojta on 07.10.15.
//  Copyright © 2015 Robert Vojta. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController {
    @IBOutlet var pickerPlaceholder: UIView!
    @IBOutlet var selectedColorView: UIView!
    @IBOutlet var selectedColorLabel: UILabel!
    @IBOutlet var forceTouchActiveLabel: UILabel!
    
    let pickerView = ColorPicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedColorLabel.text = nil
        forceTouchActiveLabel.alpha = 0.0
        
        selectedColorView.layer.borderColor = UIColor.blackColor().CGColor
        selectedColorView.layer.borderWidth = 1.0
        
        pickerPlaceholder.addSubview(pickerView)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.centerXAnchor.constraintEqualToAnchor(pickerPlaceholder.centerXAnchor).active = true
        pickerView.centerYAnchor.constraintEqualToAnchor(pickerPlaceholder.centerYAnchor).active = true
        
        pickerView.didChangeColor = { [weak self] color in
            self?.selectedColorView.backgroundColor = color
            
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            
            if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil) {
                let h = Int(hue * 360)
                let s = Int(saturation * 100)
                let b = Int(brightness * 100)
                
                self?.selectedColorLabel.text = "HSB \(h)° \(s)% \(b)%"
                self?.forceTouchActiveLabel.alpha = 1.0 - brightness
            }
            
        }
        pickerView.didChangeColor?(pickerView.color)
    }
}

