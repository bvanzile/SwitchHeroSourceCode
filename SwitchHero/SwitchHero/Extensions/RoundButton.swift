//
//  RoundButton.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 5/6/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit

// round button extension taken from article

@IBDesignable
class RoundButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 0{
        didSet{
        self.layer.cornerRadius = cornerRadius
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0{
        didSet{
            self.layer.borderWidth = borderWidth
        }
    }

    @IBInspectable var borderColor: UIColor = UIColor.clear{
        didSet{
            self.layer.borderColor = borderColor.cgColor
        }
    }
}
