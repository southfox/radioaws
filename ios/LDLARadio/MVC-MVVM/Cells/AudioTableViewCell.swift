//
//  AudioTableViewCell.swift
//  LDLARadio
//
//  Created by Javier Fuchs on 1/6/17.
//  Copyright © 2017 Mobile Patagonia. All rights reserved.
//

import UIKit
import AlamofireImage
import JFCore
import AVKit
import MediaPlayer

class AudioTableViewCell: UITableViewCell {
    // MARK: Properties
    
    static let reuseIdentifier: String = "AudioTableViewCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var downloadStateLabel: UILabel!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var bookmarkButton: UIButton!
    
    weak var delegate: AudioTableViewCellDelegate?
    fileprivate let formatter = DateComponentsFormatter()
    let gradientBg = CAGradientLayer()


    // Player buttons
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var sliderView: UISlider!
    @IBOutlet weak var startOfStreamButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var endOfStreamButton: UIButton!
    @IBOutlet weak var resizeButton: UIButton!
    @IBOutlet weak var targetSoundButton: UIButton!

    @IBOutlet weak var graphButton: UIButton!
    @IBOutlet weak var playerStack: UIStackView!
    @IBOutlet weak var progressStack: UIStackView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var bugButton: UIButton!
    
    fileprivate var timerPlayed: Timer?

    var model : AudioViewModel? = nil {
        didSet {
            let labels = [downloadStateLabel, subtitleLabel, titleLabel]
            let texts = [model?.detail, model?.subTitle, model?.title]
            for i in 0..<3 {
                if let text = texts[i]?.text, text.count > 0 {
                    labels[i]?.isHidden = false
                    labels[i]?.text = text
                    labels[i]?.textColor = texts[i]?.color
                    labels[i]?.font = texts[i]?.font
                }
                else {
                    labels[i]?.isHidden = true
                    if i == 0 {
                        titleLabel.numberOfLines = 3
                    }
                    else if i == 1 {
                        titleLabel.numberOfLines += 2
                    }
                }
            }
            
            logoView.image = model?.placeholderImage
            thumbnailView.image = logoView.image
            if let thumbnailUrl = model?.thumbnailUrl {
                logoView.af_setImage(withURL: thumbnailUrl, placeholderImage: model?.placeholderImage) { (response) in
                    self.thumbnailView.image = self.logoView.image
                    self.model?.image = self.logoView.image
                }
            }
            bookmarkButton.isHighlighted = model?.isBookmarked ?? false
            bugButton.isHidden = (model?.error != nil) ? false : true
            targetSoundButton.isHidden = true
            graphButton.isHidden = true
            resizeButton.isHidden = true
            
            paintBgView()
            infoButton.isHidden = true
            
            let modelIsPlaying = model?.isPlaying ?? false
            
            if modelIsPlaying {
                playButton.isHidden = false
                playButton.isHighlighted = true

                infoButton.isHidden = model?.text?.count ?? 0 > 0
                selectionStyle = model?.selectionStyle ?? .none
                // show big logo, and hide thumbnail
                logoView.isHidden = false
                thumbnailView.isHidden = true
                playerStack.isHidden = false
                
                if let timerPlayed = timerPlayed {
                    timerPlayed.invalidate()
                }
                
                timerPlayed = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimePlayed), userInfo: nil, repeats: true)
                
            }
            else {
                playButton.isHighlighted = false
                selectionStyle = .none
                // show thumbnail, and hide logo
                logoView.isHidden = true
                thumbnailView.isHidden = false
                playerStack.isHidden = true
                progressStack.isHidden = true
                if let timerPlayed = timerPlayed {
                    timerPlayed.invalidate()
                }
                
                sliderView.isHidden = true
                currentTimeLabel.alpha = 0
                totalTimeLabel.alpha = 0
                backwardButton.isHidden = true
                forwardButton.isHidden = true
                startOfStreamButton.isHidden = true
                endOfStreamButton.isHidden = true
                
            }

            setNeedsLayout()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        gradientBg.startPoint = CGPoint.init(x: 0, y: 1)
        gradientBg.endPoint = CGPoint.init(x: 1, y: 1)
        gradientBg.colors = [UIColor.white.cgColor, UIColor.lightGray.cgColor]
        gradientBg.frame = contentView.bounds
        contentView.layer.insertSublayer(gradientBg, at: 0)
        
        formatter.allowedUnits = [.second, .minute, .hour]
        formatter.zeroFormattingBehavior = .pad
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for label in [ downloadStateLabel, subtitleLabel, titleLabel] {
            label?.text = ""
            label?.isHidden = false
            label?.numberOfLines = 1
        }
        
        logoView.image = nil
        downloadProgressView.isHidden = true
        bookmarkButton.isHighlighted = false
        infoButton.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let stream = StreamPlaybackManager.instance
        let currentStreamTime = stream.getCurrentTime()
        let isStreamPlaying = stream.isPlaying(url: model?.urlString())
        
        currentTimeLabel.alpha = !isStreamPlaying ? 0 : 1
        totalTimeLabel.alpha = !isStreamPlaying ? 0 : 1
        backwardButton.isHidden = !isStreamPlaying
        forwardButton.isHidden = !isStreamPlaying
        startOfStreamButton.isHidden = !isStreamPlaying
        endOfStreamButton.isHidden = !isStreamPlaying
        sliderView.isHidden = !isStreamPlaying

        let isPaused = stream.isPaused(url: model?.urlString())
        if isPaused {
            if playButton.isHighlighted {
                playButton.isHighlighted = false
            }
        }
        else {
            if !playButton.isHighlighted {
                playButton.isHighlighted = true
            }
        }

        if isStreamPlaying {
            let totalStreamTime = stream.getTotalTime()
            sliderView.value = Float(currentStreamTime)
            sliderView.maximumValue = Float(totalStreamTime)
            currentTimeLabel.text = timeStringFor(seconds: Float(currentStreamTime))
            totalTimeLabel.text = timeStringFor(seconds: Float(totalStreamTime))
            
            if sliderView.value >= sliderView.maximumValue {
                playButton.isHighlighted = false
                stream.pause()
            }
        }
    }
    
    @IBAction func bookmarkAction(_ sender: UIButton?) {
        bookmarkButton.isHighlighted = !bookmarkButton.isHighlighted
        delegate?.audioTableViewCell(self, bookmarkDidChange: bookmarkButton.isHighlighted)
    }
    
    @IBAction func playAction(_ sender: UIButton?) {
        let stream = StreamPlaybackManager.instance
        if stream.isPaused(url: model?.urlString()) {
            stream.playCurrentPosition()
        }
        else {
            stream.pause()
        }
        setNeedsLayout()
        delegate?.audioTableViewCell(self, didPlay: playButton.isHighlighted)
    }
    
    func startPlaying() {
        setNeedsLayout()
    }
    
    func play() {
        StreamPlaybackManager.instance.delegate = self
        setNeedsLayout()
    }
    
    @IBAction func startOfStreamAction(_ sender: UIButton?) {
        delegate?.audioTableViewCell(self, didChangePosition: 0)
    }
    
    @IBAction func endOfStreamAction(_ sender: UIButton?) {
        delegate?.audioTableViewCell(self, didChangeToEnd: true)
    }

    @IBAction func backwardAction(_ sender: UIButton?) {
        delegate?.audioTableViewCell(self, didChangeOffset: true)
    }
    
    @IBAction func forwardAction(_ sender: UIButton?) {
        delegate?.audioTableViewCell(self, didChangeOffset: false)
    }
    
    @IBAction func graphAction(_ sender: UIButton?) {
        graphButton.isHighlighted = !graphButton.isHighlighted
        delegate?.audioTableViewCell(self, didShowGraph: graphButton.isHighlighted)
    }
    
    @IBAction func infoAction(_ sender: UIButton?) {
        delegate?.audioTableViewCell(self, didShowInfo: infoButton.isHighlighted)
    }
    
    @IBAction func bugAction(_ sender: UIButton?) {
        delegate?.audioTableViewCell(self, didShowBug: true)
    }
    
    @IBAction func resizeAction(_ sender: UIButton?) {
        let isFullScreen = !(model?.isFullScreen ?? false)
        model?.isFullScreen = isFullScreen
        delegate?.audioTableViewCell(self, didResize: isFullScreen)
    }
    
    @IBAction func targetSoundAction(_ sender: UIButton?) {
        targetSoundButton.isHighlighted = !targetSoundButton.isHighlighted
        delegate?.audioTableViewCell(self, didChangeTargetSound: targetSoundButton.isHighlighted)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider?) {
        let value = sender?.value ?? 0
        delegate?.audioTableViewCell(self, didChangePosition: value)
        updateTimeLabel(with: value)
    }

    @objc fileprivate func updateTimePlayed() {
        setNeedsLayout()
    }
    
    private func updateTimeLabel(with updatedTime: Float) {
        currentTimeLabel.text = timeStringFor(seconds: updatedTime)
    }
    
    private func timeStringFor(seconds : Float) -> String?
    {
        guard let output = formatter.string(from: TimeInterval(seconds)) else {
            return nil
        }
        if seconds < 3600 {
            guard let rng = output.range(of: ":") else { return nil }
            return String(output[rng.upperBound...])
        }
        return output
    }
    
    private func paintBgView() {
        if let audioPlay = AudioPlay.search(byIdentifier: model?.id),
            audioPlay.isPlaying {
            gradientBg.isHidden = false
        }
        else {
            gradientBg.isHidden = true
        }
    }
    
}

protocol AudioTableViewCellDelegate: class {
    
    func audioTableViewCell(_ cell: AudioTableViewCell, downloadStateDidChange newState: Stream.DownloadState)
    func audioTableViewCell(_ cell: AudioTableViewCell, bookmarkDidChange newState: Bool)
    func audioTableViewCell(_ cell: AudioTableViewCell, didPlay newState: Bool)
    func audioTableViewCell(_ cell: AudioTableViewCell, didChangeOffset isBackward: Bool)
    func audioTableViewCell(_ cell: AudioTableViewCell, didChangeToEnd toEnd: Bool)
    func audioTableViewCell(_ cell: AudioTableViewCell, didChangePosition newState: Float)
    func audioTableViewCell(_ cell: AudioTableViewCell, didResize newState: Bool)
    func audioTableViewCell(_ cell: AudioTableViewCell, didChangeTargetSound newState: Bool)
    func audioTableViewCell(_ cell: AudioTableViewCell, didShowGraph newValue: Bool)
    func audioTableViewCell(_ cell: AudioTableViewCell, didShowInfo newValue: Bool)
    func audioTableViewCell(_ cell: AudioTableViewCell, didShowBug newValue: Bool)
}

/**
 Extend `AudioViewController` to conform to the `AssetPlaybackDelegate` protocol.
 */
extension AudioTableViewCell: AssetPlaybackDelegate {
    func streamPlaybackManager(_ streamPlaybackManager: StreamPlaybackManager, playerError error: JFError) {
        Analytics.logError(error: error)
        layoutIfNeeded()
    }
    
    func streamPlaybackManager(_ streamPlaybackManager: StreamPlaybackManager, playerReadyToPlay player: AVPlayer, isPlaying: Bool) {
        if isPlaying {
            print("JF FINALLY PLAYING")
        }
        else {
            print("JF PAUSE")
        }
        layoutIfNeeded()
    }
    
    func streamPlaybackManager(_ streamPlaybackManager: StreamPlaybackManager, playerCurrentItemDidChange player: AVPlayer) {
        print("JF CHANGE")
        layoutIfNeeded()
    }
}
