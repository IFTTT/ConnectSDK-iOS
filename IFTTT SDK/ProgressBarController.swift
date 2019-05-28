//
//  ProgressBarController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 3/28/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

/// Interface for a `ProgressBar` view to use in conjunction with a `ProgressBarCoordinator`
@available(iOS 10.0, *)
protocol ProgressBar {
    
    /// Shows the `ProgressBar`.
    ///
    /// - Parameters:
    ///   - start: A value representing the starting value of the progress bar's fraction complete.
    ///   - end: A value representing the ending value of the progress bar's fraction complete.
    ///   - duration: The amount of time the animation should take.
    ///   - curve: The `UIView.AnimationCurve` to configure the `UIViewPropertyAnimator`.
    /// - Returns: A `UIViewPropertyAnimator` configured to show the progress bar.
    func showProgress(from start: CGFloat, to end: CGFloat,
                      duration: TimeInterval, curve: UIView.AnimationCurve) -> UIViewPropertyAnimator
}

/// Coordinators the animation of a `ProgressBar` during a long running operation
@available(iOS 10.0, *)
final class ProgressBarController {
    
    struct Constants {
        static let defaultDuration: TimeInterval = 1.5
    }
    
    private let progressBar: ProgressBar
    private let pauseAt: CGFloat
    private let duration: TimeInterval
    
    /// The current duration the progress bar is at.
    private var currentDuration: TimeInterval {
        guard let currentAnimation = currentAnimation else {
            return 0
        }
        
        return Double(currentAnimation.fractionComplete) * currentAnimation.duration
    }
    
    /// Creates a `ProgressBarCoordinator`
    ///
    /// - Parameters:
    ///   - progressBar: A `ProgressBar` to acuate
    ///   - offset: An offset between 0 and 1 to pause at if the operation takes longer than expected. Default value is 0.75.
    ///   - duration: The duration to complete the progress animation. Default value is Constants.defaultTimeout (1.5).
    init(progressBar: ProgressBar, pauseAt offset: CGFloat = 0.75, duration: TimeInterval = Constants.defaultDuration) {
        assert(offset > 0 && offset < 1, "Offset must be between 0 and 1")
        
        self.progressBar = progressBar
        self.pauseAt = offset
        self.duration = duration
    }
    
    private var currentAnimation: UIViewPropertyAnimator?
    
    /// Begins the progress animation
    func begin() {
        guard currentAnimation == nil else {
            return
        }
        currentAnimation = progressBar.showProgress(from: 0,
                                                    to: pauseAt,
                                                    duration: TimeInterval(pauseAt) * duration,
                                                    curve: .linear)
        currentAnimation?.startAnimation()
    }
    
    /// Tells the coordinator to wait for an amount of time before call its completion handler.
    ///
    /// - Parameters:
    ///   - minimumDuration: The amount of time you would like to wait.
    ///   - completionHandler: Called when the amount of time has passed.
    func wait(until minimumDuration: TimeInterval, _ completionHandler: @escaping () -> Void) {
        let timeTillMinimumDuration = max(0, minimumDuration - currentDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeTillMinimumDuration) {
            completionHandler()
        }
    }
    
    /// Tells the coordinator that the associated long running task is complete
    /// If the progress animation hasn't finished, this waits then calls the completion handler.
    ///
    /// - Parameter completionHandler: Called when the progress bar reaches the end
    func finish(extendingDurationBy additionalDuration: TimeInterval = 0, _ completionHandler: @escaping () -> Void) {
        guard let currentAnimation = currentAnimation else {
            completionHandler()
            return
        }
        
        func finalAnimation(from start: CGFloat) {
            let remainingDuration = TimeInterval(1 - start) * duration + additionalDuration
            progressBar.showProgress(from: start, to: 1,
                                     duration: remainingDuration,
                                     curve: .linear).startAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingDuration) {
                completionHandler()
            }
        }
        
        if currentAnimation.isRunning {
            // The amount progressed from 0 to 1
            // Since we asked the progress bar to stop at the `pauseAt` amount we have to apply that ratio first
            let progressAmount = pauseAt * currentAnimation.fractionComplete
            
            currentAnimation.stopAnimation(true)
            currentAnimation.finishAnimation(at: .current)
            
            finalAnimation(from: progressAmount)
        } else {
            finalAnimation(from: pauseAt)
        }
    }
}

