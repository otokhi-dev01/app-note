import Flutter
import QuickLook
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nativeMediaServices: NativeMediaServices?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let services = NativeMediaServices()
    services.register(with: engineBridge.applicationRegistrar.messenger())
    nativeMediaServices = services
  }
}

private final class NativeMediaServices: NSObject {
  private static let channelName = "com.kimchheang.otokhi-note/media"
  private var pendingEditorResult: FlutterResult?
  private weak var presentedEditorController: UIViewController?
  private var markupEditorCoordinator: NativeMarkupEditorCoordinator?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String,
      FileManager.default.isReadableFile(atPath: path)
    else {
      result(
        FlutterError(
          code: "INVALID_IMAGE",
          message: "A readable image path is required.",
          details: nil
        )
      )
      return
    }

    switch call.method {
    case "recognizeText":
      recognizeText(at: path, result: result)
    case "editImage":
      presentImageEditor(for: path, result: result)
    case "editPdf":
      presentPdfEditor(for: path, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func recognizeText(at path: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(
          url: URL(fileURLWithPath: path),
          options: [:]
        )
        try handler.perform([request])

        let text = (request.results ?? [])
          .compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n")

        DispatchQueue.main.async {
          result(text)
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "TEXT_RECOGNITION_FAILED",
              message: "The image could not be processed.",
              details: error.localizedDescription
            )
          )
        }
      }
    }
  }

  private func presentImageEditor(
    for path: String,
    result: @escaping FlutterResult
  ) {
    guard pendingEditorResult == nil else {
      result(
        FlutterError(
          code: "EDITOR_ALREADY_OPEN",
          message: "Another image is already being edited.",
          details: nil
        )
      )
      return
    }

    guard
      UIImage(contentsOfFile: path) != nil,
      let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow }),
      let rootViewController = window.rootViewController
    else {
      result(nil)
      return
    }

    pendingEditorResult = result
    let preview = QLPreviewController()
    let sourceExtension = URL(fileURLWithPath: path).pathExtension
    let coordinator = NativeMarkupEditorCoordinator(
      originalPath: path,
      outputExtension: sourceExtension.isEmpty ? "png" : sourceExtension,
      onFinish: { [weak self] editedPath in
        self?.completeEditing(with: editedPath)
      }
    )
    preview.dataSource = coordinator
    preview.delegate = coordinator
    preview.modalPresentationStyle = .fullScreen
    markupEditorCoordinator = coordinator
    presentedEditorController = preview
    present(preview, from: rootViewController)
  }

  private func presentPdfEditor(
    for path: String,
    result: @escaping FlutterResult
  ) {
    guard pendingEditorResult == nil else {
      result(
        FlutterError(
          code: "EDITOR_ALREADY_OPEN",
          message: "Another document is already being edited.",
          details: nil
        )
      )
      return
    }

    guard
      URL(fileURLWithPath: path).pathExtension.lowercased() == "pdf",
      let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow }),
      let rootViewController = window.rootViewController
    else {
      result(nil)
      return
    }

    pendingEditorResult = result
    let preview = QLPreviewController()
    let coordinator = NativeMarkupEditorCoordinator(
      originalPath: path,
      outputExtension: "pdf",
      onFinish: { [weak self] editedPath in
        self?.completeEditing(with: editedPath)
      }
    )
    preview.dataSource = coordinator
    preview.delegate = coordinator
    preview.modalPresentationStyle = .fullScreen
    markupEditorCoordinator = coordinator
    presentedEditorController = preview
    present(preview, from: rootViewController)
  }

  private func present(
    _ controller: UIViewController,
    from rootViewController: UIViewController
  ) {
    DispatchQueue.main.async {
      if let presented = rootViewController.presentedViewController {
        presented.dismiss(animated: false) {
          rootViewController.present(controller, animated: true)
        }
      } else {
        rootViewController.present(controller, animated: true)
      }
    }
  }

  private func completeEditing(with path: String?) {
    let result = pendingEditorResult
    pendingEditorResult = nil
    markupEditorCoordinator = nil
    let controller = presentedEditorController
    presentedEditorController = nil

    if let controller, controller.presentingViewController != nil {
      controller.dismiss(animated: true) {
        result?(path)
      }
    } else {
      result?(path)
    }
  }
}

/// Presents a file directly in `QLPreviewController`'s own markup editing
/// chrome (title menu, inline markup/undo/redo, PencilKit tool picker) with
/// no extra wrapping navigation bar, and copies the edited result out to a
/// temp file with the same extension as the source.
private final class NativeMarkupEditorCoordinator: NSObject,
  QLPreviewControllerDataSource,
  QLPreviewControllerDelegate
{
  private let fileURL: URL
  private let outputExtension: String
  private let onFinish: (String?) -> Void
  private var finished = false

  init(
    originalPath: String,
    outputExtension: String,
    onFinish: @escaping (String?) -> Void
  ) {
    fileURL = URL(fileURLWithPath: originalPath)
    self.outputExtension = outputExtension
    self.onFinish = onFinish
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    1
  }

  func previewController(
    _ controller: QLPreviewController,
    previewItemAt index: Int
  ) -> QLPreviewItem {
    fileURL as NSURL
  }

  func previewController(
    _ controller: QLPreviewController,
    editingModeFor previewItem: QLPreviewItem
  ) -> QLPreviewItemEditingMode {
    .createCopy
  }

  func previewController(
    _ controller: QLPreviewController,
    didSaveEditedCopyOf previewItem: QLPreviewItem,
    at modifiedContentsURL: URL
  ) {
    do {
      let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("edited_\(UUID().uuidString).\(outputExtension)")
      try FileManager.default.copyItem(at: modifiedContentsURL, to: outputURL)
      finish(outputURL.path)
    } catch {
      NSLog("Markup could not be saved: %@", error.localizedDescription)
      finish(nil)
    }
  }

  func previewControllerDidDismiss(_ controller: QLPreviewController) {
    finish(nil)
  }

  private func finish(_ path: String?) {
    guard !finished else { return }
    finished = true
    onFinish(path)
  }
}
