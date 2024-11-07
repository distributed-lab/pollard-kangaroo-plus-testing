//
//  NavigationManager.swift
//  clock-dl
//
//  Created by Jonikorjk on 24.03.2024.
//

import Foundation
import SwiftUI
import UIKit

class NavigationManager: UINavigationController {
    static var shared: NavigationManager = .init(rootViewController: ViewController())

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        navigationBar.tintColor = .label
        navigationBar.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pushView(_ view: some View, animated: Bool = true) {
        let viewController = UIHostingController(rootView: view)
        pushViewController(viewController, animated: animated)
    }

    func presentView(
        _ view: some View,
        presentationStyle: UIModalPresentationStyle = .overFullScreen,
        transitionStyle: UIModalTransitionStyle = .coverVertical,
        animated: Bool = true
    ) {
        let viewController = UIHostingController(rootView: view)
        viewController.modalPresentationStyle = presentationStyle
        viewController.modalTransitionStyle = transitionStyle
        present(viewController, animated: animated)
    }

    func showNativeAlert(
        title: String,
        message: String? = nil,
        actions: [UIAlertAction]
    ) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        for action in actions {
            alertController.addAction(action)
        }
        present(alertController, animated: true)
    }
}
