//
//  OverlayTestViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/19/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit

enum ViewState {
    case stretched
    case compact
}

class OverlayTestViewController: UIViewController {

    @IBOutlet var overlayView:UIView!
    @IBOutlet var overlayViewHeightConstraint:NSLayoutConstraint!
    
    var propertyAnimator:UIViewPropertyAnimator?
    var viewState:ViewState = .compact
    var originalHeight:CGFloat = 44
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        self.overlayView.addGestureRecognizer(panGestureRecognizer)
    }

    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: self.view)
        
        if gestureRecognizer.state == .began {
            self.panBegan()
        }
        else if gestureRecognizer.state == .ended {
            self.panningEnded(withTranslation: translation, velocity: gestureRecognizer.velocity(in: self.view))
        }
        else {
            self.panningChanged(with: translation)
        }
    }
    
    func panBegan() {
        
        if self.propertyAnimator?.isRunning ?? false {
            return
        }
        
        //figure out target frame
        var targetHeight:CGFloat
        
        switch self.viewState {
        case .compact:
            targetHeight = 544
        case .stretched:
            targetHeight = self.originalHeight
        }
        
        self.overlayViewHeightConstraint.constant = targetHeight
        
        self.propertyAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.8, animations: { 
            self.view.layoutIfNeeded()
        })
    }
    
    func panningChanged(with translation:CGPoint) {
        
        if self.propertyAnimator?.isRunning ?? true {
            return
        }
        
        var progress = abs(translation.y) / 500
        progress = max(0.001, min(0.999, progress))
        print(progress)
        self.propertyAnimator?.fractionComplete = progress
    }
    
    func panningEnded(withTranslation translation: CGPoint, velocity: CGPoint) {
        
        //TODO: disable panning
        
        switch self.viewState {
        case .compact:
            if translation.y > 250 || velocity.y > 200 {
                self.propertyAnimator?.isReversed = false
                self.propertyAnimator?.addCompletion({ [weak self] (finalPosition) in
                    self?.viewState = .stretched
                    //TODO: enable panning
                })
            }
            else {
                self.propertyAnimator?.isReversed = true
                self.propertyAnimator?.addCompletion({ [weak self] (finalPosition) in
                    self?.viewState = .compact
                    //TODO: enable panning
                })
            }
        case .stretched:
            if translation.y < -250 || velocity.y < -200 {
                self.propertyAnimator?.isReversed = false
                self.propertyAnimator?.addCompletion({ [weak self] (finalPosition) in
                    self?.viewState = .compact
                    //TODO: enable panning
                })
            }
            else {
                self.propertyAnimator?.isReversed = true
                self.propertyAnimator?.addCompletion({ [weak self] (finalPosition) in
                    self?.viewState = .stretched
                    //TODO: enable panning
                })
            }
        }
        
        let velocityVector = CGVector(dx: velocity.x/100, dy: velocity.y/100)
        let springParameters = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: velocityVector)
        
        self.propertyAnimator?.continueAnimation(withTimingParameters: springParameters, durationFactor: 1.0)
    }
}
