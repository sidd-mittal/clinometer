//
//  ContentView.swift
//  Clinometer
//
//  Created by Sidd Mittal on 2024-03-03.
//

import SwiftUI
import CoreMotion
import AVFoundation
import UIKit

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start the camera session
        setupCamera()
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }
}

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

struct ContentView: View {
    @State private var roll: Double = 0.0
    @State private var pitch: Double = 0.0
    @State private var yaw: Double = 0.0
    private var motion = CMMotionManager()
    private let queue = OperationQueue()
    private let rollThreshold = 0.4

    var body: some View {
        ZStack {
            CameraView()
                .edgesIgnoringSafeArea(.all)

            Circle()
                .frame(width: 25, height: 25)
                .foregroundColor(.red)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 2)
                )
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)

            Rectangle()
                .frame(height: 2)
                .foregroundColor(isDeviceLevel(roll) ? .green : .red) // Change based on roll
                .padding(.horizontal, 50)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 + 50)

            VStack {
                Spacer()
                Text("Pitch: \(pitch) Degrees")
                Text(isDeviceLevel(roll) ? "Aligned" : "Align the device")
                    .foregroundColor(.white)
                    .bold()
            }.padding()
        }
        .onAppear() {
            self.startQueuedUpdates()
        }
    }
    
    private func isDeviceLevel(_ roll: Double) -> Bool {
        abs(roll) < rollThreshold || abs(roll - .pi) < rollThreshold
    }
    
    func startQueuedUpdates() {
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 60.0
            motion.showsDeviceMovementDisplay = true
            motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                                                   to: self.queue) { (data, error) in
                if let validData = data {
                    var adjustedPitch = validData.attitude.pitch - (Double.pi / 2)
                    adjustedPitch = -adjustedPitch
                    let pitch = adjustedPitch * (180 / .pi)
                    let roll = validData.attitude.roll

                    DispatchQueue.main.async {
                        self.roll = roll
                        self.pitch = pitch
                    }
                }
            }
        } else {
            print("Device motion is not available")
        }
    }

}

#Preview {
    ContentView()
}
