//
//  mailBoxCell.swift
//  Trouve moi une boite !
//
//  Created by Thomas Fauquemberg on 11/05/2018.
//  Copyright © 2018 Thomas Fauquemberg. All rights reserved.
//

import UIKit
import ScalingCarousel


class MailBoxCell: ScalingCarouselCell {
    
    var mailBox: MailBox? {
        didSet {
            if let dist = mailBox?.distanceFromUser {
                distanceLabel.text = "Distance: \(String(describing: Double(dist)/1000)) km"
            }
            
            if let city = mailBox?.city, let streetName = mailBox?.streetName?.lowercased(), var streetNumber = mailBox?.streetNumber, let zipCode = mailBox?.zipCode {
                
                if Int(streetNumber) == 0 {
                    streetNumber = ""
                }
                
                let attributedString = NSMutableAttributedString(string: "\(streetNumber) \(streetName)\n", attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 24)])
                attributedString.append(NSMutableAttributedString(string: "\(zipCode) \(city)\n", attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 18)]))
                self.adressLabel.attributedText = attributedString
            }
            
        }
    }
    
    
    let bottomContainer: UIView = {
       let v = UIView()
        v.backgroundColor = UIColor.rgb(red: 254, green: 203, blue: 61)
        return v
    }()
    
    let distanceLabel: UILabel = {
       let lbl = UILabel()
        lbl.text = "DISTANCE: 1.35 km"
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.textColor = UIColor.rgb(red: 61, green: 61, blue: 61)
        lbl.backgroundColor = .clear
        return lbl
    }()
    
    let adressLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor.rgb(red: 61, green: 61, blue: 61)
        lbl.backgroundColor = .clear
        lbl.numberOfLines = 0
        return lbl
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        mainView = UIView(frame: contentView.bounds)
        mainView.backgroundColor = UIColor.rgb(red: 235, green: 235, blue: 235)
        mainView.clipsToBounds = true
        
        setupViews()
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    fileprivate func setupViews() {
        contentView.addSubview(mainView)
        mainView.addSubview(bottomContainer)
        
        bottomContainer.anchor(top: nil, left: mainView.leftAnchor, bottom: mainView.bottomAnchor, right: mainView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        
        bottomContainer.addSubview(distanceLabel)
        distanceLabel.anchor(top: bottomContainer.topAnchor, left: bottomContainer.leftAnchor, bottom: bottomContainer.bottomAnchor, right: bottomContainer.rightAnchor, paddingTop: 5, paddingLeft: 14, paddingBottom: 5, paddingRight: 14, width: 0, height: 0)
        
        mainView.addSubview(adressLabel)
        adressLabel.anchor(top: mainView.topAnchor, left: mainView.leftAnchor, bottom: bottomContainer.topAnchor, right: mainView.rightAnchor, paddingTop: 14, paddingLeft: 14, paddingBottom: 14, paddingRight: 14, width: 0, height: 0)
    }
    
    
}





