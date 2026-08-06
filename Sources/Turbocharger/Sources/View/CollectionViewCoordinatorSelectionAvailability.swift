//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public enum CollectionViewCoordinatorSelectionAvailability {
    case unavailable
    case disabled
    case available
}

#endif
