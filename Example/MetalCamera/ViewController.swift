//
//  ViewController.swift
//  MetalCamera
//
//  Created by jsharp83 on 06/04/2020.
//  Copyright (c) 2020 jsharp83. All rights reserved.
//

import UIKit
import MetalCamera
import AVKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var preview: MetalVideoView!
    @IBOutlet weak var recordButton: UIButton!

    var camera: MetalCamera!
    var video: MetalVideoLoader?
    var videoCompositor: ImageCompositor!
    var audioCompositor: AudioCompositor!
    var recorder: MetalVideoWriter?

    let useMic = true

    var recordingURL: URL {
        let documentsDir = try? FileManager.default.url(for:. documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = URL(string: "recording.mov", relativeTo: documentsDir)!
        return fileURL
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCamera()
        setupVideo()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try audioSession.setMode(.videoChat)
            try audioSession.setActive(true)
        } catch {
            debugPrint(error)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera?.startCapture()
        video?.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera?.stopCapture()
        video?.stop()
    }

    @IBAction func didTapRecordButton(_ sender: Any) {
        if let recorder = recorder {
            preview.removeTarget(recorder)

            if useMic {
                audioCompositor.removeAudioTarget(recorder)
            }

            recorder.finishRecording { [weak self] in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    let player = AVPlayer(url: self.recordingURL)

                    let vc = AVPlayerViewController()
                    vc.player = player

                    self.present(vc, animated: true) { vc.player?.play() }

                    self.recorder = nil

                    self.recordButton.setTitle("Record Start", for: .normal)
                }
            }
        } else {
            do {
                if FileManager.default.fileExists(atPath: recordingURL.path) {
                    try FileManager.default.removeItem(at: recordingURL)
                }

                recorder = try MetalVideoWriter(url: recordingURL, videoSize: CGSize(width: 720, height: 1280), recordAudio: useMic)
                if let recorder = recorder {
                    preview-->recorder

                    if useMic {
                        audioCompositor==>recorder
                    }

                    recorder.startRecording()
                }

                recordButton.setTitle("Record Stop", for: .normal)
            } catch {
                debugPrint(error)
            }
        }
    }
}

// MARK: Setup Funcs
extension ViewController {
    func setupCamera() {
        guard let camera = try? MetalCamera(useMic: useMic) else { return }

        let rotation90 = RotationOperation(.degree90_flip)

        let imageCompositor = ImageCompositor(baseTextureKey: camera.sourceKey)
        guard let testImage = UIImage(named: "sampleImage") else {
            fatalError("Check image resource")
        }

        let gray = Gray()

        let compositeFrame = CGRect(x: 50, y: 100, width: 250, height: 250)
        imageCompositor.addCompositeImage(testImage)
        imageCompositor.sourceFrame = compositeFrame

        videoCompositor = ImageCompositor(baseTextureKey: camera.sourceKey)
        videoCompositor.sourceFrame = CGRect(x: 320, y: 100, width: 450, height: 250)

        camera-->rotation90-->gray-->imageCompositor-->videoCompositor-->preview
        self.camera = camera

        audioCompositor = AudioCompositor(camera.sourceKey)
        camera==>audioCompositor
    }

    func setupVideo() {
        let bundleURL = Bundle.main.resourceURL!
        let movieURL = URL(string: "bunny.mp4", relativeTo: bundleURL)!
        do {
            let videoLoader = try MetalVideoLoader(url: movieURL, useAudio: true)
            videoCompositor.sourceTextureKey = videoLoader.sourceKey
            videoLoader-->videoCompositor
            videoLoader==>audioCompositor
            video = videoLoader
        } catch {
            debugPrint(error)
        }
    }
}
