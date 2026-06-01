import Flutter
import GoogleMaps
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Google Maps iOS API Key
    GMSServices.provideAPIKey("AIzaSyCOQhQDvYJRkuzadJ21ar6xT8CzzkZqNO4")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
