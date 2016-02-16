//
//  MainCollectionViewCell.swift
//  豆瓣美女
//
//  Created by lu on 15/11/12.
//  Copyright © 2015年 lu. All rights reserved.
//

import UIKit

class MainCollectionViewCell: UICollectionViewCell {
    var imageView  = UIImageView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.frame = bounds
        imageView.contentMode = .ScaleAspectFill
    }
}