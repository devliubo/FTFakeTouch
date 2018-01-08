//
//  FTFakeTouch.m
//  FTFakeTouch
//
//  Created by 刘博 on 2018/1/9.
//  Copyright © 2018年 devliubo. All rights reserved.
//

#import "FTFakeTouch.h"
#import "UITouch-KIFAdditions.h"
#import "UIEvent+KIFAdditions.h"

#pragma mark - Private Interface Declare

@interface UIApplication ()
- (UIEvent *)_touchesEvent;
@end

@interface NSObject (UIWebDocumentViewInternal)
- (void)tapInteractionWithLocation:(CGPoint)point;
@end

#pragma mark - FTFakeTouch

#define kFakeTouchDragDelay      0.01
#define kFakeTouchTwoFingerWidth 40.f

@implementation FTFakeTouch

#pragma mark - Life Cycle

+ (void)load {
    load_UIEvent_KIFAdditions();
    load_UITouch_KIFAdditions();
}

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Interface For Window

- (void)tapAtPoint:(CGPoint)point {
    UITouch *touch = [[UITouch alloc] initAtPoint:point inWindow:[self defaultTouchWindow]];
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    
    UIEvent *event = [self eventWithTouch:touch];
    
    [[UIApplication sharedApplication] sendEvent:event];
    
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    [[UIApplication sharedApplication] sendEvent:event];
    
    UIView *touchView = touch.view;
    if ([touchView canBecomeFirstResponder]) {
        [touchView becomeFirstResponder];
    }
}

- (void)twoFingerTapAtPoint:(CGPoint)point {
    CGPoint finger1 = CGPointMake(point.x - kFakeTouchTwoFingerWidth, point.y - kFakeTouchTwoFingerWidth);
    CGPoint finger2 = CGPointMake(point.x + kFakeTouchTwoFingerWidth, point.y + kFakeTouchTwoFingerWidth);
    UITouch *touch1 = [[UITouch alloc] initAtPoint:finger1 inWindow:[self defaultTouchWindow]];
    UITouch *touch2 = [[UITouch alloc] initAtPoint:finger2 inWindow:[self defaultTouchWindow]];
    [touch1 setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    [touch2 setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    
    UIEvent *event = [self eventWithTouches:@[touch1, touch2]];
    [[UIApplication sharedApplication] sendEvent:event];
    
    [touch1 setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    [touch2 setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    
    [[UIApplication sharedApplication] sendEvent:event];
}

- (void)longPressAtPoint:(CGPoint)point duration:(NSTimeInterval)duration {
    UITouch *touch = [[UITouch alloc] initAtPoint:point inWindow:[self defaultTouchWindow]];
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    
    UIEvent *eventDown = [self eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventDown];
    
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, kFakeTouchDragDelay, false);
    
    for (NSTimeInterval timeSpent = kFakeTouchDragDelay; timeSpent < duration; timeSpent += kFakeTouchDragDelay) {
        [touch setPhaseAndUpdateTimestamp:UITouchPhaseStationary];
        
        UIEvent *eventStillDown = [self eventWithTouch:touch];
        [[UIApplication sharedApplication] sendEvent:eventStillDown];
        
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, kFakeTouchDragDelay, false);
    }
    
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    UIEvent *eventUp = [self eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventUp];
    
    UIView *touchView = touch.view;
    if ([touchView canBecomeFirstResponder]) {
        [touchView becomeFirstResponder];
    }
}

- (void)dragFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint steps:(NSUInteger)stepCount {
    NSArray *path = [self pointsFromStartPoint:startPoint toPoint:endPoint steps:stepCount];
    [self dragPointsAlongPaths:@[path]];
}

- (void)dragPointsAlongPaths:(NSArray *)arrayOfPaths {
    // must have at least one path, and each path must have the same number of points
    if (arrayOfPaths.count == 0) {
        return;
    }
    
    // all paths must have similar number of points
    NSUInteger pointsInPath = [arrayOfPaths[0] count];
    for (NSArray *path in arrayOfPaths) {
        if (path.count != pointsInPath) {
            return;
        }
    }
    
    NSMutableArray *touches = [NSMutableArray array];
    
    for (NSUInteger pointIndex = 0; pointIndex < pointsInPath; pointIndex++) {
        // create initial touch event and send touch down event
        if (pointIndex == 0) {
            for (NSArray *path in arrayOfPaths) {
                CGPoint point = [path[pointIndex] CGPointValue];
                UITouch *touch = [[UITouch alloc] initAtPoint:point inWindow:[self defaultTouchWindow]];
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
                [touches addObject:touch];
            }
            UIEvent *eventDown = [self eventWithTouches:[NSArray arrayWithArray:touches]];
            [[UIApplication sharedApplication] sendEvent:eventDown];
            
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, kFakeTouchDragDelay, false);
        } else {
            UITouch *touch;
            for (NSUInteger pathIndex = 0; pathIndex < arrayOfPaths.count; pathIndex++) {
                NSArray *path = arrayOfPaths[pathIndex];
                CGPoint point = [path[pointIndex] CGPointValue];
                touch = touches[pathIndex];
                [touch setLocationInWindow:point];
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseMoved];
            }
            UIEvent *event = [self eventWithTouches:[NSArray arrayWithArray:touches]];
            [[UIApplication sharedApplication] sendEvent:event];
            
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, kFakeTouchDragDelay, false);
            
            // The last point needs to also send a phase ended touch.
            if (pointIndex == pointsInPath - 1) {
                for (UITouch * touch in touches) {
                    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
                    UIEvent *eventUp = [self eventWithTouch:touch];
                    [[UIApplication sharedApplication] sendEvent:eventUp];
                }
            }
        }
    }
    
    UIView *touchView = ((UITouch *)touches[0]).view;
    if ([touchView canBecomeFirstResponder]) {
        [touchView becomeFirstResponder];
    }
    
    while (CFRunLoopCopyCurrentMode(CFRunLoopGetCurrent()) != kCFRunLoopDefaultMode) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }
}

#pragma mark - Interface For View

- (void)tapInView:(UIView *)view atPoint:(CGPoint)point {
    // Web views don't handle touches in a normal fashion, but they do have a method we can call to tap them
    // This may not be necessary anymore. We didn't properly support controls that used gesture recognizers
    // when this was added, but we now do. It needs to be tested before we can get rid of it.
    id /*UIWebBrowserView*/ webBrowserView = nil;
    
    if ([NSStringFromClass([view class]) isEqual:@"UIWebBrowserView"]) {
        webBrowserView = view;
    } else if ([view isKindOfClass:[UIWebView class]]) {
        id webViewInternal = [view valueForKey:@"_internal"];
        webBrowserView = [webViewInternal valueForKey:@"browserView"];
    }
    
    if (webBrowserView) {
        [webBrowserView tapInteractionWithLocation:point];
        return;
    }
    
    // Handle touches in the normal way for other views
    UITouch *touch = [[UITouch alloc] initAtPoint:point inView:view];
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    
    UIEvent *event = [self eventWithTouch:touch];
    
    [[UIApplication sharedApplication] sendEvent:event];
    
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    [[UIApplication sharedApplication] sendEvent:event];
    
    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touch.view isDescendantOfView:view] && [view canBecomeFirstResponder]) {
        [view becomeFirstResponder];
    }
}

- (void)twoFingerTapInView:(UIView *)view atPoint:(CGPoint)point {
    CGPoint finger1 = CGPointMake(point.x - kFakeTouchTwoFingerWidth, point.y - kFakeTouchTwoFingerWidth);
    CGPoint finger2 = CGPointMake(point.x + kFakeTouchTwoFingerWidth, point.y + kFakeTouchTwoFingerWidth);
    UITouch *touch1 = [[UITouch alloc] initAtPoint:finger1 inView:view];
    UITouch *touch2 = [[UITouch alloc] initAtPoint:finger2 inView:view];
    [touch1 setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    [touch2 setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    
    UIEvent *event = [self eventWithTouches:@[touch1, touch2]];
    [[UIApplication sharedApplication] sendEvent:event];
    
    [touch1 setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    [touch2 setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    
    [[UIApplication sharedApplication] sendEvent:event];
}

- (void)longPressInView:(UIView *)view atPoint:(CGPoint)point duration:(NSTimeInterval)duration {
    UITouch *touch = [[UITouch alloc] initAtPoint:point inView:view];
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    
    UIEvent *eventDown = [self eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventDown];
    
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, kFakeTouchDragDelay, false);
    
    for (NSTimeInterval timeSpent = kFakeTouchDragDelay; timeSpent < duration; timeSpent += kFakeTouchDragDelay) {
        [touch setPhaseAndUpdateTimestamp:UITouchPhaseStationary];
        
        UIEvent *eventStillDown = [self eventWithTouch:touch];
        [[UIApplication sharedApplication] sendEvent:eventStillDown];
        
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, kFakeTouchDragDelay, false);
    }
    
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    UIEvent *eventUp = [self eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventUp];
    
    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touch.view isDescendantOfView:view] && [view canBecomeFirstResponder]) {
        [view becomeFirstResponder];
    }
}

- (void)dragInView:(UIView *)view fromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint steps:(NSUInteger)stepCount {
    NSArray *path = [self pointsFromStartPoint:startPoint toPoint:endPoint steps:stepCount];
    [self dragPointsInView:view alongPaths:@[path]];
}

- (void)dragPointsInView:(UIView *)view alongPaths:(NSArray *)arrayOfPaths {
    // must have at least one path, and each path must have the same number of points
    if (arrayOfPaths.count == 0) {
        return;
    }
    
    // all paths must have similar number of points
    NSUInteger pointsInPath = [arrayOfPaths[0] count];
    for (NSArray *path in arrayOfPaths) {
        if (path.count != pointsInPath) {
            return;
        }
    }
    
    NSMutableArray *touches = [NSMutableArray array];
    
    // Convert paths to be in window coordinates before we start, because the view may
    // move relative to the window.
    NSMutableArray *newPaths = [[NSMutableArray alloc] init];
    
    for (NSArray * path in arrayOfPaths) {
        NSMutableArray *newPath = [[NSMutableArray alloc] init];
        for (NSValue *pointValue in path) {
            CGPoint point = [pointValue CGPointValue];
            [newPath addObject:[NSValue valueWithCGPoint:[view.window convertPoint:point fromView:view]]];
        }
        [newPaths addObject:newPath];
    }
    
    arrayOfPaths = newPaths;
    
    for (NSUInteger pointIndex = 0; pointIndex < pointsInPath; pointIndex++) {
        // create initial touch event and send touch down event
        if (pointIndex == 0) {
            for (NSArray *path in arrayOfPaths) {
                CGPoint point = [path[pointIndex] CGPointValue];
                // The starting point needs to be relative to the view receiving the UITouch event.
                point = [view convertPoint:point fromView:view.window];
                UITouch *touch = [[UITouch alloc] initAtPoint:point inView:view];
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
                [touches addObject:touch];
            }
            UIEvent *eventDown = [self eventWithTouches:[NSArray arrayWithArray:touches]];
            [[UIApplication sharedApplication] sendEvent:eventDown];
            
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, kFakeTouchDragDelay, false);
        } else {
            UITouch *touch;
            for (NSUInteger pathIndex = 0; pathIndex < arrayOfPaths.count; pathIndex++) {
                NSArray *path = arrayOfPaths[pathIndex];
                CGPoint point = [path[pointIndex] CGPointValue];
                touch = touches[pathIndex];
                [touch setLocationInWindow:point];
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseMoved];
            }
            UIEvent *event = [self eventWithTouches:[NSArray arrayWithArray:touches]];
            [[UIApplication sharedApplication] sendEvent:event];
            
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, kFakeTouchDragDelay, false);
            
            // The last point needs to also send a phase ended touch.
            if (pointIndex == pointsInPath - 1) {
                for (UITouch * touch in touches) {
                    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
                    UIEvent *eventUp = [self eventWithTouch:touch];
                    [[UIApplication sharedApplication] sendEvent:eventUp];
                }
            }
        }
    }
    
    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touches[0] view] == view && [view canBecomeFirstResponder]) {
        [view becomeFirstResponder];
    }
    
    while (CFRunLoopCopyCurrentMode(CFRunLoopGetCurrent()) != kCFRunLoopDefaultMode) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }
}

#pragma mark - Interface For Map

- (void)twoFingerPanInView:(UIView *)view fromPoint:(CGPoint)startPoint toPoint:(CGPoint)toPoint steps:(NSUInteger)stepCount {
    //estimate the first finger to be diagonally up and left from the center
    CGPoint finger1Start = CGPointMake(startPoint.x - kFakeTouchTwoFingerWidth,
                                       startPoint.y - kFakeTouchTwoFingerWidth);
    CGPoint finger1End = CGPointMake(toPoint.x - kFakeTouchTwoFingerWidth,
                                     toPoint.y - kFakeTouchTwoFingerWidth);
    //estimate the second finger to be diagonally down and right from the center
    CGPoint finger2Start = CGPointMake(startPoint.x + kFakeTouchTwoFingerWidth,
                                       startPoint.y + kFakeTouchTwoFingerWidth);
    CGPoint finger2End = CGPointMake(toPoint.x + kFakeTouchTwoFingerWidth,
                                     toPoint.y + kFakeTouchTwoFingerWidth);
    NSArray *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
    NSArray *paths = @[finger1Path, finger2Path];
    
    [self dragPointsInView:view alongPaths:paths];
}

- (void)pinchInView:(UIView *)view atPoint:(CGPoint)centerPoint distance:(CGFloat)distance steps:(NSUInteger)stepCount {
    //estimate the first finger to be on the left
    CGPoint finger1Start = CGPointMake(centerPoint.x - kFakeTouchTwoFingerWidth - distance, centerPoint.y);
    CGPoint finger1End = CGPointMake(centerPoint.x - kFakeTouchTwoFingerWidth, centerPoint.y);
    //estimate the second finger to be on the right
    CGPoint finger2Start = CGPointMake(centerPoint.x + kFakeTouchTwoFingerWidth + distance, centerPoint.y);
    CGPoint finger2End = CGPointMake(centerPoint.x + kFakeTouchTwoFingerWidth, centerPoint.y);
    NSArray *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
    NSArray *paths = @[finger1Path, finger2Path];
    
    [self dragPointsInView:view alongPaths:paths];
}

- (void)zoomInView:(UIView *)view atPoint:(CGPoint)centerPoint distance:(CGFloat)distance steps:(NSUInteger)stepCount {
    //estimate the first finger to be on the left
    CGPoint finger1Start = CGPointMake(centerPoint.x - kFakeTouchTwoFingerWidth, centerPoint.y);
    CGPoint finger1End = CGPointMake(centerPoint.x - kFakeTouchTwoFingerWidth - distance, centerPoint.y);
    //estimate the second finger to be on the right
    CGPoint finger2Start = CGPointMake(centerPoint.x + kFakeTouchTwoFingerWidth, centerPoint.y);
    CGPoint finger2End = CGPointMake(centerPoint.x + kFakeTouchTwoFingerWidth + distance, centerPoint.y);
    NSArray *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
    NSArray *paths = @[finger1Path, finger2Path];
    
    [self dragPointsInView:view alongPaths:paths];
}

- (void)twoFingerRotateInView:(UIView *)view atPoint:(CGPoint)centerPoint angle:(CGFloat)angleInDegrees {
    NSInteger stepCount = ABS(angleInDegrees)/2; // very rough approximation. 90deg = ~45 steps, 360 deg = ~180 steps
    CGFloat radius = kFakeTouchTwoFingerWidth*2;
    double angleInRadians = angleInDegrees / 180.0 * M_PI;
    
    NSMutableArray *finger1Path = [NSMutableArray array];
    NSMutableArray *finger2Path = [NSMutableArray array];
    for (NSUInteger i = 0; i < stepCount; i++) {
        double currentAngle = 0;
        if (i == stepCount - 1) {
            currentAngle = angleInRadians; // do not interpolate for the last step for maximum accuracy
        }
        else {
            double interpolation = i/(double)stepCount;
            currentAngle = interpolation * angleInRadians;
        }
        // interpolate betwen 0 and the target rotation
        CGPoint offset1 = CGPointMake(radius * cos(currentAngle), radius * sin(currentAngle));
        CGPoint offset2 = CGPointMake(-offset1.x, -offset1.y); // second finger is just opposite of the first
        
        CGPoint finger1 = CGPointMake(centerPoint.x + offset1.x, centerPoint.y + offset1.y);
        CGPoint finger2 = CGPointMake(centerPoint.x + offset2.x, centerPoint.y + offset2.y);
        
        [finger1Path addObject:[NSValue valueWithCGPoint:finger1]];
        [finger2Path addObject:[NSValue valueWithCGPoint:finger2]];
    }
    [self dragPointsInView:view alongPaths:@[[finger1Path copy], [finger2Path copy]]];
}

#pragma mark - Helper

- (UIWindow *)defaultTouchWindow {
    return [[UIApplication sharedApplication] keyWindow];
}

- (NSArray *)pointsFromStartPoint:(CGPoint)startPoint toPoint:(CGPoint)toPoint steps:(NSUInteger)stepCount {
    
    CGPoint displacement = CGPointMake(toPoint.x - startPoint.x, toPoint.y - startPoint.y);
    NSMutableArray *points = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < stepCount; i++) {
        CGFloat progress = ((CGFloat)i)/(stepCount - 1);
        CGPoint point = CGPointMake(startPoint.x + (progress * displacement.x),
                                    startPoint.y + (progress * displacement.y));
        [points addObject:[NSValue valueWithCGPoint:point]];
    }
    return [NSArray arrayWithArray:points];
}

- (UIEvent *)eventWithTouches:(NSArray *)touches {
    // _touchesEvent is a private selector, interface is exposed in UIApplication(KIFAdditionsPrivate)
    UIEvent *event = [[UIApplication sharedApplication] _touchesEvent];
    
    [event _clearTouches];
    [event kif_setEventWithTouches:touches];
    
    for (UITouch *aTouch in touches) {
        [event _addTouch:aTouch forDelayedDelivery:NO];
    }
    
    return event;
}

- (UIEvent *)eventWithTouch:(UITouch *)touch {
    NSArray *touches = touch ? @[touch] : nil;
    return [self eventWithTouches:touches];
}

@end
