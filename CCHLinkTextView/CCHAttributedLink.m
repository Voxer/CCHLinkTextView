//
//  CCHAttributedLink.m
//  Pods
//
//  Created by Kostia Dombrovsky on 5/16/16.
//  Copyright (c) 2016 ${ORGANIZATION_NAME}. All rights reserved.
//

#import "CCHAttributedLink.h"

@interface CCHAttributedLink ()
@end

@implementation CCHAttributedLink

- (instancetype) initWithAttributes: (NSDictionary*) attributes
                   activeAttributes: (NSDictionary*) activeAttributes
                 inactiveAttributes: (NSDictionary*) inactiveAttributes
                 textCheckingResult: (NSTextCheckingResult*) result
{
    if ((self = [super init]))
    {
        _result = result;
        _attributes = [attributes copy];
        _activeAttributes = [activeAttributes copy];
        _inactiveAttributes = [inactiveAttributes copy];
    }

    return self;
}

#pragma mark - Accessibility

- (NSString *) accessibilityValue {
    if ([_accessibilityValue length] == 0) {
        switch (self.result.resultType) {
            case NSTextCheckingTypeLink:
                _accessibilityValue = self.result.URL.absoluteString;
                break;
            case NSTextCheckingTypePhoneNumber:
                _accessibilityValue = self.result.phoneNumber;
                break;
            case NSTextCheckingTypeDate:
                _accessibilityValue = [NSDateFormatter localizedStringFromDate:self.result.date
                                                                     dateStyle:NSDateFormatterLongStyle
                                                                     timeStyle:NSDateFormatterLongStyle];
                break;
            default:
                break;
        }
    }

    return _accessibilityValue;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.result forKey:NSStringFromSelector(@selector(result))];
    [aCoder encodeObject:self.attributes forKey:NSStringFromSelector(@selector(attributes))];
    [aCoder encodeObject:self.activeAttributes forKey:NSStringFromSelector(@selector(activeAttributes))];
    [aCoder encodeObject:self.inactiveAttributes forKey:NSStringFromSelector(@selector(inactiveAttributes))];
    [aCoder encodeObject:self.accessibilityValue forKey:NSStringFromSelector(@selector(accessibilityValue))];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        _result = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(result))];
        _attributes = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(attributes))];
        _activeAttributes = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(activeAttributes))];
        _inactiveAttributes = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(inactiveAttributes))];
        self.accessibilityValue = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(accessibilityValue))];
    }

    return self;
}

@end
