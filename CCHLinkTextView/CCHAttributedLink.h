//
//  CCHAttributedLink.h
//  Pods
//
//  Created by Kostia Dombrovsky on 5/16/16.
//  Copyright (c) 2016 ${ORGANIZATION_NAME}. All rights reserved.
//

@import Foundation;


@interface CCHAttributedLink : NSObject <NSCoding>

/**
 An `NSTextCheckingResult` representing the link's location and type.
 */
@property (readonly, nonatomic, strong) NSTextCheckingResult *result;

/**
 A dictionary containing the @c NSAttributedString attributes to be applied to the link.
 */
@property (readonly, nonatomic, copy) NSDictionary *attributes;

/**
 A dictionary containing the @c NSAttributedString attributes to be applied to the link when it is in the active state.
 */
@property (readonly, nonatomic, copy) NSDictionary *activeAttributes;

/**
 A dictionary containing the @c NSAttributedString attributes to be applied to the link when it is in the inactive state, which is triggered by a change in `tintColor` in iOS 7 and later.
 */
@property (readonly, nonatomic, copy) NSDictionary *inactiveAttributes;

/**
 Additional information about a link for VoiceOver users. Has default values if the link's @c result is @c NSTextCheckingTypeLink, @c NSTextCheckingTypePhoneNumber, or @c NSTextCheckingTypeDate.
 */
@property (nonatomic, copy) NSString *accessibilityValue;

/**
 Initializes a link using the attribute dictionaries specified.

 @param attributes         The @c attributes property for the link.
 @param activeAttributes   The @c activeAttributes property for the link.
 @param inactiveAttributes The @c inactiveAttributes property for the link.
 @param result             An @c NSTextCheckingResult representing the link's location and type.

 @return The initialized link object.
 */
- (instancetype)initWithAttributes:(NSDictionary *)attributes
                  activeAttributes:(NSDictionary *)activeAttributes
                inactiveAttributes:(NSDictionary *)inactiveAttributes
                textCheckingResult:(NSTextCheckingResult *)result;

@end
