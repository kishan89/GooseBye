//
//  SegueFromLeft.swift
//  GooseBye
//
//  Created by Kishan Patel on 10/23/16.
//  Copyright © 2016 Kishan Patel. All rights reserved.
//

import UIKit
import QuartzCore

class SegueNext: UIStoryboardSegue {
    
    override func perform()
    {
        let src = self.source
        let dst = self.destination
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations:
            {
                dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion:
            {
                finished in src.present(dst, animated: false, completion: nil)
            }
        )
    }
}
