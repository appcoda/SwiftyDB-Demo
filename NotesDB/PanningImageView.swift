//
//  PanningImageView.swift
//  NotesDB
//
//  Created by Gabriel Theodoropoulos on 2/20/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit


protocol PanningImageViewDelegate {
    func didMoveImageView(sender: PanningImageView)
}


class PanningImageView: UIImageView {

    var delegate: PanningImageViewDelegate!
    
    var lastCenter: CGPoint!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lastCenter = center
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "moveImageView:")
        addGestureRecognizer(panGestureRecognizer)
        
        userInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func moveImageView(gestureRecognizer: UIPanGestureRecognizer) {
        let translatedPoint  = gestureRecognizer.translationInView(superview!)
        center = CGPointMake(lastCenter.x + translatedPoint.x, lastCenter.y + translatedPoint.y)
        
        if delegate != nil {
            delegate.didMoveImageView(self)
        }
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        lastCenter = center
    }

}
