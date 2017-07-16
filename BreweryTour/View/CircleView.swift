//
//  CircleView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 11/30/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

/*
 This class creates a circular UIView with a white center.
 */


import UIKit


@IBDesignable

class CircleView: UIView {

    let lineWidth: CGFloat = 1.5

    let multiplier : CGFloat = 1

    var centerOfCirclesView : CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    var halfOfViewSize : CGFloat {
        return min(bounds.size.height, bounds.size.width) * multiplier / 2
    }

    let fullCircleInRadians = CGFloat(Double.pi*2)


    // MARK: - Functions

    func drawCirleCenteredAt(center: CGPoint, withRadius radius: CGFloat) -> UIBezierPath {
        let circlePath = UIBezierPath(arcCenter: centerOfCirclesView,
                                      radius: halfOfViewSize-(lineWidth),
                                      startAngle: 0,
                                      endAngle: fullCircleInRadians, clockwise: true)
        circlePath.lineWidth = lineWidth
        return circlePath
    }


    override func draw(_ rect: CGRect) {
        // Drawing code
        let path = drawCirleCenteredAt(center: centerOfCirclesView, withRadius: halfOfViewSize)
        path.close()

        // Stroke and fill circle
        UIColor.white.setStroke()
        //UIColor.white.setFill()
        path.stroke()
        //path.fill()
    }

}
