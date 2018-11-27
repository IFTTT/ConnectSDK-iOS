//
//  Autolayout.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
extension UIView {
    var constrain: Constraints {
        return Constraints(view: self)
    }
    
    struct Constraints {
        fileprivate let view: UIView
        
        fileprivate init(view: UIView) {
            self.view = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        func center(in otherView: UIView) {
            view.centerXAnchor.constraint(equalTo: otherView.centerXAnchor).isActive = true
            view.centerYAnchor.constraint(equalTo: otherView.centerYAnchor).isActive = true
        }
        func square() {
            view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        }
        func square(length: CGFloat) {
            view.heightAnchor.constraint(equalToConstant: length).isActive = true
            view.widthAnchor.constraint(equalToConstant: length).isActive = true
        }
        func width(to otherView: UIView) {
            view.widthAnchor.constraint(equalTo: otherView.widthAnchor).isActive = true
        }
        func edges(to otherView: UIView, edges: UIRectEdge = .all, inset: UIEdgeInsets = .zero) {
            if edges.contains(.top) {
                view.topAnchor.constraint(equalTo: otherView.topAnchor, constant: inset.top).isActive = true
            }
            if edges.contains(.left) {
                view.leftAnchor.constraint(equalTo: otherView.leftAnchor, constant: inset.left).isActive = true
            }
            if edges.contains(.bottom) {
                view.bottomAnchor.constraint(equalTo: otherView.bottomAnchor, constant: -inset.bottom).isActive = true
            }
            if edges.contains(.right) {
                view.rightAnchor.constraint(equalTo: otherView.rightAnchor, constant: -inset.right).isActive = true
            }
        }
        func edges(to guide: UILayoutGuide, edges: UIRectEdge = .all) {
            if edges.contains(.top) {
                view.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
            }
            if edges.contains(.left) {
                view.leftAnchor.constraint(equalTo: guide.leftAnchor).isActive = true
            }
            if edges.contains(.bottom) {
                view.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
            }
            if edges.contains(.right) {
                view.rightAnchor.constraint(equalTo: guide.rightAnchor).isActive = true
            }
        }
    }
}
