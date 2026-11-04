import Sparkle
import SwiftUI

final class Updates: ObservableObject {
    static let shared = Updates()
    private let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    var automaticallyChecks: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set {
            objectWillChange.send()
            controller.updater.automaticallyChecksForUpdates = newValue
        }
    }

    func check() {
        controller.checkForUpdates(nil)
    }
}
