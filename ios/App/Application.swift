import UIKit

@main
final class Application: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Biblia", sessionRole: session.role)
        configuration.delegateClass = BibleScene.self
        return configuration
    }
}

final class BibleScene: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let tabs = UITabBarController()
        let screens: [(FormScreen, String, String)] = [
            (LiturgyScreen(), "Liturgia", "calendar"),
            (BibleScreen(), "Czytaj Biblię", "book"),
            (QuoteScreen(), "Losuj cytat", "quote.bubble"),
            (SearchScreen(), "Wyszukaj", "magnifyingglass")
        ]
        tabs.viewControllers = screens.enumerated().map { index, item in
            let (screen, title, symbol) = item
            screen.title = title
            let navigation = UINavigationController(rootViewController: screen)
            navigation.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), tag: index)
            return navigation
        }
        let window = UIWindow(windowScene: scene)
        window.rootViewController = tabs
        self.window = window
        window.makeKeyAndVisible()
    }
}
