//
//  Util.swift
//  豆瓣美女
//
//  Created by lu on 16/2/16.
//  Copyright © 2016年 lu. All rights reserved.
//

import Foundation
//工具函数
class PhotoUtil {
    //通过id获取类型
    static func selectTypeByNumber(number: Int)->PageType{
        switch number{
        case 0:
            return .daxiong
        case 1:
            return .qiaotun
        case 2:
            return .heisi
        case 3:
            return .meitui
        case 4:
            return .yanzhi
        case 5:
            return .dazahui
        default:
            return .daxiong
        }
    }
    class func MIN(one: CGFloat, two: CGFloat)-> CGFloat{
        return one < two ? one : two
    }
}
