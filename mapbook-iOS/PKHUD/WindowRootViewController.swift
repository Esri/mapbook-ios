//
//  PKHUD.WindowRootViewController.swift
//  PKHUD
//
//  Created by Philip Kluz on 6/18/14.
//  Copyright (c) 2016 NSExceptional. All rights reserved.
//  Licensed under the MIT license.
//

import UIKit

/// Serves as a configuration relay controller, tapping into the main window's rootViewController settings.
internal class WindowRootViewController: UIViewController {

    internal override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            return rootViewController.supportedInterfaceOrientations
        } else {
            return UIInterfaceOrientationMask.portrait
        }
    }

    internal override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13, *) {
            return
                presentingViewController?.preferredStatusBarStyle ??
                view.window?.windowScene?.statusBarManager?.statusBarStyle ??
                .default
        }
        else {
            return
                presentingViewController?.preferredStatusBarStyle ??
                UIApplication.shared.statusBarStyle
        }
    }

    internal override var prefersStatusBarHidden: Bool {
        if #available(iOS 13, *) {
            return
                presentingViewController?.prefersStatusBarHidden ??
                view.window?.windowScene?.statusBarManager?.isStatusBarHidden ??
                false
        }
        else {
            return
                presentingViewController?.prefersStatusBarHidden ??
                UIApplication.shared.isStatusBarHidden
        }
    }

    internal override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            return rootViewController.preferredStatusBarUpdateAnimation
        } else {
            return .none
        }
    }

    internal override var shouldAutorotate: Bool {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            return rootViewController.shouldAutorotate
        } else {
            return false
        }
    }
}
