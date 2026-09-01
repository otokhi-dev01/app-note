import Flutter
import SwiftUI
import UIKit

public class IOSImageEditorPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "ios_image_editor",
            binaryMessenger: registrar.messenger()
        )
        let instance = IOSImageEditorPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "editImage" else {
            result(FlutterMethodNotImplemented)
            return
        }

        guard
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String,
            let image = UIImage(contentsOfFile: path)
        else {
            result(nil)
            return
        }

        guard
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }),
            let rootViewController = window.rootViewController
        else {
            result(nil)
            return
        }

        let editor = UIHostingController(
            rootView: EditorContainer(
                image: image,
                originalPath: path,
                completion: { editedPath in
                    result(editedPath)
                }
            )
        )

        editor.modalPresentationStyle = .fullScreen
        editor.view.frame = window.bounds

        DispatchQueue.main.async {
            var topViewController = rootViewController
            while let presented = topViewController.presentedViewController {
                topViewController = presented
            }

            let isPicker = topViewController is UIImagePickerController
                || String(describing: type(of: topViewController)).contains("PHPicker")

            let presentEditor = {
                rootViewController.present(editor, animated: true)
            }

            if isPicker || topViewController !== rootViewController {
                topViewController.dismiss(animated: false, completion: presentEditor)
            } else {
                presentEditor()
            }
        }
    }
}
