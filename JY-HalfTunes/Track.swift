//
//  Track.swift
//  JY-HalfTunes
//
//  Created by atom on 2017/4/20.
//  Copyright © 2017年 atom. All rights reserved.
//

import Foundation

class Track {
    var name: String?
    var artist: String?
    var previewUrl: String?
    
    init(name: String?, artist: String?, previewUrl: String?) {
        self.name = name
        self.artist = artist
        self.previewUrl = previewUrl
    }
}
