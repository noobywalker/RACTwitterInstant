//
//  Tweet.swift
//  TwitterInstant
//
//  Created by Waratnan Suriyasorn on 6/16/2559 BE.
//
//

import Foundation

struct Tweet {
    
    var status:String
    var profileImageUrl:String
    var username:String
    
    init(statusObj:[String:AnyObject])
    {
        status = statusObj["text"] as! String
        let user = statusObj["user"] as! [String:AnyObject]
        profileImageUrl = user["profile_image_url"] as! String
        username = user["screen_name"] as! String
    }
    
}