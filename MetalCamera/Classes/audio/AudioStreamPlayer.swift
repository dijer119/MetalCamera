//
//  AudioStreamPlayer.swift
//  MetalCamera
//
//  Created by Eric on 2020/06/08.
//

import Foundation
import AVFoundation

public class AudioStreamPlayer: AudioOperationChain {
    public var audioTargets = TargetContainer<AudioOperationChain>()
    public var preservedBuffer: AudioBuffer?

    public init() {
    }

    public func newAudioAvailable(_ sampleBuffer: AudioBuffer) {
        playSampleBuffer(sampleBuffer)
        audioOperationFinished(sampleBuffer)
    }

    func playSampleBuffer(_ sampleBuffer: AudioBuffer) {
        let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer.buffer)
        let blockBufferDataLength = CMBlockBufferGetDataLength(blockBuffer!)

        var blockBufferData  = [UInt8](repeating: 0, count: blockBufferDataLength)
        let status = CMBlockBufferCopyDataBytes(blockBuffer!, 0, blockBufferDataLength, &blockBufferData)
        guard status == noErr else { return }
        let data = Data(bytes: blockBufferData, count: blockBufferDataLength)
    }
}
