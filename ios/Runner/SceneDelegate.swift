import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    window = UIWindow(windowScene: windowScene)
    let flutterVC = FlutterViewController(
      project: nil,
      nibName: nil,
      bundle: nil
    )
    window?.rootViewController = flutterVC
    window?.makeKeyAndVisible()
  }
}
