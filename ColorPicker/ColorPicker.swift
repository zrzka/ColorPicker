//
//  ColorPicker.swift
//  ColorPicker
//
//  Created by Robert Vojta on 07.10.15.
//  Copyright © 2015 Robert Vojta. All rights reserved.
//

import UIKit

// MARK: - Color Picker

public class ColorPicker: UIView {
    public var didChangeColor: ((UIColor) -> Void)?
    public var color: UIColor {
        return pickedColor
    }
    
    private let padding: CGFloat = 8.0
    
    private let wheel = WheelView()
    private let brightnessBar = BrightnessBar()
    
    private var pickedColor = UIColor.whiteColor() { didSet { didChangeColor?(color) } }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        addSubview(brightnessBar)
        
        brightnessBar.translatesAutoresizingMaskIntoConstraints = false
        brightnessBar.backgroundColor = UIColor.whiteColor()
        brightnessBar.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: padding).active = true
        brightnessBar.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -padding).active = true
        brightnessBar.topAnchor.constraintEqualToAnchor(topAnchor, constant: padding).active = true
        
        addConstraint(NSLayoutConstraint(item: brightnessBar, attribute: .Height, relatedBy: .Equal,
            toItem: nil, attribute: .NotAnAttribute,
            multiplier: 1.0, constant: 40.0))
        
        addSubview(wheel)
        
        wheel.translatesAutoresizingMaskIntoConstraints = false
        wheel.backgroundColor = UIColor.whiteColor()
        wheel.topAnchor.constraintEqualToAnchor(brightnessBar.bottomAnchor, constant: padding).active = true
        wheel.leadingAnchor.constraintEqualToAnchor(brightnessBar.leadingAnchor).active = true
        wheel.trailingAnchor.constraintEqualToAnchor(brightnessBar.trailingAnchor).active = true
        addConstraint(NSLayoutConstraint(item: wheel, attribute: .Height, relatedBy: .Equal,
            toItem: wheel, attribute: .Width, multiplier: 1.0, constant: 0))
        
        wheel.didChangeWheelColor = { [weak self] color in
            self?.brightnessBar.color = color
            self?.pickedColor = UIColor(hue: color.0 / 360.0, saturation: color.1, brightness: color.2, alpha: CGFloat(1.0))
        }
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(320.0, 320.0 + 40.0 + padding)
    }
}

// MARK: Brightness Bar

private class BrightnessBar: UIView {
    var color: (CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 1.0) { didSet { setNeedsDisplay() } }
    
    override func drawRect(rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        CGContextSaveGState(ctx)
        let x = color.2 * CGRectGetWidth(bounds) + CGRectGetMinX(bounds)
        let lineRect = CGRectMake(x, CGRectGetMinY(bounds), 1.0, CGRectGetHeight(bounds))
        CGContextAddPath(ctx, CGPathCreateWithRect(lineRect, nil))
        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextDrawPath(ctx, .Stroke)
        CGContextRestoreGState(ctx)
        
        CGContextSaveGState(ctx)
        let colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB)
        let path = CGPathCreateWithRect(CGRectInset(bounds, 0, CGFloat(4)), nil)
        CGContextAddPath(ctx, path)
        CGContextClip(ctx)
        
        let leftPoint = CGPointMake(CGRectGetMinX(bounds), CGRectGetMidY(bounds))
        let rightPoint = CGPointMake(CGRectGetMaxX(bounds), CGRectGetMidY(bounds))
        let leftColor = UIColor(hue: color.0 / 360.0, saturation: color.1, brightness: 0, alpha: 1)
        let rightColor = UIColor(hue: color.0 / 360.0, saturation: color.1, brightness: 1, alpha: 1)
        var locations: [CGFloat] = [0, 1]
        
        let gradient = CGGradientCreateWithColors(colorSpace,
            [leftColor.CGColor, rightColor.CGColor],
            &locations)
        
        CGContextDrawLinearGradient(ctx, gradient, leftPoint, rightPoint, [])
        CGContextRestoreGState(ctx)
    }
}

// MARK: WheelView

private class WheelView: UIView {
    var wheelRadius: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var wheelCenter: CGPoint = CGPointMake(0, 0) { didSet { setNeedsDisplay() } }
    
    var didChangeWheelColor: (((CGFloat, CGFloat, CGFloat)) -> Void)?
    var wheelColor: (CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 1.0) { didSet { didChangeWheelColor?(wheelColor) } }
    
    let crossImageView = UIImageView(image: UIImage(named: "cross"))
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let point = touch.locationInView(self)
        
        guard let color = color(atPoint: point) else {
            return
        }
        
        var brightness: CGFloat = 1.0
        
        if touch.maximumPossibleForce > 0 {
            // Ignore first 15% of maximumPossibleForce
            let trigger: CGFloat = touch.maximumPossibleForce * 0.15
            
            if touch.force >= trigger {
                // Ignore first & last 15% of maximumPossibleForce, rest is used to calculate
                // brightness, iow 15% ... 85% -> 1.0 ... 0.0
                var force = ( touch.force - trigger ) / ( touch.maximumPossibleForce - 2.0 * trigger )
                brightness = 1.0 - force.clamp(0, 1)
            }
        }
        
        wheelColor = (color.0, color.1, brightness)
        crossImageView.center = point
    }
    
    func color(atPoint point: CGPoint) -> (CGFloat, CGFloat, CGFloat)? {
        if wheelRadius <= 0 {
            return nil
        }
        
        let centerDistance = sqrt(pow(point.x - wheelCenter.x, 2) + pow(point.y - wheelCenter.y, 2))
        
        if centerDistance > wheelRadius {
            return nil
        }
        
        let saturation = centerDistance / wheelRadius
        
        var angle = atan2(point.y - wheelCenter.y, point.x - wheelCenter.x)
        if angle < 0 {
            angle = CGFloat(M_PI * 2.0) - abs(angle)
        }
        let hue = radiansToHue(CGFloat(angle))
        
        return (hue, saturation, 1.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        wheelRadius = CGRectGetWidth(bounds) / 2.0
        wheelCenter = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        
        if crossImageView.superview == nil {
            addSubview(crossImageView)
            crossImageView.center = wheelCenter
        }
    }
    
    override func drawRect(rect: CGRect) {
        // Don't use in production, it's optimized Hue Saturation wheel drawing
        guard let ctx = UIGraphicsGetCurrentContext() where wheelRadius > 0 else {
            return
        }
        
        let colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB)
        
        var hue: CGFloat = 0
        let hueStep: CGFloat = 0.5
        
        while hue < 360.0 {
            CGContextSaveGState(ctx)
            
            let hueRadians = hueToRadians(hue)
            let leftHueRadians = hueToRadians(hue - hueStep / 2.0)
            let rightHueRadians = hueToRadians(hue + hueStep / 2.0)
            
            // Clipping path for gradient
            
            let bezierPath = UIBezierPath(arcCenter: wheelCenter, radius: wheelRadius,
                startAngle: leftHueRadians, endAngle: rightHueRadians,
                clockwise: true)
            bezierPath.addLineToPoint(wheelCenter)
            
            CGContextAddPath(ctx, bezierPath.CGPath)
            CGContextClip(ctx)
            
            // Gradient
            
            let x = wheelCenter.x + wheelRadius * CGFloat(cos(hueRadians))
            let y = wheelCenter.y + wheelRadius * CGFloat(sin(hueRadians))
            
            let wheelPoint = CGPointMake(x, y)
            
            let centerColor = UIColor(hue: hue / 360.0, saturation: 0.0, brightness: 1.0, alpha: 1.0)
            let wheelColor = UIColor(hue: hue / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            var locations: [CGFloat] = [0, 1]
            
            let gradient = CGGradientCreateWithColors(colorSpace,
                [centerColor.CGColor, wheelColor.CGColor],
                &locations)
            
            CGContextDrawLinearGradient(ctx, gradient, wheelCenter, wheelPoint, [])
            
            CGContextRestoreGState(ctx)
            hue += hueStep
        }
    }
}


// MARK: - Utils

private extension Comparable {
    mutating func clamp(minimum: Self, _ maximum: Self) -> Self {
        if self < minimum { self = minimum }
        if self > maximum { self = maximum }
        return self
    }
}

private func hueToRadians(hue: CGFloat) -> CGFloat {
    return CGFloat(Double(hue) * M_PI / 180.0)
}

private func radiansToHue(radians: CGFloat) -> CGFloat {
    return CGFloat(Double(radians) / ( M_PI / 180.0 ))
}
