//
//  MusicView_MAIN.swift
//  MusicApp
//
//  Created by Patrick Hanna on 2/19/18.
//  Copyright © 2018 Patrick Hanna. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer



protocol NowPlayingViewControllerDelegate: class{
    func userDidMinimizeNowPlayingView()
    func userDidMaximizeNowPlayingView()
}

class NowPlayingViewController: UIViewController, CustomSliderDelegate, AVAudioPlayerDelegate{
    
    
    
    var songQueue: SongQueue!
    
    var songPlayer: AVAudioPlayer!
    
    var songIsPlaying: Bool{
        if let player = songPlayer{
            if player.isPlaying{
                return true
            }
        }
        return false
    }
    
    var parentView: UIView{
        return parent!.view
    }
    
    init() { super.init(nibName: nil, bundle: nil) }
    
    
    
    func setAllConstraintsToParent(){
        setInitialConstraints()
        setUpViews()
        minimizedNowPlayingPreview.addGestureRecognizer(goUpRecognizer)
        view.addGestureRecognizer(longPressGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder has not been implemented")
    }
    
    weak var delegate: NowPlayingViewControllerDelegate?
    
 

    

    
    

    
    

    
    
    
    
    
    
    
    
    
    //MARK: - CONSTANTS
    
   weak var currentlyPlayingSong: Song?
   

    var elasticDistance: CGFloat = 150
    var musicViewEndingFrameCornerRadius: CGFloat = 10
    var endingMusicViewFrameSpaceFromTop: CGFloat = 20
    var lengthOfPan: CGFloat = 0
    
    
    var timer = Timer()
    var musicViewIsMinimized = true
    var iAmVisible = false
    
    
    
    
    
    var topAnchorConstraint: NSLayoutConstraint!

    var albumCover_centerXConstraint: NSLayoutConstraint!
    var albumCover_topConstraint: NSLayoutConstraint!
    var albumCover_leftConstraint: NSLayoutConstraint!
    
    var albumCover_heightConstraint: NSLayoutConstraint!
    var albumCover_widthConstraints: NSLayoutConstraint!
    
    
    
    
    
    
    
    
    lazy var minimizedNowPlayingPreview: MinimizedNowPlayingPreview = {
        let x = MinimizedNowPlayingPreview.init(nameLabelLeftInset:  10 + minimizedAlbumCover_Size.width + 9)
        x.rewindButton.action = { self.performRewindButtonAction()}
        x.playPauseButton.action = {self.performPlayPauseButtonAction()}
        x.fastForwardButton.action = {self.performFastForwardButtonAction()}
        return x
    }()
    
    
    lazy var backGroundBluryView: UIVisualEffectView = {
        let x = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    

    lazy var topNub: UIView = {

        let holderView = UIView()
        holderView.translatesAutoresizingMaskIntoConstraints = false
        holderView.backgroundColor = .clear
        
        let image = UIView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        image.layer.cornerRadius = 2.5
        image.layer.masksToBounds = true
        image.isUserInteractionEnabled = false
        holderView.addSubview(image)
        
        image.widthAnchor.constraint(equalToConstant: 40).isActive = true
        image.heightAnchor.constraint(equalToConstant: 5).isActive = true
        image.centerXAnchor.constraint(equalTo: holderView.centerXAnchor).isActive = true
        image.centerYAnchor.constraint(equalTo: holderView.centerYAnchor).isActive = true
        
        holderView.alpha = 0
        return holderView
    }()
    
    
    
    lazy var albumImage: AlbumImageView = {
        let x = AlbumImageView()
        x.contentMode = .scaleAspectFill
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    
    lazy var scrubbingSlider: CustomSlider = {
        let x = CustomSlider(frame: CGRect(x: maximizedAlbumCoverInset,
                                           y: distanceFromTopOfMusicViewToBottomOfAlbumCover,
                                           width: maximizedAlbumCoverSize_Playing_NotSliding.width,
                                           height: 20))
        x.customDelegate = self
        return x
    }()
    
    
    
    
    
    
    
    override func interfaceColorDidChange(to color: UIColor) {
        artistAndAlbumLabel.textColor = color
        audioDevicesButton.tintColor = color
        audioDevicesButtonCover.tintColor = color
        threeDotImageView.tintColor = color
        playlistImageView.tintColor = color
    }
    
    
    
    
    
    lazy var songNameLabel: UILabel = {
        let x = UILabel()
        x.font = UIFont.boldSystemFont(ofSize: 25)
        x.textAlignment = .center
        x.textColor = .black
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    
    
    
    lazy var artistAndAlbumLabel: UILabel = {
        let x = UILabel()
        x.font = UIFont.systemFont(ofSize: 22)
        x.textColor = THEME_COLOR(asker: self)
        x.textAlignment = .center
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    
    
    
    
    lazy var rewindButton: MediaPlayingButton = {
        let x = MediaPlayingButton(buttonType: .rewind, imageSize: 40, circleSize: 70)
        x.translatesAutoresizingMaskIntoConstraints = false
        x.action = { self.performRewindButtonAction() }
        return x
    }()
    
   
    
    lazy var play_PauseButton: MediaPlayingButton = {
        let x = MediaPlayingButton(buttonType: .play_pause, imageSize: 50, circleSize: 70)
        x.translatesAutoresizingMaskIntoConstraints = false
        x.action = {
            self.performPlayPauseButtonAction()
        }
     
        
        x.automaticallyAnimatesImageWhenTapped = false

        return x
    }()
    
   
   
    
    lazy var fastForwardButton: MediaPlayingButton = {
        let x = MediaPlayingButton(buttonType: .fastForward, imageSize: 40, circleSize: 70)
        x.translatesAutoresizingMaskIntoConstraints = false
        x.action = { self.performFastForwardButtonAction() }
        return x
    }()
    

    
    lazy var volumeSlider: MPVolumeView = {

        let x = MPVolumeView()
        x.translatesAutoresizingMaskIntoConstraints = false
        
        x.tintColor = .lightGray
        
        x.showsRouteButton = false
        x.backgroundColor = .clear

        return x
    }()
    

    
    lazy var audioDevicesButton: MPVolumeView = {
        let x = MPVolumeView()
        x.showsVolumeSlider = false
        x.showsRouteButton = true
        x.tintColor = THEME_COLOR(asker: self)
        let image = UIImage(named: "icons8-earbud-headphones-filled-100")!.withRenderingMode(.alwaysTemplate)
        x.setRouteButtonImage( image ,for: .normal)
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    
    lazy var audioDevicesButtonCover: UIImageView = {
        let x = UIImageView(image: UIImage(named: "icons8-earbud-headphones-filled-100")!.withRenderingMode(.alwaysTemplate))
        x.tintColor = THEME_COLOR(asker: self)
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
        
    }()
    
    private let threeDotImageView = UIImageView(image: UIImage(named: "icons8-more-filled-100")!.withRenderingMode(.alwaysTemplate))

    
    lazy var threeDotButton: UIButton = {
       let x = UIButton(type: .system)
        x.translatesAutoresizingMaskIntoConstraints = false
        
        threeDotImageView.translatesAutoresizingMaskIntoConstraints = false
        threeDotImageView.contentMode = .scaleAspectFit
        threeDotImageView.tintColor = THEME_COLOR(asker: self)
        threeDotImageView.isUserInteractionEnabled = false
        
        x.addSubview(threeDotImageView)
        
        threeDotImageView.centerXAnchor.constraint(equalTo: x.centerXAnchor).isActive = true
        threeDotImageView.centerYAnchor.constraint(equalTo: x.centerYAnchor).isActive = true
        threeDotImageView.heightAnchor.constraint(equalTo: x.heightAnchor).isActive = true
        threeDotImageView.widthAnchor.constraint(equalTo: x.widthAnchor).isActive = true
        
        
        x.addTarget(self, action: #selector(respondToThreeDotButtonTapped), for: .touchUpInside)
        return x
    }()
    
    @objc func respondToThreeDotButtonTapped(){
        
        AppManager.shared.displayActionMenuFor(song: currentlyPlayingSong!)
        
    }

    private let playlistImageView = UIImageView(image: UIImage(named: "icons8-playlist-96")!.withRenderingMode(.alwaysTemplate))

    lazy var songQueueListButton: UIButton = {
        let x = UIButton(type: .system)
        x.translatesAutoresizingMaskIntoConstraints = false
        
        playlistImageView.translatesAutoresizingMaskIntoConstraints = false
        playlistImageView.contentMode = .scaleAspectFit
        playlistImageView.tintColor = THEME_COLOR(asker: self)
        playlistImageView.isUserInteractionEnabled = false
        
        x.addSubview(playlistImageView)
        
        playlistImageView.centerXAnchor.constraint(equalTo: x.centerXAnchor).isActive = true
        playlistImageView.centerYAnchor.constraint(equalTo: x.centerYAnchor).isActive = true
        playlistImageView.heightAnchor.constraint(equalTo: x.heightAnchor).isActive = true
        playlistImageView.widthAnchor.constraint(equalTo: x.widthAnchor).isActive = true
        
        
        x.addTarget(self, action: #selector(respondToSongQueueButtonTapped), for: .touchUpInside)
        return x
    }()
    
    
    @objc func respondToSongQueueButtonTapped(){
        
        let newController = songQueue.getVisualizer()
        
        AppManager.shared.screen.present(newController, animated: true, completion: nil)
        
        
        
    }
    
    
    
    
    
    
    
    
    private lazy var textInfoStackView: UIStackView = {
        
        let x = UIStackView(arrangedSubviews: [songNameLabel, artistAndAlbumLabel])
        x.axis = .vertical
        x.distribution = .fillEqually
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    
    
    
    
    private lazy var mediaButtonHolderView: UIView = {
       let x = UIView()
        x.translatesAutoresizingMaskIntoConstraints = false
        x.backgroundColor = .clear
        
        x.addSubview(play_PauseButton)
        x.addSubview(rewindButton)
        x.addSubview(fastForwardButton)
        
        
        let SPACING: CGFloat = 30
        let BUTTON_SIZE: CGFloat = 70
        
        
        play_PauseButton.centerYAnchor.constraint(equalTo: x.centerYAnchor).isActive = true
        play_PauseButton.centerXAnchor.constraint(equalTo: x.centerXAnchor).isActive = true
        play_PauseButton.heightAnchor.constraint(equalToConstant: BUTTON_SIZE).isActive = true
        play_PauseButton.widthAnchor.constraint(equalTo: play_PauseButton.heightAnchor).isActive = true
        
        
        rewindButton.centerYAnchor.constraint(equalTo: play_PauseButton.centerYAnchor).isActive = true
        rewindButton.rightAnchor.constraint(equalTo: play_PauseButton.leftAnchor, constant: -SPACING).isActive = true
        rewindButton.widthAnchor.constraint(equalToConstant: BUTTON_SIZE).isActive = true
        rewindButton.heightAnchor.constraint(equalTo: rewindButton.widthAnchor).isActive = true
        
        
        fastForwardButton.centerYAnchor.constraint(equalTo: play_PauseButton.centerYAnchor).isActive = true
        fastForwardButton.leftAnchor.constraint(equalTo: play_PauseButton.rightAnchor, constant: SPACING).isActive = true
        fastForwardButton.widthAnchor.constraint(equalToConstant: BUTTON_SIZE).isActive = true
        fastForwardButton.heightAnchor.constraint(equalTo: fastForwardButton.widthAnchor).isActive = true
        
        
        return x
        
    }()
    
    private lazy var volumeSliderHolderView: UIView = {
        let x = UIView()
        x.translatesAutoresizingMaskIntoConstraints = false
        x.backgroundColor = .clear
        
        x.addSubview(volumeSlider)
        
        volumeSlider.leftAnchor.constraint(equalTo: x.leftAnchor).isActive = true
        volumeSlider.rightAnchor.constraint(equalTo: x.rightAnchor).isActive = true
        volumeSlider.heightAnchor.constraint(equalToConstant: 30).isActive = true
        volumeSlider.centerYAnchor.constraint(equalTo: x.centerYAnchor, constant: 5).isActive = true
        
        #if targetEnvironment(simulator)
    
        
        let showerSlider = UISlider()
        showerSlider.translatesAutoresizingMaskIntoConstraints = false
        x.addSubview(showerSlider)
        
        
        showerSlider.leftAnchor.constraint(equalTo: x.leftAnchor).isActive = true
        showerSlider.rightAnchor.constraint(equalTo: x.rightAnchor).isActive = true
        showerSlider.centerYAnchor.constraint(equalTo: x.centerYAnchor).isActive = true
        
        #endif
        
        return x
        
    }()
    
    
    
    private lazy var bottomBarHolderView: UIView = {
       let x = UIView()
        x.translatesAutoresizingMaskIntoConstraints = false
        x.backgroundColor = .clear
        
        
        x.addSubview(audioDevicesButton)
        x.addSubview(threeDotButton)
        x.addSubview(audioDevicesButtonCover)
        x.addSubview(songQueueListButton)
        
        let devicesButtonSize: CGFloat = 30
        
      
        
        audioDevicesButton.centerXAnchor.constraint(equalTo: x.centerXAnchor).isActive = true
        audioDevicesButton.topAnchor.constraint(equalTo: x.topAnchor).isActive = true
        audioDevicesButton.bottomAnchor.constraint(equalTo: x.bottomAnchor).isActive = true
        audioDevicesButton.widthAnchor.constraint(equalTo: audioDevicesButton.heightAnchor).isActive = true
        
        x.layoutIfNeeded()

        let bounds = audioDevicesButton.routeButtonRect(forBounds: audioDevicesButton.bounds)



        audioDevicesButtonCover.leftAnchor.constraint(equalTo: audioDevicesButton.leftAnchor, constant: 4).isActive = true
        audioDevicesButtonCover.topAnchor.constraint(equalTo: audioDevicesButton.topAnchor, constant: 4).isActive = true
        audioDevicesButtonCover.heightAnchor.constraint(equalToConstant: bounds.height).isActive = true
        audioDevicesButtonCover.widthAnchor.constraint(equalToConstant: bounds.width).isActive = true

        
        
        threeDotButton.rightAnchor.constraint(equalTo: x.rightAnchor).isActive = true
        threeDotButton.centerYAnchor.constraint(equalTo: x.centerYAnchor).isActive = true
        threeDotButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        threeDotButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        
        songQueueListButton.leftAnchor.constraint(equalTo: x.leftAnchor).isActive = true
        songQueueListButton.centerYAnchor.constraint(equalTo: x.centerYAnchor).isActive = true
        songQueueListButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        songQueueListButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        return x
        
    }()
    
    
    
    func setUpViews(){
        
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.layoutIfNeeded()
        
        view.clipsToBounds = true
        
        view.addSubview(backGroundBluryView)
        view.addSubview(scrubbingSlider)
        view.addSubview(topNub)
        view.addSubview(textInfoStackView)
        view.addSubview(mediaButtonHolderView)
        view.addSubview(volumeSliderHolderView)
        view.addSubview(bottomBarHolderView)
        view.addSubview(minimizedNowPlayingPreview)
        view.addSubview(albumImage)

        // MARK: - SETUP VIEWS VISIBLE IN MINIMIZED STATE
        
        setInitialAlbumCoverConstraints()
        
        
        backGroundBluryView.pinAllSidesTo(view)
        
        
        
        

        
        minimizedNowPlayingPreview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        minimizedNowPlayingPreview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        minimizedNowPlayingPreview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        minimizedNowPlayingPreview.heightAnchor.constraint(equalToConstant: AppManager.minimizedMusicViewHeight).isActive = true
        
        

        
        
        // MARK: - SETUP VIEWS VISIBLE IN MAXIMIZED STATE

        
        
        
        
        topNub.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        topNub.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topNub.widthAnchor.constraint(equalToConstant: 60).isActive = true
        topNub.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        
        
        textInfoStackView.topAnchor.constraint(equalTo: scrubbingSlider.bottomAnchor, constant: Variations.MusicView.distance_from_ScrubbingSliderBottom_to_InfoLabelsTop).isActive = true
        textInfoStackView.leftAnchor.constraint(equalTo: scrubbingSlider.leftAnchor).isActive = true
        textInfoStackView.rightAnchor.constraint(equalTo: scrubbingSlider.rightAnchor).isActive = true
        
    
        
        mediaButtonHolderView.topAnchor.constraint(equalTo: textInfoStackView.lastBaselineAnchor).isActive = true
        mediaButtonHolderView.bottomAnchor.constraint(equalTo: volumeSliderHolderView.centerYAnchor).isActive = true
        mediaButtonHolderView.leftAnchor.constraint(equalTo: scrubbingSlider.leftAnchor).isActive = true
        mediaButtonHolderView.rightAnchor.constraint(equalTo: scrubbingSlider.rightAnchor).isActive = true
        
        
        
        

        
        volumeSliderHolderView.leftAnchor.constraint(equalTo: scrubbingSlider.leftAnchor).isActive = true
        volumeSliderHolderView.rightAnchor.constraint(equalTo: scrubbingSlider.rightAnchor).isActive = true
        volumeSliderHolderView.bottomAnchor.constraint(equalTo: bottomBarHolderView.topAnchor, constant: 5).isActive = true
        volumeSliderHolderView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        
        
        
        
        bottomBarHolderView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(APP_INSETS.bottom + 15)).isActive = true
        
        bottomBarHolderView.leftAnchor.constraint(equalTo: scrubbingSlider.leftAnchor).isActive = true
        bottomBarHolderView.rightAnchor.constraint(equalTo: scrubbingSlider.rightAnchor).isActive = true
        bottomBarHolderView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        
        
    }
    
    
    
    
    
    
    // MARK: - TAP GESTURE RECOGNIZERS
    
    lazy var goUpRecognizer = UITapGestureRecognizer(target: self, action: #selector(liftUpMusicViewTapGestureSelectorFunction))
    
    
    lazy var bringBackDownGesture = UIPanGestureRecognizer(target: self, action: #selector(bringMusicViewBackDown(gesture:)))
    
    
    lazy var topNubGesture = UITapGestureRecognizer(target: self, action: #selector(finishBringingMusicViewDown))
    
    
    lazy var longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(respondToLongPress(gesture:)))
    
    
    
    @objc private func respondToLongPress(gesture: UILongPressGestureRecognizer){
        
        if gesture.state == .began{
            AppManager.shared.displayActionMenuFor(song: currentlyPlayingSong!)
        }
        
        
    }
    
}
