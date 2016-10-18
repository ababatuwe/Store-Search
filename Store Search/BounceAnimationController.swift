//
//  BounceAnimationController.swift
//  Store Search
//
//  Created by N on 2016-10-18.
//  Copyright © 2016 Agaba Nkuuhe. All rights reserved.
//
//  To animate the transition between two screens, use an animation controller object. The purpose of this object is to animate a screen while it's being presented or dismissed, nothing more
//
//  To become an animation controller, the object needs to extend NSObject and also implement the UIViewControllerAnimatedTransitioning protocol. The important methods are:
//  
//  1. transitionDuration() -> determines how long the animation is. Ours only lasts for 0.4 seconds.
//
//  2. animateTransition() -> Performs the animation.
//



import UIKit

class BounceAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    
    /*
     transitionContext -> Contains a reference to new view controller and lets you know how big it should be.
     
     The actual animation starts at the line UIView.animateKeyFrames(). This sets the initial state before the animation block, and UIKit will automatically animate any properties that get changed inside the closure. The difference with before is that a keyframe animation lets you animate the view in several distinct statges
     
     transform -> Property that we're animated. This is an affine transform matrix. It allows you to do all sorts of funky stuff with the view, such as rotating or 
     shearing it, but the most common use of the transform is for scaling.
     
     The animation consists of several keyframes. It will smoothly proceed from one keyframe wot the next over a certain amount of time. Because you're animating the view's scale, the dfiferent toView.transform values represent how much bigger or smaller the view will be over time.
     
     The animation starts with the view sclaed down to 70%(0,7). The next keyframe inflates it to 120% its normal size aftwerwhich it will scale the view down a bit again but not as much as before(only 90% of its original size). The final keyframe ends up with a scale of 1.0, which restores the view to an undistorted shape. 
     */
    
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        if let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
            
            let containerView = transitionContext.containerView
            toView.frame = transitionContext.finalFrame(for: toViewController)
            containerView.addSubview(toView)
            toView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            
            UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .calculationModeCubic, animations: { 
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.334, animations: { 
                    toView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.334, relativeDuration: 0.333, animations: { 
                    toView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.666, relativeDuration: 0.333, animations: {
                    toView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                })
                }, completion: { finished in
                    transitionContext.completeTransition(finished)
            })
            
        }
    }
}
