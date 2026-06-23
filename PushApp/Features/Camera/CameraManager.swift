//
//  CameraManager.swift
//  PushApp
//
//  Управляет AVCaptureSession, прогоняет кадры через PoseProcessor и
//  публикует глубину/позу для интерфейса. О каждом засчитанном отжимании
//  сообщает через монотонный счётчик repCount, за которым следит экран.
//

import Foundation
import AVFoundation
import ImageIO
import Combine

final class CameraManager: NSObject, ObservableObject {
    @Published var depthPercent: Double = 0
    @Published var pose: PoseResult?
    @Published var poseDetected = false
    @Published var isRunning = false
    /// Монотонный счётчик засчитанных отжиманий. За ним наблюдает экран тренировки.
    @Published private(set) var repCount = 0

    /// Когда false — кадры обрабатываются, но отжимания не считаются (например, во время отдыха).
    var countingEnabled = true

    let session = AVCaptureSession()
    private let sampleQueue = DispatchQueue(label: "pushapp.camera.samples")
    private let processor = PoseProcessor()
    private let counter = PushupCounter()
    private var useFrontCamera = true
    private let videoOutput = AVCaptureVideoDataOutput()
    private var lastProcessed = Date.distantPast

    // MARK: - Жизненный цикл

    func start() {
        sampleQueue.async { [weak self] in
            guard let self else { return }
            if self.session.inputs.isEmpty {
                self.configureSession()
            }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async { self.isRunning = true }
            }
        }
    }

    func stop() {
        sampleQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async { self.isRunning = false }
            }
        }
    }

    func resetCounter() {
        counter.reset()
        DispatchQueue.main.async { self.depthPercent = 0 }
    }

    func flipCamera() {
        sampleQueue.async { [weak self] in
            guard let self else { return }
            self.useFrontCamera.toggle()
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.addCameraInput()
            self.session.commitConfiguration()
        }
    }

    // MARK: - Настройка сессии

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        addCameraInput()

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        session.commitConfiguration()
    }

    private func addCameraInput() {
        let position: AVCaptureDevice.Position = useFrontCamera ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
                ?? AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
    }
}

// MARK: - Приём кадров

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Ограничиваем частоту обработки ~20 кадров/с, чтобы не греть устройство.
        let now = Date()
        guard now.timeIntervalSince(lastProcessed) > 0.05 else { return }
        lastProcessed = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Подсчёт идёт по углу в локте и не зависит от ориентации, поэтому используем
        // фиксированную портретную ориентацию (UIKit нельзя дёргать из фонового потока).
        let orientation: CGImagePropertyOrientation = useFrontCamera ? .leftMirrored : .right
        let result = processor.process(pixelBuffer: pixelBuffer, orientation: orientation, mirror: useFrontCamera)

        guard let result else {
            DispatchQueue.main.async { self.poseDetected = false }
            return
        }

        var repCompleted = false
        if let angle = result.elbowAngle, countingEnabled {
            repCompleted = counter.update(elbowAngle: angle)
        }
        let depth = counter.depthPercent

        DispatchQueue.main.async {
            self.pose = result
            self.poseDetected = !result.points.isEmpty
            self.depthPercent = depth
            if repCompleted { self.repCount += 1 }
        }
    }
}
