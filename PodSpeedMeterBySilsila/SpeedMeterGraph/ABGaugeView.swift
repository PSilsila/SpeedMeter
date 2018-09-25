//
//  ABGaugeView.swift
//  ABGaugeViewKit
//
//  Created by Ajay Bhanushali on 02/03/18.
//  Copyright © 2018 Aimpact. All rights reserved.
//

import Foundation
import UIKit

struct ArcModel {
    var startAngle: CGFloat!
    var endAngle: CGFloat!
    var strokeColor: UIColor!
    var arcCap: CGLineCap!
    var center: CGPoint!
}

@IBDesignable
public class SpeedMeterGraph: UIView {
    
    // MARK:- @IBInspectable
    /// Send number of Colors
    @IBInspectable public var colorCodes: String = "929918,C8CC86,66581A,185D99,66581A" // number of colors and areas should equal
    
    /// Send number of division
    @IBInspectable public var areas: String = "40,20,10,20,10"
    
    /// Set the way arc will visible
    @IBInspectable public var arcAngle: CGFloat = 1.8 // 0.9 //1.8 //2.7 //3.6
    
    /// Set color of needle
    @IBInspectable public var needleColor: UIColor = UIColor(red: 255, green: 138/255, blue: 72/255, alpha: 1.0)
    
    /// Set needle value where needle will stop
    @IBInspectable public var needleValue: CGFloat = 0 {
        didSet {
            //needleValue = min(maximumValue, max(minimumValue, needleValue))
        }
    }
    
    @IBInspectable public var applyShadow: Bool = true {
        didSet {
            shadowColor = applyShadow ? shadowColor : UIColor.clear
        }
    }
    
    /// set style of start and end point of arc (square or butt)
    @IBInspectable public var isSquareCap: Bool = true {
        didSet {
            capStyle = isSquareCap ? .square : .butt
        }
    }
    
    ///
    @IBInspectable public var blinkAnimate: Bool = false
    
    ///Set middle circle color
    @IBInspectable public var circleColor: UIColor = UIColor(red: 255, green: 138/255, blue: 72/255, alpha: 1.0)
    
    ///
    @IBInspectable public var shadowColor: UIColor = UIColor.lightGray.withAlphaComponent(0.3)
    
    ///
    var needleScore: CGFloat = 0
    
    ///
    @IBInspectable public var scoreLblFontSize: CGFloat = 25
    
    ///
    @IBInspectable public var scoreLblFont: UIFont = UIFont(name: "Farah", size: 0)!
    
    ///
    @IBInspectable public var rangeLblFont: UIFont = UIFont(name: "Helvetica-Bold", size: 14)!
    
    ///
    @IBInspectable public var rangeLblTextColor: UIColor = UIColor.black
    
    ///
    @IBInspectable public var needleAnimationRequire: Bool = false
    
    ///
    var firstAngle = CGFloat()
    
    ///
    var capStyle = CGLineCap.square
    
    ///
    public var minimumValue: CGFloat = 50 {
        didSet {
            //needleValue = max(minimumValue, needleValue)
        }
    }
    
    ///
    public var maximumValue: CGFloat = 500 {
        didSet {
            //needleValue = min(maximumValue, needleValue)
        }
    }
    
    ///
    var granularity: CGFloat = 100
    
    ///
    var maxVal: CGFloat = 0.0
    
    // MARK:- UIView Draw method
    ///
    override public func draw(_ rect: CGRect) {
        drawGauge()
    }
    
    // MARK:- Custom Methods
    ///
    func drawGauge() {
        layer.sublayers = []
        drawSmartArc()
        drawNeedle()
        drawNeedleCircle(withScore: "\(needleScore)")
    }
    
    ///
    func drawSmartArc() {
        var numberOfDiv: Int = 0
        var angles = getAllAngles()
        let arcColors = colorCodes.components(separatedBy: ",")
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        var angle = CGFloat.pi
        if granularity > 0 {
            let numberOfDivv = (maximumValue - minimumValue) / granularity
            let decimalValue = numberOfDivv.truncatingRemainder(dividingBy: 1)
            print(decimalValue)
            if decimalValue > 0 {
                numberOfDiv = Int((maximumValue - minimumValue) / granularity) + 1
            } else {
                numberOfDiv = Int((maximumValue - minimumValue) / granularity)
            }
            var minValue = minimumValue
            for _ in 0...numberOfDiv {
                let point = center.getPointWith(distance: bounds.width / 2 + 10, angle: angle)
                let rangeLbl = UILabel()
                rangeLbl.font = rangeLblFont
                rangeLbl.textColor = rangeLblTextColor
                    rangeLbl.text = "\(Int(minValue))"
                guard let maxValCGfloat = NumberFormatter().number(from: rangeLbl.text!) else { return }
                maxVal = CGFloat(truncating: maxValCGfloat)
                minValue = minValue + granularity
                rangeLbl.textAlignment = .center
                rangeLbl.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
                rangeLbl.center = point
                rangeLbl.transform = CGAffineTransform(rotationAngle: angle - (.pi * 3 / 2))
                self.addSubview(rangeLbl)
                angle += (.pi / CGFloat(numberOfDiv))
                print(point)
            }
        } else {
            print("Please enter gratularity positive value!!!!")
        }
        
        var arcs = [ArcModel(startAngle: angles[0],
                             endAngle: angles.last!,
                             strokeColor: shadowColor,
                             arcCap: CGLineCap.square,
                             center:CGPoint(x: bounds.width / 2, y: (bounds.height / 2)+5))]
        
        for index in 0..<arcColors.count {
            let arc = ArcModel(startAngle: angles[index], endAngle: angles[index+1],
                               strokeColor: UIColor(hex: arcColors[index]),
                               arcCap: CGLineCap.butt,
                               center: center)
            arcs.append(arc)
        }
        arcs.rearrange(from: arcs.count-1, to: 2)
        arcs[1].arcCap = self.capStyle
        arcs[2].arcCap = self.capStyle
        for i in 0..<arcs.count {
            createArcWith(startAngle: arcs[i].startAngle, endAngle: arcs[i].endAngle, arcCap: arcs[i].arcCap, strokeColor: arcs[i].strokeColor, center: arcs[i].center)
        }
        
        if blinkAnimate {
            blink()
        }
    }
    
    func radian(for area: CGFloat) -> CGFloat {
        let degrees = arcAngle * area
        let radians = degrees * .pi/180
        return radians
    }
    
    func getAllAngles() -> [CGFloat] {
        var angles = [CGFloat]()
        firstAngle = radian(for: 0) + .pi/2
        var lastAngle = radian(for: 100) + .pi/2
        
        let degrees:CGFloat = 3.6 * 100
        let radians = degrees * .pi/(1.8*100)
        
        let thisRadians = (arcAngle * 100) * .pi/(1.8*100)
        let theD = (radians - thisRadians)/2
        firstAngle += theD
        lastAngle += theD
        
        angles.append(firstAngle)
        let allAngles = self.areas.components(separatedBy: ",")
        for index in 0..<allAngles.count {
            let n = NumberFormatter().number(from: allAngles[index])
            let angle = radian(for: CGFloat(truncating: n!)) + angles[index]
            angles.append(angle)
        }
        
        angles.append(lastAngle)
        return angles
    }
    
    func createArcWith(startAngle: CGFloat, endAngle: CGFloat, arcCap: CGLineCap, strokeColor: UIColor, center:CGPoint) {
        // 1
        let center = center
        let radius: CGFloat = max(bounds.width, bounds.height)/2 - self.frame.width/20
        let lineWidth: CGFloat = self.frame.width/10
        // 2
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        // 3
        path.lineWidth = lineWidth
        path.lineCapStyle = arcCap
        strokeColor.setStroke()
        path.stroke()
    }
    
    func drawNeedleCircle(withScore score: String) {
        // 1
        let circleLayer = CAShapeLayer()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 1.8), radius: self.bounds.width/5, startAngle: CGFloat(Double.pi), endAngle: CGFloat(2 * Double.pi), clockwise: true)
        // 2
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = circleColor.cgColor
        layer.addSublayer(circleLayer)
        
        // 3
        let scoreLable = CATextLayer()
        scoreLable.string = score
        scoreLable.font = scoreLblFont.fontName as CFTypeRef
        scoreLable.fontSize = scoreLblFontSize
        scoreLable.alignmentMode = "center"
        scoreLable.frame = CGRect(x: (bounds.width / 2) - 40, y: bounds.height / 2 - 20, width: 80, height: 35)
        circleLayer.addSublayer(scoreLable)
    }
    
    func drawNeedle() {
        var needleValueInRad: CGFloat = 0.0
        // 1
        let triangleLayer = CAShapeLayer()
        let shadowLayer = CAShapeLayer()
        
        // 2
        triangleLayer.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y + 5, width: bounds.width, height: bounds.height-15)
        shadowLayer.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y + 5, width: bounds.width, height: bounds.height-15)
        
        // 3
        let needlePath = UIBezierPath()
        needlePath.move(to: CGPoint(x: self.bounds.width/2, y: self.bounds.width * 0.95))
        needlePath.addLine(to: CGPoint(x: self.bounds.width * 0.47, y: self.bounds.width * 0.42))
        needlePath.addLine(to: CGPoint(x: self.bounds.width * 0.53, y: self.bounds.width * 0.42))
        
        needlePath.close()
        
        // 4
        triangleLayer.path = needlePath.cgPath
        shadowLayer.path = needlePath.cgPath
        
        // 5
        triangleLayer.fillColor = needleColor.cgColor
        triangleLayer.strokeColor = needleColor.cgColor
        shadowLayer.fillColor = shadowColor.cgColor
        // 6
        layer.addSublayer(shadowLayer)
        layer.addSublayer(triangleLayer)
        
        var firstAngle = radian(for: 0)
        
        let degrees:CGFloat = 3.6 * 100 // Entire Arc is of 240 degrees
        let radians = degrees * .pi / (1.8 * 100)
        let thisRadians = (arcAngle * 100) * .pi / (1.8 * 100)
        let theD = (radians - thisRadians) / 2
        firstAngle += theD
        if maxVal < needleValue {
            needleValue = maxVal
        }
        needleScore = needleValue
        let numberOfDivv = (maximumValue - minimumValue) / granularity
        let decimalValue = numberOfDivv.truncatingRemainder(dividingBy: 1)
        if decimalValue > 0 {
            needleValueInRad = radian(for: (self.needleValue - minimumValue) * 100 / (maximumValue)) + firstAngle
        } else {
            needleValueInRad = radian(for: (self.needleValue - minimumValue) * 100 / (maximumValue - minimumValue)) + firstAngle
        }
        if needleValueInRad <= firstAngle {
            needleValueInRad = firstAngle
        }
        if needleAnimationRequire {
            animate(triangleLayer: triangleLayer, shadowLayer: shadowLayer, fromValue: 0, toValue: needleValueInRad * 1.05, duration: 0.5) {
                self.animate(triangleLayer: triangleLayer, shadowLayer: shadowLayer, fromValue: needleValueInRad * 1.05, toValue: needleValueInRad * 0.95, duration: 0.4, callBack: {
                    self.animate(triangleLayer: triangleLayer, shadowLayer: shadowLayer, fromValue: needleValueInRad * 0.95, toValue: needleValueInRad, duration: 0.6, callBack: {})
                })
            }
        } else {
            animate(triangleLayer: triangleLayer, shadowLayer: shadowLayer, fromValue: 0, toValue: needleValueInRad*1.05, duration: 0) {
                self.animate(triangleLayer: triangleLayer, shadowLayer: shadowLayer, fromValue: needleValueInRad, toValue: needleValueInRad, duration: 0, callBack: {})
            }
        }
    }
    
    func blink() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.2
        animation.duration = 0.1
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        animation.autoreverses = true
        animation.repeatCount = 3
        self.layer.add(animation, forKey: "opacity")
    }
    
    func animate(triangleLayer: CAShapeLayer, shadowLayer:CAShapeLayer, fromValue: CGFloat, toValue:CGFloat, duration: CFTimeInterval, callBack:@escaping ()->Void) {
        // 1
        CATransaction.begin()
        let spinAnimation1 = CABasicAnimation(keyPath: "transform.rotation.z")
        spinAnimation1.fromValue = fromValue//radian(for: fromValue)
        spinAnimation1.toValue = toValue//radian(for: toValue)
        spinAnimation1.duration = duration
        spinAnimation1.fillMode = kCAFillModeForwards
        spinAnimation1.isRemovedOnCompletion = false
        
        CATransaction.setCompletionBlock {
            callBack()
        }
        // 2
        triangleLayer.add(spinAnimation1, forKey: "indeterminateAnimation")
        shadowLayer.add(spinAnimation1, forKey: "indeterminateAnimation")
        CATransaction.commit()
    }
}

extension CGPoint {
    func getPointWith(distance: CGFloat, angle: CGFloat) -> CGPoint {
        let rx = x + distance * cos(angle)
        let ry = y + distance * sin(angle)
        return CGPoint(x: rx, y: ry)
    }
}

extension Array {
    mutating func rearrange(from: Int, to: Int) {
        precondition(from != to && indices.contains(from) && indices.contains(to), "invalid indexes")
        insert(remove(at: from), at: to)
    }
}

extension UIColor {
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha:1)
    }
    
    convenience init(hex: String, alpha: CGFloat) {
        var hexWithoutSymbol = hex
        if hexWithoutSymbol.hasPrefix("#") {
            hexWithoutSymbol = String(hexWithoutSymbol.dropFirst())
        }
        
        let scanner = Scanner(string: hexWithoutSymbol)
        var hexInt:UInt32 = 0x0
        scanner.scanHexInt32(&hexInt)
        
        var r:UInt32!, g:UInt32!, b:UInt32!
        switch (hexWithoutSymbol.count) {
        case 3: // #RGB
            r = ((hexInt >> 4) & 0xf0 | (hexInt >> 8) & 0x0f)
            g = ((hexInt >> 0) & 0xf0 | (hexInt >> 4) & 0x0f)
            b = ((hexInt << 4) & 0xf0 | hexInt & 0x0f)
            break;
        case 6: // #RRGGBB
            r = (hexInt >> 16) & 0xff
            g = (hexInt >> 8) & 0xff
            b = hexInt & 0xff
            break;
        default:
            // TODO:ERROR
            break;
        }
        
        self.init(
            red: (CGFloat(r)/255),
            green: (CGFloat(g)/255),
            blue: (CGFloat(b)/255),
            alpha:alpha)
    }
}
