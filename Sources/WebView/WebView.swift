import SwiftUI
import Combine
import WebKit

public class WebViewStore: ObservableObject {
    @Published public var webView: WKWebView {
        didSet {
            setupObservers()
        }
    }
    
    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        setupObservers()
    }
    
    private func setupObservers() {
        func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
            return webView.observe(keyPath, options: [.prior]) { _, change in
                if change.isPrior {
                    self.objectWillChange.send()
                }
            }
        }
        // Setup observers for all KVO compliant properties
        observers = [
            subscriber(for: \.title),
            subscriber(for: \.url),
            subscriber(for: \.isLoading),
            subscriber(for: \.estimatedProgress),
            subscriber(for: \.hasOnlySecureContent),
            subscriber(for: \.serverTrust),
            subscriber(for: \.canGoBack),
            subscriber(for: \.canGoForward)
        ]
    }
    
    private var observers: [NSKeyValueObservation] = []
    
    deinit {
        observers.forEach {
            // Not even sure if this is required?
            // Probably wont be needed in future betas?
            $0.invalidate()
        }
    }
}

#if os(iOS)
/// A container for using a WKWebView in SwiftUI
public struct WebView: View, UIViewRepresentable {
    /// The WKWebView to display
    public let webView: WKWebView
    
    public init(webView: WKWebView) {
        self.webView = webView
    }
    
    public func makeUIView(context: UIViewRepresentableContext<WebView>) -> UIView {
        return UIViewContainerView()
    }
    
    public func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<WebView>) {
        // If its the same content view we don't need to update.
        guard let uiView = uiView as? UIViewContainerView else {
            return
        }
        if uiView.contentView !== webView {
            uiView.contentView = webView
        }
    }
}

/// A UIView which simply adds some view to its view hierarchy
class UIViewContainerView<ContentView: UIView>: UIView {
    var contentView: ContentView? {
        willSet {
            contentView?.removeFromSuperview()
        }
        didSet {
            if let contentView = contentView {
                addSubview(contentView)
                contentView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    contentView.topAnchor.constraint(equalTo: topAnchor),
                    contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }
        }
    }
}

#elseif os(macOS)
/// A container for using a WKWebView in SwiftUI
public struct WebView: View, NSViewRepresentable {
    public let webView: WKWebView
    
    public init(webView: WKWebView) {
        self.webView = webView
    }
    
    public func makeNSView(context: Context) -> NSView {
        return NSViewContainerView()
    }
    
    public func updateNSView(_ view: NSView, context: Context) {
        guard let view = view as? NSViewContainerView else {
            return
        }
        if view.contentView !== webView {
            view.contentView = webView
        }
    }
}

/// A NSView which simply adds some view to its view hierarchy
class NSViewContainerView<ContentView: NSView>: NSView {
    var contentView: ContentView? {
        willSet {
            contentView?.removeFromSuperview()
        }
        didSet {
            if let contentView = contentView {
                addSubview(contentView)
                contentView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    contentView.topAnchor.constraint(equalTo: topAnchor),
                    contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }
        }
    }
}
#endif
