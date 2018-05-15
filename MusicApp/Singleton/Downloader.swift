//
//  Downloader.swift
//  MusicApp
//
//  Created by Patrick Hanna on 4/5/18.
//  Copyright © 2018 Patrick Hanna. All rights reserved.
//

import UIKit
import Foundation
import UserNotifications
import AVFoundation

fileprivate let sharedDownloaderInstance = Downloader()

class Downloader: NSObject, URLSessionDownloadDelegate{
    
    static var main: Downloader{
        return sharedDownloaderInstance
    }
    
    
    //MARK: - DOWNLOAD TASK DELEGATE METHODS
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        DispatchQueue.main.sync {
            let decimal = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * Double(100)
            self.downloadTaskDict[downloadTask]?.changeStatusTo(.loading(decimal))
            
        }
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        DispatchQueue.main.sync {
            let decimal = Double(fileOffset) / Double(expectedTotalBytes) * Double(100)
            self.downloadTaskDict[downloadTask]?.changeStatusTo(.loading(decimal))
            
        }
        
        
    }
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        dataTaskDidFinishWithError(error: error, task: task)
       
        
    }
    
    
    private func dataTaskDidFinishWithError(error: Error?, task: URLSessionTask){
        
        DispatchQueue.main.sync {
            if error == nil{return}
            
            if let downloadItem = self.downloadTaskDict[task as! URLSessionDownloadTask]{
                downloadItem.changeStatusTo(.failed(Date()))
                self.downloadTaskDict[task as! URLSessionDownloadTask] = nil
            }
            
        }
        
    }
    

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        
        var data: Data
        do {
            data = try Data(contentsOf: location)
            let downloadItem = self.downloadTaskDict[downloadTask]!

            do{
                let _ = try AVAudioPlayer(data: data)
            } catch {
                
                dataTaskDidFinishWithError(error: error, task: downloadTask)
                AppManager.displayErrorMessage(target: AppManager.shared.screen, message: "The video you attempted to download, titled \n\n'\(downloadItem.name)'\n\ncannot be played, possibly due to the data being corrupted. Please try again or delete.", completion: nil)
                return
            }
            
            DispatchQueue.main.sync {
                let newSong = Song.createNew(from: downloadItem, songData: data)
                self.displayDownloadFinishedNotification()
                
                downloadItem.changeStatusTo(.finished(newSong, Date()))
                self.downloadTaskDict[downloadTask] = nil
            }
            
            
        } catch {
        
            print("An error occured in the 'didFinishDownloadingTo' delegate function in Downloader.swift: \(error)")
            DispatchQueue.main.sync {
                self.downloadTaskDict[downloadTask]?.changeStatusTo(.failed(Date()))
                self.downloadTaskDict[downloadTask] = nil
                AppManager.displayErrorMessage(target: AppManager.shared.screen, message: "Sorry, an error occured when trying to download a video", completion: nil)
                return
            }
        }
    }
    
    
    
    
    
    
    
    
    var downloadTaskDict = [URLSessionDownloadTask : DownloadItem](){
        didSet{
            DispatchQueue.main.async {
                AppManager.shared.setDownloadCountTo(self.downloadTaskDict.count)

            }
        }
    }
    
    
    private func displayDownloadFinishedNotification(){
        
        //
        //        let content = UNMutableNotificationContent()
        //        content.title = "Download Complete"
        //        content.body = "Tap to start listening mother fuckaaa!!"
        //        content.badge = 1
        //
        //        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        //
        //        let request = UNNotificationRequest(identifier: "downloadCompleteRequest", content: content, trigger: trigger)
        //
        //        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        //
        //
        
    }
    
    
    
    func continueDownloadOf(item: DownloadItem){
        guard let resumeData = item.resumeData else {return}
        
        
        let task = session.downloadTask(withResumeData: resumeData)
        
        task.resume()
        
        downloadTaskDict[task] = item
        
        item.deleteResumeData()
        item.changeStatusTo(.buffering)
        
        
        
    }
    
    
    private func getTaskForItem(_ item: DownloadItem) -> URLSessionDownloadTask?{
        var downloadTask: URLSessionDownloadTask?
        for (task, downloadItem) in downloadTaskDict{
            
            if downloadItem != item {continue}
            
            downloadTask = task
            
        }
        
        return downloadTask
    }
    
    
    
    func pauseDownloadOf(item: DownloadItem){
      
        guard let task = getTaskForItem(item) else {return}
        
        task.cancel { (data) in
            
            DispatchQueue.main.sync {
                if data == nil{
                    item.changeStatusTo(.canceled(Date()))
                    return
                }

                item.changeStatusTo(.paused(data!, Date()))
            }
            
        }
        
        downloadTaskDict[task] = nil
        
        
        
    }
    
    
    func cancelDownloadOf(item: DownloadItem){
        
        guard let task = getTaskForItem(item) else {return}
        
        task.cancel()
        item.changeStatusTo(.canceled(Date()))
        downloadTaskDict[task] = nil
        
    }
    
    
    
    func appWillTerminate(){
        
        downloadTaskDict.forEach { (task, downloadItem) in
 
            downloadItem.changeStatusTo(.failed(Date()))
        }
    }
    
    
    func cancelAllActiveDownloads(){
        
        downloadTaskDict.forEach { (task, downloadItem) in
            task.cancel()
            downloadItem.changeStatusTo(.canceled(Date()))
            downloadTaskDict[task] = nil
        }
    }
    
    
    
    
    
    
    
    
    lazy var session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    
    
    
    
    
    
    //MARK: - GET MP3 FILE
    
    
    func retryDownloadOf(item: DownloadItem){
        
        
        let title = "Song_Downloaded_With_Patricks_App"
        
        let url = URL(string: "https://cdn.mixload.co/get.php?id=\(item.ytVideoID)&name=\(title)")!
        
        
        
        let task = session.downloadTask(with: url)
        
        self.downloadTaskDict[task] = item
        
        task.resume()
        item.changeStatusTo(.buffering)
        item.deleteResumeData()
    }
    
    
    
    
    func beginDownloadOf(_ video: YoutubeVideo){
        
        let title = "Song_Downloaded_With_Patricks_App"
        
        let url = URL(string: "https://cdn.mixload.co/get.php?id=\(video.videoID)&name=\(title)")!
        
        
        
        let task = session.downloadTask(with: url)
        
        URLSession.shared.dataTask(with: video.thumbnailLink) { (data, response, error) in
            if error != nil{
                print("There was an error in the 'beginDownloadOf' function in Downloader.swift: \(error!)")
                return
            }
            DispatchQueue.main.sync {
                
                let newDownloadItem = DownloadItem.createNew(from: video, imageData: data!)
                
                
                self.downloadTaskDict[task] = newDownloadItem
                
                task.resume()
                
                newDownloadItem.changeStatusTo(DownloadStatus.buffering)
                
            }
            
            
            }.resume()
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
