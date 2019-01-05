//
//  NoResultCell.swift
//  Trouve moi une boite !
//
//  Created by Thomas Fauquemberg on 12/05/2018.
//  Copyright © 2018 Thomas Fauquemberg. All rights reserved.
//

import UIKit
import ScalingCarousel


class NoResultCell: ScalingCarouselCell {
    
    let textLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor.rgb(red: 61, green: 61, blue: 61)
        lbl.backgroundColor = .clear
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        
        return lbl
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        mainView = UIView(frame: contentView.bounds)
        mainView.backgroundColor = UIColor.rgb(red: 235, green: 235, blue: 235)
        mainView.clipsToBounds = true
        
        setupViews()
    }
    
    
    fileprivate func setupViews() {
        contentView.addSubview(mainView)
        
        mainView.addSubview(textLabel)
        textLabel.anchor(top: mainView.topAnchor, left: mainView.leftAnchor, bottom: mainView.bottomAnchor, right: mainView.rightAnchor, paddingTop: 18, paddingLeft: 18, paddingBottom: 18, paddingRight: 18, width: 0, height: 0)
        

    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
}
