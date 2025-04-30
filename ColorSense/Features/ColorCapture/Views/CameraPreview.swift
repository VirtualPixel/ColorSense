import SwiftUI
@preconcurrency import AVFoundation

struct CameraPreview: UIViewRepresentable {
    private let source: PreviewSource

    init(source: PreviewSource) {
        self.source = source
    }

    func makeUIView(context: Context) -> PreviewView {
        let preview = PreviewView()
        source.connect(to: preview)

        // Add this debug check
        if let previewLayer = preview.layer as? AVCaptureVideoPreviewLayer,
           let session = (source as? DefaultPreviewSource)?.session {
            DebugHelper.verifySessionConnection(previewLayer: previewLayer, session: session)
        }

        return preview
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        /*if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }*/
    }

    /// A class that presents the captured content.
    ///
    /// This class owns the `AVCaptureVideoPreviewLayer` that presents the captured content.
    ///
    class PreviewView: UIView, PreviewTarget {
        func setVideoRotationAngle(_ angle: CGFloat) {
            // Do nothing
        }
        

        init() {
            super.init(frame: .zero)
    #if targetEnvironment(simulator)
            // The capture APIs require running on a real device. If running
            // in Simulator, display a static image to represent the video feed.
            let imageView = UIImageView(frame: UIScreen.main.bounds)
            imageView.image = UIImage(named: "video_mode")
            imageView.contentMode = .scaleAspectFill
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(imageView)
    #endif
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // Use the preview layer as the view's backing layer.
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        nonisolated func setSession(_ session: AVCaptureSession) {
            // Connects the session with the preview layer, which allows the layer
            // to provide a live view of the captured content.
            Task { @MainActor in
                previewLayer.session = session
            }
        }
    }
}

protocol PreviewSource: Sendable {
    // Connects a preview destination to this source.
    func connect(to target: PreviewTarget)
}

/// A protocol that passes the app's capture session to the `CameraPreview` view.
protocol PreviewTarget {
    // Sets the capture session on the destination.
    func setSession(_ session: AVCaptureSession)

    func setVideoRotationAngle(_ angle: CGFloat)
}

/// The app's default `PreviewSource` implementation.
struct DefaultPreviewSource: PreviewSource {

    let session: AVCaptureSession

    init(session: AVCaptureSession) {
        self.session = session
    }

    func connect(to target: PreviewTarget) {
        target.setSession(session)
    }
}

class DebugHelper {
    static func verifySessionConnection(previewLayer: AVCaptureVideoPreviewLayer, session: AVCaptureSession) {
        if previewLayer.session === session {
            print("SUCCESS: Preview layer is connected to the correct session")
        } else {
            print("ERROR: Preview layer is connected to a different session!")
        }
    }
}
