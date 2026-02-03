//
//  UIColor+Hex.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import UIKit

extension UIColor {

    convenience init(rgb: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}
