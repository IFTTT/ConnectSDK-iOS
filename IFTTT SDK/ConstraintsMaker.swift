//
//  ConstraintsMaker.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
extension UIView {
    
    /// Returns a `ConstraintsMaker` for this view
    var constrain: ConstraintsMaker {
        return ConstraintsMaker(view: self)
    }
}

/// Provides a consistent way to access layout anchors between `UIView` and `UILayoutGuide`
@available(iOS 10.0, *)
protocol LayoutGuide {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var heightAnchor: NSLayoutDimension { get }
    var widthAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
}

@available(iOS 10.0, *)
extension UIView: LayoutGuide { }

@available(iOS 10.0, *)
extension UILayoutGuide: LayoutGuide { }

/// A factory for `NSLayoutConstraint`
/// Creates layout regarding a single target view
@available(iOS 10.0, *)
struct ConstraintsMaker {
    
    struct Axis: OptionSet {
        let rawValue: Int
        
        static let horizontal = Axis(rawValue: 1 << 0)
        static let vertical = Axis(rawValue: 1 << 1)
        
        static let all: Axis = [.horizontal, .vertical]
    }
    
    /// The target view in layout constraints
    let view: UIView
    
    /// Creates a new `ConstraintsMaker`
    ///
    /// - Parameter view: The target view in layout constraints
    init(view: UIView) {
        self.view = view
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    /// Center the `view` within a guide.
    ///
    /// - Parameters:
    ///     - guide: The layout guide or view providing the center layout anchor.
    ///     - axis: The axes to which the `view` is centered. Default value is `all`.
    func center(in guide: LayoutGuide, axis: Axis = .all) {
        if axis.contains(.horizontal) {
            view.centerXAnchor.constraint(equalTo: guide.centerXAnchor).isActive = true
        }
        if axis.contains(.vertical) {
            view.centerYAnchor.constraint(equalTo: guide.centerYAnchor).isActive = true
        }
    }
    
    /// Constrains the `view` to a square. The `view`s width equals its height.
    func square() {
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
    
    /// Constrains the `view` to a square.
    ///
    /// - Parameter length: The length of the sides of the square.
    func square(length: CGFloat) {
        view.heightAnchor.constraint(equalToConstant: length).isActive = true
        view.widthAnchor.constraint(equalToConstant: length).isActive = true
    }

    func height(to constant: CGFloat) {
        view.heightAnchor.constraint(equalToConstant: constant).isActive = true
    }
    
    /// Constrains the `view`s width to that of a layout guide
    ///
    /// - Parameter guide: Provides the widthAnchor
    func width(to guide: LayoutGuide) {
        view.widthAnchor.constraint(equalTo: guide.widthAnchor).isActive = true
    }
    
    /// Constrains the `view`s edges to another view's edges
    ///
    /// - Parameters:
    ///   - guide: Provides the layout edge anchors
    ///   - edges: Pick to edges to use in the constraint. Default value is `all`.
    ///   - inset: The insets between each edge of the `view` and the `guide`
    func edges(to guide: LayoutGuide, edges: UIRectEdge = .all, inset: UIEdgeInsets = .zero) {
        if edges.contains(.top) {
            view.topAnchor.constraint(equalTo: guide.topAnchor, constant: inset.top).isActive = true
        }
        if edges.contains(.left) {
            view.leftAnchor.constraint(equalTo: guide.leftAnchor, constant: inset.left).isActive = true
        }
        if edges.contains(.bottom) {
            view.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -inset.bottom).isActive = true
        }
        if edges.contains(.right) {
            view.rightAnchor.constraint(equalTo: guide.rightAnchor, constant: -inset.right).isActive = true
        }
    }
}
