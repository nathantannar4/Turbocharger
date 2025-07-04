//
// Copyright (c) Nathan Tannar
//

@import QuartzCore;

/// Exposes `CAFilter` API
@interface CAFilter : NSObject

+ (nullable instancetype)filterWithType:(nonnull NSString *)type;
@property (nullable, copy) NSString *name;

@end

/// Exposes `CABackdropLayer` API
@interface CABackdropLayer : CALayer

@property (nullable, copy) NSString *groupName;
@property (nullable, copy) NSArray<CAFilter *> *filters;
@property BOOL allowsHitTesting;
@property BOOL windowServerAware;
@property BOOL allowsGroupBlending;
@property BOOL allowsGroupOpacity;
@property BOOL allowsEdgeAntialiasing;
@property BOOL disablesOccludedBackdropBlurs;
@property BOOL ignoresOffscreenGroups;
@property BOOL allowsInPlaceFiltering;
@property CGFloat bleedAmount;
@property CGFloat scale;

@end
