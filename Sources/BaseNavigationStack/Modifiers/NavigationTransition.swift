import SwiftUI

private struct NavigationTransitionNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    /// Namespace shared by zoom sources and destinations. Set by `navigationRouter(...)`.
    var navigationTransitionNamespace: Namespace.ID? {
        get { self[NavigationTransitionNamespaceKey.self] }
        set { self[NavigationTransitionNamespaceKey.self] = newValue }
    }
}

public extension View {
    /// Marks this view as the origin of a zoom push started with `router.push(_:zoomFrom:)` using the same `id`.
    /// No-op before iOS 18 and on platforms without zoom transitions, where the push uses the default animation.
    @ViewBuilder
    func baseNavigationTransitionSource(id: some Hashable & Sendable) -> some View {
        modifier(TransitionSourceModifier(id: id))
    }
}

private struct TransitionSourceModifier<ID: Hashable & Sendable>: ViewModifier {
    let id: ID
    @Environment(\.navigationTransitionNamespace) private var namespace

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 18, *), let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// Applies the zoom destination transition when the router recorded a source for the route.
struct ZoomDestinationModifier: ViewModifier {
    let sourceID: AnyHashable?
    @Environment(\.navigationTransitionNamespace) private var namespace

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 18, *), let sourceID, let namespace {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// Sheet presentation options. Conform the app's `Sheet` type to `SheetPresentable` to have the
/// router apply them; sheets that don't conform keep the system defaults.
public struct SheetOptions {
    public var detents: Set<PresentationDetent>
    public var dragIndicator: Visibility
    public var cornerRadius: CGFloat?
    /// Largest detent that still lets touches reach the presenting view (nil = fully modal).
    public var backgroundInteractionUpThrough: PresentationDetent?
    public var interactiveDismissDisabled: Bool

    public init(
        detents: Set<PresentationDetent> = [.large],
        dragIndicator: Visibility = .automatic,
        cornerRadius: CGFloat? = nil,
        backgroundInteractionUpThrough: PresentationDetent? = nil,
        interactiveDismissDisabled: Bool = false
    ) {
        self.detents = detents
        self.dragIndicator = dragIndicator
        self.cornerRadius = cornerRadius
        self.backgroundInteractionUpThrough = backgroundInteractionUpThrough
        self.interactiveDismissDisabled = interactiveDismissDisabled
    }
}

public protocol SheetPresentable {
    var sheetOptions: SheetOptions { get }
}

struct SheetOptionsModifier: ViewModifier {
    let options: SheetOptions?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let options {
            content
                .presentationDetents(options.detents)
                .presentationDragIndicator(options.dragIndicator)
                .presentationCornerRadius(options.cornerRadius)
                .presentationBackgroundInteraction(
                    options.backgroundInteractionUpThrough.map { .enabled(upThrough: $0) } ?? .automatic
                )
                .interactiveDismissDisabled(options.interactiveDismissDisabled)
        } else {
            content
        }
    }
}
