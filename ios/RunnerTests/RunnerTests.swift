import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  private let iosID = "123-ios.apps.googleusercontent.com"
  private let webID = "123-web.apps.googleusercontent.com"

  func testCustomConfigurationTakesPrecedence() {
    let resolved = GoogleOAuthConfiguration.resolve(info: [
      "NoteGoogleIOSClientID": iosID,
      "NoteGoogleServerClientID": webID,
      "GIDClientID": "456-ios.apps.googleusercontent.com"
    ])
    XCTAssertEqual(resolved["clientId"] as? String, iosID)
    XCTAssertEqual(resolved["serverClientId"] as? String, webID)
  }

  func testBlankBuildSettingsDoNotHideStandardGoogleConfiguration() {
    let resolved = GoogleOAuthConfiguration.resolve(info: [
      "NoteGoogleIOSClientID": "",
      "NoteGoogleServerClientID": "$(GOOGLE_SERVER_CLIENT_ID)",
      "GIDClientID": " \(iosID)\n",
      "GIDServerClientID": webID
    ])
    XCTAssertEqual(resolved["clientId"] as? String, iosID)
    XCTAssertEqual(resolved["serverClientId"] as? String, webID)
  }

  func testBundledGoogleConfigurationProvidesIOSClientOnly() {
    let resolved = GoogleOAuthConfiguration.resolve(
      info: ["GIDServerClientID": webID],
      googleInfo: ["CLIENT_ID": iosID, "REVERSED_CLIENT_ID": "com.googleusercontent.apps.123-ios"]
    )
    XCTAssertEqual(resolved["clientId"] as? String, iosID)
    XCTAssertEqual(resolved["serverClientId"] as? String, webID)
    XCTAssertEqual(resolved["urlSchemes"] as? [String], [])
  }

  func testOnlyRegisteredCallbackSchemesAreReturned() {
    let schemes = ["com.googleusercontent.apps.123-ios", "ShareMedia-note"]
    let resolved = GoogleOAuthConfiguration.resolve(info: [
      "CFBundleURLTypes": [["CFBundleURLSchemes": schemes]]
    ])
    XCTAssertEqual(resolved["urlSchemes"] as? [String], schemes)
  }

}
