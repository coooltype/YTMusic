//
//  Templates.swift
//  MusicApp
//
//  Created by Patrick Hanna on 2/18/18.
//  Copyright © 2018 Patrick Hanna. All rights reserved.
//

import UIKit
import MediaPlayer
import UserNotifications
import AudioToolbox
import SafariServices


class AppManager: NSObject{
    
    static let shared = AppManager()
    
    
    //MARK: - APP CONSTANTS
    static var screenWidth: CGFloat!
    static var tabBarHeight: CGFloat = 49
    static var minimizedMusicViewHeight: CGFloat = 60
    
    static var currentAppBottomInset: CGFloat = 49
    
   
    
    private let APP_HAS_LAUNCHED_ALREADY_KEY = "APP HAS LAUNCHED ALREADY."
    
    
    
    //MARK: - APP ENTRY POINT
    
    func generateInterface() -> UIViewController{
        
        

        if UserDefaults.standard.bool(forKey: self.APP_HAS_LAUNCHED_ALREADY_KEY) == false{

            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {[weak self] (timer) in
                guard let self = self else {return}
                let alert = UIAlertController(title: "Hey There!", message: "Wecome To YTMusic! Unfortunately, the backend used for this app has been malfunctioning lately. As a result,  Youtube videos cannot be downloaded. Regardless, feel free to enjoy the fantastic UI and preinstalled music.", preferredStyle: .alert)

                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(action)
                self.screen.present(alert, animated: true, completion: nil)

            }
            UserDefaults.standard.set(true, forKey: self.APP_HAS_LAUNCHED_ALREADY_KEY)
        }
    
        return screen
    }
    
    
    
    //MARK: - APP VIEW CONTROLLERS
    
    var screen = Screen()
    
    
    private var musicView: NowPlayingViewController{
        return screen.nowPlayingVC
    }
    
    
    
    //MARK: - ERROR MESSAGE
    
    
    static func displayErrorMessage(target: UIViewController = AppManager.shared.screen, title: String = "Oops",message: String, completion: (() -> Void)?){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel){ (action) in
            if let completion = completion{
                completion()
            }
        }
        alert.addAction(action)
        vibrate(type: .warning)
        target.present(alert, animated: true, completion: nil)
    }
    
    
    static func vibrate(type: UINotificationFeedbackType){
        let hapticFeedback = UINotificationFeedbackGenerator()
        hapticFeedback.notificationOccurred(.error)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - HANDLE USER SELECTED SONG
    
    private var musicViewIsVisible = false
    
    func setAndPlaySong(_ song: Song){
        
        
        musicView.setUpMusicPlayer(withSong: song, userHandPicked: true, playWhenSetted: true, animated: true)
        
        if !musicViewIsVisible{
            musicViewWasShown()
        }
        
    }
    
    
    
    func musicViewWasShown(){
        
        AppManager.currentAppBottomInset = AppManager.minimizedMusicViewHeight + AppManager.tabBarHeight
        self.musicViewIsVisible = true
        MNotifications.sendAppBottomSafeAreaInsetsDidChangeNotification(for: AppManager.currentAppBottomInset)
    }
    
    
    
    
    func musicViewWasHidden(){
        AppManager.currentAppBottomInset = AppManager.tabBarHeight
        musicViewIsVisible = false
        MNotifications.sendAppBottomSafeAreaInsetsDidChangeNotification(for: AppManager.currentAppBottomInset)
        
    }
    
    
    
    
    
    
    func setDownloadCountTo(_ int: Int){
        if int <= 0{screen.downloadsItem.badgeValue = nil; return}
        screen.downloadsItem.badgeValue = String(int)
    }
    
    
    
    
    
    // MARK: - HANDLE SONG DELETION
    
    private func handleDeletionOf(song: Song){
        
        let alert = UIAlertController(title: "Are you sure you want to delete this item permanently?", message: "You cannot undo this action.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
            song.delete()
        })
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        alert.addAction(action)
        AppManager.vibrate(type: .warning)
        self.screen.present(alert, animated: true, completion: nil)
        
    }
    
    
    
    //MARK: -
    
    
    
    func userPressedAppSearchShortcut(){
        screen.showtabBarItem(tag: 2)
    }
    
    
    
    
    
    func userSelectedDownloadItem(_ item: DownloadItem){
        guard let song = item.song else {return}
        
        AppManager.shared.screen.showtabBarItem(tag: 1)
        AppManager.shared.screen.libraryVC.scrollToCellOf(song: song)
        
    }
    
    
    private static var testedtimer = Timer()
    
    private static var urlHasBeenTested = false
    
    static func openVideoInYoutubeApp(videoID: String){
        let appURL = URL(string:"youtube://")!
        
        if UIApplication.shared.canOpenURL(appURL){
            
            let videoURL = URL(string: "youtube://www.youtube.com/watch?v=\(videoID)")!
            if UIApplication.shared.canOpenURL(videoURL){
                UIApplication.shared.open(videoURL)
                
            } else {
                AppManager.displayErrorMessage(target: AppManager.shared.screen, message: "Something went wrong when trying to redirect you to the Youtube App", completion: nil)
            }
            
            
            
        } else {
            displayYoutubeNotAvailableAlert()
        }
        
    }
    
    static func displayYoutubeNotAvailableAlert(){
        let alert = UIAlertController(title: "You don't have the YouTube app installed.", message: "Would you like to install it?", preferredStyle: .alert)
        
        let downloadYoutubeAction = UIAlertAction(title: "Install", style: .default) { (action) in
            let youtubeAppURL  = URL(string:"itms://itunes.apple.com/us/app/apple-store/id544007664?mt=8")!
            
            if UIApplication.shared.canOpenURL(youtubeAppURL){
                
                UIApplication.shared.open(youtubeAppURL, options: [:], completionHandler: nil)
                
            } else {
                displayErrorMessage(target: AppManager.shared.screen, message: "Something went wrong when trying to redirect you to the iTunes Store.", completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        
        
        alert.addAction(cancelAction)
        alert.addAction(downloadYoutubeAction)
        
        AppManager.shared.screen.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    
    
    //MARK: - ACTION MENU FUCTIONS
    
    func displayActionMenuFor(song: Song){
        let optionMenu = UIAlertController(title: "Song Options", message: song.name, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.handleDeletionOf(song: song)
        }
        
        let watchAction = UIAlertAction(title: "Watch", style: .default) { (action) in
            
            if let ytid = song.youtubeID,
                let controller = AppManager.prepareYoutubeVideo(videoID: ytid){
                
                self.screen.present(controller, animated: true, completion: nil)
                
            } else {
                AppManager.displayErrorMessage(target: self.screen, message: "The video for this song could not be loaded. You're out of luck 😴.", completion: nil)
            }
        }
        
        let openInYoutube = UIAlertAction(title: "Open in the YouTube App", style: .default) { (action) in
            
            
            if let id = song.youtubeID{
                
                AppManager.openVideoInYoutubeApp(videoID: id)
                
            } else {
                AppManager.displayErrorMessage(target: AppManager.shared.screen, message: "Something went wrong when trying to redirect you. You're out of luck 😴.", completion: nil)
            }
        }
        
        //
        //        let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
        //            optionMenu.dismiss(animated: true, completion: nil)
        //            self.screen.present(SongEditorView(song: song), animated: true, completion: nil)
        //        }
        
        let playNextAction = UIAlertAction(title: "Play Next", style: .default) { (action) in
            
            song.playNext()
        }
        
        let shareAction = UIAlertAction(title: "Share", style: .default) { (action) in
            if let id = song.youtubeID, let url = youtubeURL(from: id){
                let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                
                AppManager.shared.screen.present(controller, animated: true, completion: nil)
            } else {
                AppManager.displayErrorMessage(target: AppManager.shared.screen, message: "Something went wrong when trying to prepare the link for sharing.", completion: nil)
            }
        }
        
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        //        optionMenu.addAction(editAction)
        
        
        if let currentSong = musicView.currentlyPlayingSong{
            if song != currentSong{
                optionMenu.addAction(playNextAction)
            }
        }
        
        optionMenu.addAction(watchAction)
        optionMenu.addAction(shareAction)
        optionMenu.addAction(openInYoutube)
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        screen.present(optionMenu, animated: true, completion: nil)
        
    }
    
    
    
    func appWillTerminate(){
        
        Downloader.main.appWillTerminate()
        
    }
    
    func displayActionMenuFor(downloadItem: DownloadItem){
        
        
        let downloader = Downloader.main
        
        let optionMenu = UIAlertController(title: "Download Options", message: downloadItem.name, preferredStyle: .actionSheet)
        
        let stopAction = UIAlertAction(title: "Stop", style: .destructive) { (action) in
            downloader.cancelDownloadOf(item: downloadItem)
        }
        
        let pauseAction = UIAlertAction(title: "Pause", style: .default) { (action) in
            downloader.pauseDownloadOf(item: downloadItem)
        }
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { (action) in
            downloadItem.delete()
        }
        
        let retryAction = UIAlertAction(title: "Retry", style: .default) { (action) in
            downloadItem.deleteResumeData()
            downloader.cancelDownloadOf(item: downloadItem)
            downloader.retryDownloadOf(item: downloadItem)
        }
        
        let continueAction = UIAlertAction(title: "Continue", style: .default) { (action) in
            downloader.continueDownloadOf(item: downloadItem)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        switch downloadItem.runTimeStatus {
        case .buffering, .loading:
            optionMenu.addAction(pauseAction)
            optionMenu.addAction(retryAction)
            optionMenu.addAction(stopAction)
            
        case .paused:
            optionMenu.addAction(continueAction)
            optionMenu.addAction(retryAction)
            
        case .failed, .canceled:
            
            optionMenu.addAction(retryAction)
            
        default: break
            
        }
        optionMenu.addAction(removeAction)
        optionMenu.addAction(cancel)
        screen.present(optionMenu, animated: true, completion: nil)
        
        
    }
    
    
    
    
    
    
    
    
    static func prepareYoutubeVideo(videoID: String) -> UIViewController? {
        guard let url = youtubeURL(from: videoID) else {
            
            AppManager.displayErrorMessage(target: self.shared.screen, message: "This video could not be loaded.", completion: nil)
            return nil
            
        }
        
        
        
        
        let webView = SFSafariViewController(url: url)
        webView.preferredControlTintColor = CURRENT_THEME_COLOR
        
        return webView
    }
    
    
    
    
    @objc private static func respondToSearchButtonTapped(){
        
        AppManager.shared.screen.showtabBarItem(tag: 2)
        AppManager.shared.screen.searchVC.popToRootViewController(animated: true)
        
        
    }
    
    
}

