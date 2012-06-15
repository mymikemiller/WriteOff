//
//  CroppableImageView.m
//  WriteOff
//
//  Created by Mike Miller on 6/8/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "CroppableImageView.h"

@implementation CroppableImageView

@synthesize tapRegionCornerRatio;


+ (NSString*)tapRegionToString:(TapRegion)tapRegion {
    if (tapRegion == TapRegionNone)
        return @"TapRegionNone";
    if (tapRegion == TapRegionMiddle)
        return @"TapRegionMiddle";
    
    NSString *result = @"TapRegion";
    if (tapRegion & TapRegionTop)
        result = [result stringByAppendingString:@"Top"];
    else if (tapRegion & TapRegionBottom)
        result = [result stringByAppendingString:@"Bottom"];
    
    if (tapRegion & TapRegionLeft)
        result = [result stringByAppendingString:@"Left"];
    else if (tapRegion & TapRegionRight)
        result = [result stringByAppendingString:@"Right"];
    
    return result;
}


-(void) doInitialization {
    NSLog(@"Adding GestureRecognizers");
    [self setUserInteractionEnabled:YES];
    
    UITapGestureRecognizer * tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRec.delegate = self;
    [self addGestureRecognizer:tapRec];
    
    UIPanGestureRecognizer * panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRec.delegate = self;
    [self addGestureRecognizer:panRec];
    
    UIPinchGestureRecognizer * pinchRec = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    pinchRec.delegate = self;
    [self addGestureRecognizer:pinchRec];
    
    self.tapRegionCornerRatio = 1/3.0;
    self.cropRect = CGRectMake(50, 50, self.bounds.size.width - 100, self.bounds.size.height - 100);
    self.allowCropRectOutOfBounds = false;
    _initialTapRegion = TapRegionNone;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder])
    {
        [self doInitialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) 
    {
        [self doInitialization];
    }
    return self;
}

- (CGRect)getTapRegionCenter
{
    CGFloat horizontalMargin = self.tapRegionCornerRatio * self.cropRect.size.width;
    CGFloat verticalMargin = self.tapRegionCornerRatio * self.cropRect.size.height;
    CGFloat x = self.cropRect.origin.x + horizontalMargin;
    CGFloat y = self.cropRect.origin.y + verticalMargin;
    CGFloat width = self.cropRect.size.width - 2 * horizontalMargin;
    CGFloat height = self.cropRect.size.height - 2 * verticalMargin;
    return CGRectMake(x, y, width, height);
}

- (TapRegion)getTapRegionForPoint:(CGPoint)point
{
    CGRect tapRegionCenter = [self getTapRegionCenter];
    
    TapRegion result = TapRegionNone;
    
    if (point.x < CGRectGetMinX(tapRegionCenter))
        result |= TapRegionLeft;
    if (point.x > CGRectGetMaxX(tapRegionCenter))
        result |= TapRegionRight;
    if (point.y < CGRectGetMinY(tapRegionCenter))
        result |= TapRegionTop;
    if (point.y > CGRectGetMaxY(tapRegionCenter))
        result |= TapRegionBottom;
    
    // If we're not to the right, left, top or bottom of the center region, we must be inside it!
    if (result == TapRegionNone)
        result = TapRegionMiddle;
    
    return result;
}

- (void)drawTapRegionLines
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetStrokeColor(context, CGColorGetComponents([UIColor blueColor].CGColor));
    CGContextAddRect(context, self.cropRect);
    CGContextStrokePath(context);
    
    CGRect tapRegionCenter = [self getTapRegionCenter];
    CGContextSetStrokeColor(context, CGColorGetComponents([UIColor redColor].CGColor));
    
    CGFloat leftVertical = CGRectGetMinX(tapRegionCenter);
    CGFloat rightVertical = CGRectGetMaxX(tapRegionCenter);
    CGFloat topHorizontal = CGRectGetMinY(tapRegionCenter);
    CGFloat bottomHorizontal = CGRectGetMaxY(tapRegionCenter);
    
    CGContextMoveToPoint(context, leftVertical, 0);
    CGContextAddLineToPoint(context, leftVertical, self.bounds.size.height);
    CGContextMoveToPoint(context, rightVertical, 0);
    CGContextAddLineToPoint(context, rightVertical, self.bounds.size.height);
    CGContextMoveToPoint(context, 0, topHorizontal);
    CGContextAddLineToPoint(context, self.bounds.size.width, topHorizontal);
    CGContextMoveToPoint(context, 0, bottomHorizontal);
    CGContextAddLineToPoint(context, self.bounds.size.width, bottomHorizontal);
    
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}


- (void)drawRect:(CGRect)rect
{
    //NSLog(@"drawRect!");
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!_backgroundLayer) {
        NSLog(@"Creating background layer");
        // Cache the image to a layer so we can draw it quickly
        
        _backgroundLayer = CGLayerCreateWithContext(context, self.image.size, /*auxiliaryInfo*/ NULL);
        
        CGContextRef layerContext = CGLayerGetContext(_backgroundLayer);
        // We may not get a valid context if we're still initializing
        if (layerContext) {
            CGContextDrawImage(layerContext, (CGRect){ CGPointZero, self.image.size }, self.image.CGImage);
        } else {
            NSLog(@"invalid layerContext");
        }
    }
    if (_backgroundLayer)
        CGContextDrawLayerInRect(context, rect, _backgroundLayer);
    
    //CGContextDrawImage(context, rect, self.image.CGImage);
    //[self.image drawInRect:rect];
    
    CGContextSetFillColor(context, CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:.75].CGColor));
    
    CGRect leftRect = CGRectMake(0, 0, self.cropRect.origin.x, self.bounds.size.height);
    CGRect rightRect = CGRectMake(self.cropRect.origin.x + self.cropRect.size.width, 0, self.bounds.size.width - (self.cropRect.origin.x + self.cropRect.size.width), self.bounds.size.height);
    
    CGRect topRect = CGRectMake(leftRect.size.width, 0, self.bounds.size.width - leftRect.size.width - rightRect.size.width, self.cropRect.origin.y);
    CGRect bottomRect = CGRectMake(leftRect.size.width, self.cropRect.origin.y + self.cropRect.size.height, topRect.size.width, self.bounds.size.height - self.cropRect.origin.y - self.cropRect.size.height);
    
    CGContextFillRect(context, leftRect);
    CGContextFillRect(context, rightRect);
    CGContextFillRect(context, topRect);
    CGContextFillRect(context, bottomRect);

    //[self drawTapRegionLines];
}

- (UIImage *)image {
    return _image;
}
- (void)setImage:(UIImage *)theImage {
    _image = theImage;
    
    // Release the cached background layer so we recreate it when we draw
    if (_backgroundLayer)
        CFRelease(_backgroundLayer);
    
    [self setNeedsDisplay];
}
- (CGRect)cropRect {
    return _cropRect;
}
- (void)setCropRect:(CGRect)theCropRect {
    // Don't allow setting cropRect larger than the view
    CGRect adjustedRect = _allowCropRectOutOfBounds ? theCropRect : CGRectIntersection(theCropRect, self.bounds);
    if (!CGRectEqualToRect(adjustedRect, _cropRect)) {
        //NSLog(@"Changing cropRect from %@", NSStringFromCGRect(_cropRect));
        //NSLog(@"                    to %@", NSStringFromCGRect(theCropRect));
        _cropRect = adjustedRect;
        [self setNeedsDisplay];
    }
}

- (bool)allowCropRectOutOfBounds {
    return _allowCropRectOutOfBounds;
}

- (void)setAllowCropRectOutOfBounds:(bool)allowCropRectOutOfBounds{
    _allowCropRectOutOfBounds = allowCropRectOutOfBounds;
    // cropRect may need cropping if we switched to not allowing cropRect out of bounds
    [self setCropRect:self.cropRect];
}


- (void)adjustCropRectToPoint:(CGPoint)point withInitialTapRegion:(TapRegion)tapRegion
{
    CGRect newCropRect = self.cropRect;
    
    /*NSLog(@"Before adjust: %@", NSStringFromCGRect(newCropRect));
    
    if (tapRegion & TapRegionLeft)
        NSLog(@"Adjusting Left");
    if (tapRegion & TapRegionTop)
        NSLog(@"Adjusting Top");
    if (tapRegion & TapRegionRight)
        NSLog(@"Adjusting Right");
    if (tapRegion & TapRegionBottom)
        NSLog(@"Adjusting Bottom");
    */
    if (tapRegion & TapRegionLeft) {
        CGFloat oldRightEdge = CGRectGetMaxX(newCropRect);
        newCropRect.origin.x = point.x;
        newCropRect.size.width += oldRightEdge - CGRectGetMaxX(newCropRect);
    }
    if (tapRegion & TapRegionTop) {
        CGFloat oldBottomEdge = CGRectGetMaxY(newCropRect);
        newCropRect.origin.y = point.y;
        newCropRect.size.height += oldBottomEdge - CGRectGetMaxY(newCropRect);
    }
    if (tapRegion & TapRegionBottom)
        newCropRect.size.height = point.y - newCropRect.origin.y;
    if (tapRegion & TapRegionRight)
        newCropRect.size.width = point.x - newCropRect.origin.x;
    if (tapRegion & TapRegionMiddle) {
        newCropRect.origin = point;
    }
    
    
    NSLog(@"After adjust: %@", NSStringFromCGRect(newCropRect));
    self.cropRect = newCropRect;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
{
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    _initialTapRegion = [self getTapRegionForPoint:location];
    NSLog(@"touchesBegan at: %@, %@", NSStringFromCGPoint(location), [CroppableImageView tapRegionToString:_initialTapRegion]);
    
    // Don't modify anything if we're beginning a pan
    if (_initialTapRegion & TapRegionMiddle) {
        // If we're panning, we allow the cropRect to go out of bounds so it doesn't get clipped if we drag it off the screen. Note that we also don't adjust the cropRect here; beginning a pan should have no effect on cropRect.
        self.allowCropRectOutOfBounds = true;
    } else {
        [self adjustCropRectToPoint:location withInitialTapRegion:_initialTapRegion];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer { 
    
    CGPoint tapLoc = [recognizer locationInView:self];
    //recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x, 
    //                                     recognizer.view.center.y + translation.y);
    TapRegion tapRegion = [self getTapRegionForPoint:tapLoc];
    NSLog(@"Tap! %@ (%@)", NSStringFromCGPoint(tapLoc), [CroppableImageView tapRegionToString:tapRegion]);
     
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    NSLog(@"handlePinch");
    //recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    //recognizer.scale = 1;    
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateCancelled ||
        recognizer.state == UIGestureRecognizerStateEnded) {
        
        NSLog(@"Pan gesture ended!");
        _initialTapRegion = TapRegionNone;
        self.allowCropRectOutOfBounds = false;
        return;
    }
    
    
    CGPoint location = [recognizer locationInView:self];
    
    //NSLog(@"Panned to %@", NSStringFromCGPoint(location));
    //NSLog(@"    delta %@", NSStringFromCGPoint(translation));
    
    // Adjust the initialTapRegion to compensate for the user crossing the boundaries of cropRect (e.g. if they drag the left side of cropRect past the right side, we switch initialTapRegion to have the user start dragging the right side
    CGPoint adjustedPoint = CGPointMake(location.x, location.y);
    TapRegion newTapRegion = _initialTapRegion;
    if (_initialTapRegion & TapRegionLeft && location.x > CGRectGetMaxX(self.cropRect)) {
        NSLog(@"Went too far right. Adjusting tap region.");
        // When switching the side the user is dragging, we first adjust the side we're dragging so that when we switch to dragging the other side, we leave the previous side at the position the new side started at.
        adjustedPoint.x = CGRectGetMaxX(self.cropRect);
        newTapRegion ^= TapRegionLeft;
        newTapRegion |= TapRegionRight;
    }
    if (_initialTapRegion & TapRegionRight && location.x < CGRectGetMinX(self.cropRect)) {
        NSLog(@"Went too far left. Adjusting tap region.");
        adjustedPoint.x = CGRectGetMinX(self.cropRect);
        newTapRegion ^= TapRegionRight;
        newTapRegion |= TapRegionLeft;
    }
    if (_initialTapRegion & TapRegionTop && location.y > CGRectGetMaxY(self.cropRect)) {
        NSLog(@"Went too far down. Adjusting tap region.");
        adjustedPoint.y = CGRectGetMaxY(self.cropRect);
        newTapRegion ^= TapRegionTop;
        newTapRegion |= TapRegionBottom;
    }
    if (_initialTapRegion & TapRegionBottom && location.y < CGRectGetMinY(self.cropRect)) {
        NSLog(@"Went too far up. Adjusting tap region.");
        adjustedPoint.y = CGRectGetMinY(self.cropRect);
        newTapRegion ^= TapRegionBottom;
        newTapRegion |= TapRegionTop;
    }
    
    // If we realized above that we had to adjust, do the adjustment now
    if (!CGPointEqualToPoint(adjustedPoint, location)) {
        NSLog(@"Adjusting!");
        [self adjustCropRectToPoint:adjustedPoint withInitialTapRegion:_initialTapRegion];
    }
    
    _initialTapRegion = newTapRegion;
    
    // If we're panning cropRect, find the new origin based on the change in location from the last time we were here
    if (_initialTapRegion & TapRegionMiddle) {
        CGPoint translation = [recognizer translationInView:self];
        location = CGPointMake(self.cropRect.origin.x + translation.x, self.cropRect.origin.y + translation.y);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self];
    }
    
    
    [self adjustCropRectToPoint:location withInitialTapRegion:_initialTapRegion];
    //[recognizer setTranslation:CGPointMake(0, 0) inView:self];
}

-(void)dealloc {
    CFRelease(_backgroundLayer);
}


@end
