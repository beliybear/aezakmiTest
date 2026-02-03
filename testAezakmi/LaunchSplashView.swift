//
//  LaunchSplashView.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import UIKit
import SnapKit

final class LaunchSplashView: UIView {
    
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(rgb: 0x101012)
        iv.image = UIImage(resource: .appLogo)
        return iv
    }()
    
    var onDismiss: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor(rgb: 0x101012)
        
        addSubview(logoImageView)
        
        logoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.edges.equalToSuperview()
        }
        
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
    }
    
    func playAnimation() {
        UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut) {
            self.logoImageView.alpha = 1
            self.logoImageView.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut) {
                UIView.animate(withDuration: 0.35, delay: 1.2, options: .curveEaseIn) {
                    self.logoImageView.alpha = 0
                    self.logoImageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                } completion: { _ in
                    self.removeFromSuperview()
                    self.onDismiss?()
                }
            }
        }
    }
}
