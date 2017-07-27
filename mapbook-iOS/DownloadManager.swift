//
//  DownloadManager.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/24/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit

class DownloadManager:NSObject {

//    lazy private var urlSession:URLSession = { return URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main) }()
    
    lazy private var urlSession:URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    
    static var shared:DownloadManager {
        return DownloadManager()
    }
    
    private override init() {
        
        super.init()
        //self.urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        
        
    }
    
    func downloadMMPK(url: URL) {
        
        self.urlSession.downloadTask(with: url).resume()
        
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    
    internal func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        print(totalBytesWritten)
    }
    
    internal func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finished")
    }
    
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Error")
        print(error)
    }
}
