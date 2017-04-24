//
//  Download.swift
//  JY-HalfTunes
//
//  Created by atom on 2017/4/22.
//  Copyright © 2017年 atom. All rights reserved.
//

import UIKit

class Download: NSObject {
    
    var url: String
    var isDownloading = false
    var progress: Float = 0.0
    
    var downloadTask: URLSessionDownloadTask?
    var resumeData: Data?
    
    init(url: String) {
        self.url = url
    }
}
