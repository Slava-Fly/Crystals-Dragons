//
//  UITextField+Padding.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 27.01.2026.
//


import UIKit

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        leftView = paddingView
        leftViewMode = .always
    }
}
