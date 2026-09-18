import Flutter
import Foundation
import libtesseract

public class IdentityOcrPlugin: NSObject, FlutterPlugin {
    private let queue = DispatchQueue(label: "com.piisiit.identity-ocr", qos: .userInitiated)

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.piisiit/identity_ocr", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(IdentityOcrPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "recognize" else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let dataPath = args["dataPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Image and OCR model paths are required.", details: nil))
            return
        }
        queue.async {
            let output: Any = autoreleasepool {
                guard let api = TessBaseAPICreate() else {
                    return FlutterError(code: "OCR_UNAVAILABLE", message: "Could not start Khmer recognition.", details: nil)
                }
                defer { TessBaseAPIEnd(api); TessBaseAPIDelete(api) }
                guard TessBaseAPIInit2(api, dataPath + "/tessdata", "khm+eng", OEM_LSTM_ONLY) == 0 else {
                    return FlutterError(code: "OCR_MODEL_ERROR", message: "Khmer recognition models could not load.", details: nil)
                }
                var pix = pixRead(path)
                guard let image = pix else {
                    return FlutterError(code: "INVALID_IMAGE", message: "The identity photo could not be read.", details: nil)
                }
                defer { pixDestroy(&pix) }
                TessBaseAPISetPageSegMode(api, PSM_AUTO)
                TessBaseAPISetImage2(api, image)
                guard let text = TessBaseAPIGetUTF8Text(api) else {
                    return FlutterError(code: "OCR_FAILED", message: "The identity photo could not be recognized.", details: nil)
                }
                defer { TessDeleteText(text) }
                return String(cString: text)
            }
            DispatchQueue.main.async { result(output) }
        }
    }
}
