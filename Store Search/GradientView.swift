//
//  GradientView.swift
//  Store Search
//
//  Created by N on 2016-10-18.
//  Copyright © 2016 Agaba Nkuuhe. All rights reserved.
//

import UIKit

/*
 This is a very simple view. It simply draws a black circular gradient that goes from a mostly opaque in the corners to mostly transparent in the center.
 */

class GradientView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
    /*
     Draw uses the Core Graphics framework (a.k.a Quartz 2D) to:
     
     1. Create 2 arrays containing the "color stops" for the gradient. The first color (0,0,0,0.3) is a black color that is mostly transparent. It sits at location 0 in the gradient which represents the centre fot he screen because you'll be drawing a circular gradient. The second color (0,0,0,0.7) is also black but much less transparent and sits at location 1, which represents the circumference of the gradient's circle. Remember that in UIKit and also in Core Graphics, colors and opacity values don't go from 0 to 255 but are fractional values from 0.0 to 1.0. [0,1] in the locations array represents percentages: 0% and 100% respectively. If you have more than 2 colors, you can specify the percentages of where in the gradient you want to place these colors.
     
     2. With those color stops, you can create the gradient. This gives you a new CGGradient object
     
     3. Now that oyou have the gradient object, you have to figure out how big you need to draw it. The midX and midY properties return the center point of a rectangle. That rectangle is given by bounds, a CGRect object that describes the dimensions of the view. By asking bounds, you can use this view anywhere you want to, no matter how big a space if should fill. The centerPoint constant contains the coordinates for the center point of the view and radius contains the larger of the x and y values; max() is a handy function that you can use to determine which of two values is the biggest.
     
     4. With all those preliminaries done, you can finally draw the thing. Core Graphics drawing always takes place in a so-called graphics context. We need to obtain a reference to the current context and then do the drawing. And finally, drawRadialGradient() draws the gradient according to your specifications
     */
    
    override func draw(_ rect: CGRect) {
        //1
        let components: [CGFloat] = [0, 0, 0, 0.3, 0, 0, 0, 0.7]
        let locations: [CGFloat] = [0,1]
        
        //2
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: 2)
        
        //3
        let x = bounds.midX
        let y = bounds.midY
        let centerPoint = CGPoint(x: x, y: y)
        let radius = max(x, y)
        
        //4
        let context = UIGraphicsGetCurrentContext()
        context?.drawRadialGradient(gradient!, startCenter: centerPoint, startRadius: 0, endCenter: centerPoint, endRadius: radius, options: .drawsAfterEndLocation)
        
    }
}
