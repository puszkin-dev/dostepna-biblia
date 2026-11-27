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
        let tabs = BibleTabs()
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

final class BibleTabs: UITabBarController {
    private var firstAppearance = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard firstAppearance else { return }
        firstAppearance = false
        if UIAccessibility.isVoiceOverRunning, let first = tabBar.accessibilityElement(at: 0) {
            UIAccessibility.post(notification: .screenChanged, argument: first)
        }
    }
    override var keyCommands: [UIKeyCommand]? {
        let forward = UIKeyCommand(input: "\t", modifierFlags: .control, action: #selector(nextCard))
        let backward = UIKeyCommand(input: "\t", modifierFlags: [.control, .shift], action: #selector(previousCard))
        forward.discoverabilityTitle = "Następna karta"
        backward.discoverabilityTitle = "Poprzednia karta"
        return [forward, backward]
    }
    @objc private func nextCard() { changeCard(1) }
    @objc private func previousCard() { changeCard(-1) }
    private func changeCard(_ offset: Int) {
        guard let count = viewControllers?.count, count > 0 else { return }
        selectedIndex = (selectedIndex + count + offset) % count
    }
}
