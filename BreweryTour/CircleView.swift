//
//  CircleView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 11/30/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit


@IBDesignable
// This class creates a circular UIView with a white center.
class CircleView: UIView {
    
        var multiplier : CGFloat = 1
    
        var centerOfCirclesView : CGPoint {
            return CGPoint(x: bounds.midX, y: bounds.midY)
        }
        var halfOfViewSize : CGFloat {
            return min(bounds.size.height, bounds.size.width) * multiplier / 2
        }

        var lineWidth : CGFloat = 0.5
        
        var full = CGFloat(M_PI*2)
    
        func drawCirleCenteredAt(center: CGPoint, withRadius radius: CGFloat) -> UIBezierPath {
            let circlePath = UIBezierPath(arcCenter: centerOfCirclesView,
                                          radius: halfOfViewSize,
                                          startAngle: 0,
                                          endAngle: full, clockwise: true)
            circlePath.lineWidth = lineWidth
            return circlePath
        }
    
    
        override func draw(_ rect: CGRect) {
            // Drawing code
            let path = drawCirleCenteredAt(center: centerOfCirclesView, withRadius: halfOfViewSize)
            path.close()
            UIColor.white.setFill()
            path.fill()
        }
        
}
