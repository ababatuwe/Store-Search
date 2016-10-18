//
//  DimingPresentationController.swift
//  Store Search
//
//  Created by N on 2016-10-17.
//  Copyright © 2016 Agaba Nkuuhe. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    
    lazy var dimmingView = GradientView(frame: CGRect.zero)
    
    override var shouldRemovePresentersView: Bool {
        return false
    }
    
    /*
     presentationTransitionWillBegin() is invoked when the new view controller is about to be shown on the screen. Here we create the GradientView object , make it as big as the containerView, and insert it behind everything else in this "container view". 
     
     The containerView is a new view that is placed on top of the SearchViewController, and it contains the views from the DetailViewController. So this piece of logic places the  GradientView in between those two screens.
     
     Set the alpha value of the gradient view to 0 to make it completely transparent and then animate it back to 1 (or 100%) and fully visible resulting in a simple fade-in. That's a bit more subtle than making the gradient appear so abruptly.
     
     The special thing here is the transitionCoordinator stuff. This is the UIKit traffic cop in charge of coordinating the presentation controller and animation controllers and everything else that happens when a new view controller is presented.
     
     The important thing to know about the transitionCoordinator is that any of your animations should be done in a closure passed to the animateAlongsideTransition to keep the transition smooth. If your users want choppy animations, they would have bought Android phones :D
     */
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, at: 0)
        
        dimmingView.alpha = 0
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1
                }, completion: nil)
        }
    }
    
    //Animate the view out of sight
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0
                }, completion: nil)
        }
    }
}
