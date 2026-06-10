#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.example.apple-samplecode.OrtioD763CZ24GN";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "EnvironmentTips" asset catalog image resource.
static NSString * const ACImageNameEnvironmentTips AC_SWIFT_PRIVATE = @"EnvironmentTips";

/// The "ObjectCharacteristicsTips" asset catalog image resource.
static NSString * const ACImageNameObjectCharacteristicsTips AC_SWIFT_PRIVATE = @"ObjectCharacteristicsTips";

/// The "PhotographyTips" asset catalog image resource.
static NSString * const ACImageNamePhotographyTips AC_SWIFT_PRIVATE = @"PhotographyTips";

/// The "ResetBbox" asset catalog image resource.
static NSString * const ACImageNameResetBbox AC_SWIFT_PRIVATE = @"ResetBbox";

/// The "Reticle" asset catalog image resource.
static NSString * const ACImageNameReticle AC_SWIFT_PRIVATE = @"Reticle";

#undef AC_SWIFT_PRIVATE
