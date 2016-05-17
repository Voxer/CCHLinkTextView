//
//  CCHLinkTextView.m
//  CCHLinkTextView
//
//  Copyright (C) 2014 Claus Höfele
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

// Based on http://stackoverflow.com/questions/19332283/detecting-taps-on-attributed-text-in-a-uitextview-on-ios-7

#import "CCHLinkTextView.h"

#import "CCHLinkTextViewDelegate.h"
#import "CCHLinkGestureRecognizer.h"
#import "CCHAttributedLink.h"

NSString *const CCHLinkAttributeName = @"CCHLinkAttributeName";
#define DEBUG_COLOR [UIColor colorWithWhite:0 alpha:0.3]

@interface CCHLinkTextView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) CCHLinkGestureRecognizer* linkGestureRecognizer;

@property (nonatomic, strong) NSMutableArray<CCHAttributedLink*>* links;
@property (nonatomic, strong) NSArray<CCHAttributedLink*>*        linksForTouchDown;

@end

@implementation CCHLinkTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    self.links = [NSMutableArray new];
    self.linkTextTouchAttributes = @{NSBackgroundColorAttributeName : UIColor.lightGrayColor};
    
    self.tapAreaInsets = UIEdgeInsetsMake(-5, -5, -5, -5);
    
    self.editable = NO;
}

- (void)setEditable:(BOOL)editable
{
    // Allows you to optionally turn on/off the functionality that provides tappable links
    // but then revert to normal selection/editing text behavior when desired.
    super.editable = editable;
    if (editable) {
        self.selectable = YES;
        [self removeGestureRecognizer:self.linkGestureRecognizer];
    } else {
        self.selectable = NO;
        if (![self.gestureRecognizers containsObject:self.linkGestureRecognizer]) {
            self.linkGestureRecognizer = [[CCHLinkGestureRecognizer alloc] initWithTarget:self action:@selector(linkAction:)];
            self.linkGestureRecognizer.delegate = self;
            [self addGestureRecognizer:self.linkGestureRecognizer];
        }
    }
}

- (id)debugQuickLookObject
{
    if (self.bounds.size.width < 0.0f || self.bounds.size.height < 0.0f) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, self.window.screen.scale);

    // Draw rectangles for all links
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGContextSetFillColorWithColor(context, DEBUG_COLOR.CGColor);
    NSAttributedString *attributedString = self.attributedText;
    [attributedString enumerateAttribute:CCHLinkAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [self enumerateViewRectsForRanges:@[[NSValue valueWithRange:range]] usingBlock:^(CGRect rect, NSRange range, BOOL *stop) {
                CGContextFillRect(context, rect);
            }];
        }
    }];

    UIGraphicsPopContext();
    
    // Draw text
    CGRect rect = self.bounds;
    rect.origin.x += self.textContainerInset.left + self.textContainer.lineFragmentPadding;
    rect.origin.y += self.textContainerInset.top;
    [attributedString drawInRect:rect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setLinkTextAttributes:(NSDictionary *)linkTextAttributes
{
    [super setLinkTextAttributes:linkTextAttributes];
    [self setAttributedText:self.attributedText];
}

- (void)setLinkTextTouchAttributes:(NSDictionary *)linkTextTouchAttributes
{
    _linkTextTouchAttributes = linkTextTouchAttributes;
    [self setAttributedText:self.attributedText];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [self.links removeAllObjects];

    NSMutableAttributedString *mutableAttributedText = [attributedText mutableCopy];
    [mutableAttributedText enumerateAttribute:CCHLinkAttributeName inRange:NSMakeRange(0, attributedText.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [mutableAttributedText addAttributes:self.linkTextAttributes range:range];
        }
    }];
    
    [super setAttributedText:mutableAttributedText];
}

- (void) enumerateViewRectsForRanges: (NSArray<NSValue*>*) ranges
                          usingBlock: (void (^)(CGRect rect, NSRange range, BOOL* stop)) block
{
    if (!block) {
        return;
    }

    for (NSValue* rangeAsValue in ranges)
    {
        NSRange range = rangeAsValue.rangeValue;
        NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange: range actualCharacterRange: nil];
        [self.layoutManager enumerateLineFragmentsForGlyphRange: glyphRange
                                                     usingBlock: ^(CGRect r, CGRect usedRect, NSTextContainer* textContainer, NSRange lineRange, BOOL* stop)
                                                     {
                                                         [self.layoutManager enumerateEnclosingRectsForGlyphRange: NSIntersectionRange(glyphRange, lineRange)
                                                                                         withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0)
                                                                                                  inTextContainer: textContainer
                                                                                                       usingBlock: ^(CGRect highlightRect, BOOL* s)
                                                                                                       {
                                                                                                           highlightRect.origin.x  += self.textContainerInset.left;
                                                                                                           highlightRect.size.width = ceilf(highlightRect.size.width);
                                                                                                           block(highlightRect, range, s);
                                                                                                       }];
                                                     }];
    }
}

- (BOOL) enumerateLinkRangesContainingLocation: (CGPoint) location
                                    usingBlock: (void (^)(CCHAttributedLink* link)) block
{
    for (CCHAttributedLink* link in self.links)
    {
        __block BOOL found = NO;
        [self enumerateViewRectsForRanges: @[[NSValue valueWithRange: link.result.range]]
                               usingBlock: ^(CGRect rect, NSRange range, BOOL* stop)
                               {
                                   if (CGRectContainsPoint(rect, location))
                                   {
                                       if (block)
                                       {
                                           block(link);
                                       }
                                       found = YES;
                                       *stop = YES;
                                   }
                               }];
        if (found)
            return YES;
    }
    return NO;
}

- (void) addLink: (CCHAttributedLink*) link
{
    [self.links addObject: link];

    NSMutableDictionary<NSString*, id>* linkAttributes = [link.attributes mutableCopy];
    linkAttributes[CCHLinkAttributeName] = link;
    [self.textStorage addAttributes: linkAttributes
                              range: link.result.range];
}

- (void)setMinimumPressDuration:(CFTimeInterval)minimumPressDuration
{
    self.linkGestureRecognizer.minimumPressDuration = minimumPressDuration;
}

- (CFTimeInterval)minimumPressDuration
{
    return self.linkGestureRecognizer.minimumPressDuration;
}

- (void)setAllowableMovement:(CGFloat)allowableMovement
{
    self.linkGestureRecognizer.allowableMovement = allowableMovement;
}

- (CGFloat)allowableMovement
{
    return self.linkGestureRecognizer.allowableMovement;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.isEditable) {
        return [super pointInside:point withEvent:event];
    } else {
        BOOL linkFound = [self enumerateLinkRangesContainingLocation:point usingBlock:NULL];
        return linkFound;
    }
}

- (void) drawRect: (CGRect) rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (CCHAttributedLink* link in self.linksForTouchDown)
    {
        UIColor* backgroundColor = link.activeAttributes[NSBackgroundColorAttributeName];
        if (!backgroundColor)
            continue;

        [self enumerateViewRectsForRanges: @[[NSValue valueWithRange: link.result.range]]
                               usingBlock: ^(CGRect r, NSRange range, BOOL* stop)
                               {
                                   CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect: CGRectInset(r, -1.0f, 0.0f)
                                                                                        cornerRadius: self.linkCornerRadius].CGPath);
                               }];

        CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
        CGContextFillPath(context);
    }
    [super drawRect: rect];
}

#pragma mark Gesture recognition

- (void)linkAction:(CCHLinkGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSAssert(self.linksForTouchDown == nil, @"Invalid touch down ranges");
        
        CGPoint location = [recognizer locationInView:self];
        self.linksForTouchDown = [self didTouchDownAtLocation:location];
        if (self.linksForTouchDown.count)
            [self setNeedsDisplay];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSAssert(self.linksForTouchDown != nil, @"Invalid touch down ranges");
        
        if (recognizer.result == CCHLinkGestureRecognizerResultTap)
        {
            [self didTapAtRangeValues:self.linksForTouchDown];
        }
        else if (recognizer.result == CCHLinkGestureRecognizerResultLongPress)
        {
            [self didLongPressAtRangeValues:self.linksForTouchDown];
        }
        
        [self didCancelTouchDownAtRangeValues:self.linksForTouchDown];
        self.linksForTouchDown = nil;
        [self setNeedsDisplay];
    }
}

- (BOOL)                         gestureRecognizer: (UIGestureRecognizer*) gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer: (UIGestureRecognizer*) otherGestureRecognizer
{
    return YES;
}

#pragma mark Gesture handling

- (NSArray<CCHAttributedLink*>*) didTouchDownAtLocation: (CGPoint) location
{
    NSMutableArray<CCHAttributedLink*>* links = [NSMutableArray array];
    [self enumerateLinkRangesContainingLocation: location
                                     usingBlock: ^(CCHAttributedLink* link)
                                     {
                                         [links addObject: link];

                                         NSMutableAttributedString* attributedText = [self.attributedText mutableCopy];
                                         for (NSString* attribute in link.attributes)
                                         {
                                             [attributedText removeAttribute: attribute range: link.result.range];
                                         }

                                         [link.activeAttributes enumerateKeysAndObjectsUsingBlock: ^(NSString* attributeName, id attr, BOOL* stop)
                                         {
                                             if (![attributeName isEqualToString: NSBackgroundColorAttributeName])
                                                 [attributedText addAttribute: attributeName
                                                                        value: attr
                                                                        range: link.result.range];
                                         }];

                                         [super setAttributedText: attributedText];
                                     }];
    return links;
}

- (void)didCancelTouchDownAtRangeValues:(NSArray<CCHAttributedLink*>*)links
{
    NSMutableAttributedString* attributedText = [self.attributedText mutableCopy];
    for (CCHAttributedLink* link in links)
    {
        NSRange range = link.result.range;
        
        for (NSString *attribute in link.activeAttributes) {
            [attributedText removeAttribute:attribute range:range];
        }
        [attributedText addAttributes: link.attributes range: range];
    }
    [super setAttributedText:attributedText];
}

- (void)didTapAtRangeValues:(NSArray<CCHAttributedLink*>*)links
{
    if ([self.linkDelegate respondsToSelector:@selector(linkTextView:didTapLink:)])
    {
        for (CCHAttributedLink* link in links)
        {
            [self.linkDelegate linkTextView:self didTapLink:link];
        }
    }
}

- (void)didLongPressAtRangeValues:(NSArray<CCHAttributedLink*>*) links
{
    if ([self.linkDelegate respondsToSelector:@selector(linkTextView:didLongPressLink:)])
    {
        for (CCHAttributedLink* link in links)
        {
            [self.linkDelegate linkTextView:self didLongPressLink:link];
        }
    }
}

@end
