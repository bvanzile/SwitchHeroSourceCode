//
//  UIAlert.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 6/1/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import Foundation
import UIKit

// workaround for Apple/xcode unresolved issue
extension UIAlertController {
    func pruneNegativeWidthConstraints() {
        for subView in self.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}

extension UIAlertAction {
    convenience init(title: String?, style: UIAlertAction.Style, image: UIImage, handler: ((UIAlertAction) -> Void)? = nil) {
        self.init(title: title, style: style, handler: handler)
        self.actionImage = image
    }
    
    convenience init?(title: String?, style: UIAlertAction.Style, imageNamed imageName: String, handler: ((UIAlertAction) -> Void)? = nil) {
        if let image = UIImage(named: imageName) {
            self.init(title: title, style: style, image: image, handler: handler)
        } else {
            return nil
        }
    }
    
    var actionImage: UIImage {
        get {
            return self.value(forKey: "image") as? UIImage ?? UIImage()
        }
        set(image) {
            self.setValue(image, forKey: "image")
        }
    }
}
