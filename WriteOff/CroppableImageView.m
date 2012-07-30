//
//  CroppableImageView.m
//  WriteOff
//
//  Created by Mike Miller on 6/8/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "CroppableImageView.h"

#import "CroppableImage.h"

#import "ManagedCALayer.h"
#import "UIImage+normalize.h"

@implementation CroppableImageView

@synthesize tapRegionCornerRatio;
@synthesize marginRatio; //should cause redraw if changed
@synthesize maintainAspectRatio; //should cause redraw if changed


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
    
    UITapGestureRecognizer * tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    tapRec.numberOfTapsRequired = 2;
    tapRec.delegate = self;
    [self addGestureRecognizer:tapRec];
    
    UIPanGestureRecognizer * panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRec.delegate = self;
    [self addGestureRecognizer:panRec];
    
    self.tapRegionCornerRatio = 1/3.0;
    //CGRect rect = [self getImageBoundsWithMargin];
    //self.cropRect = CGRectMake(rect.origin.x + 10, rect.origin.y + 10, rect.size.width - 20, rect.size.height - 20);
    //self.cropRect = CGRectMake(10, 10, 50, 50);
    //_previouslyDrawnCropRect = CGRectMake(0, 0, 0, 0);
    _initialTapRegion = TapRegionNone;
    
    // Because we're setting clarsContextBeforeDrawing to false, we set backgroundColor to nil as recommended here: http://developer.apple.com/library/ios/#documentation/uikit/reference/uiview_class/uiview/uiview.html
    self.clearsContextBeforeDrawing = false;
    self.backgroundColor = nil;
    _twoFingersDown = false;
    
    self.marginRatio = 0.05;
    self.maintainAspectRatio = true;
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
    CGRect cropRect = [self getCropRectInScreenSpace];
    CGFloat horizontalMargin = self.tapRegionCornerRatio * cropRect.size.width;
    CGFloat verticalMargin = self.tapRegionCornerRatio * cropRect.size.height;
    CGFloat x = cropRect.origin.x + horizontalMargin;
    CGFloat y = cropRect.origin.y + verticalMargin;
    CGFloat width = cropRect.size.width - 2 * horizontalMargin;
    CGFloat height = cropRect.size.height - 2 * verticalMargin;
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
    
    CGContextSetStrokeColor(context, CGColorGetComponents([UIColor greenColor].CGColor));
    CGContextAddRect(context, [self getCropRectInScreenSpace]);
    CGContextStrokePath(context);
    /*
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
     */
    CGContextRestoreGState(context);
}

- (void)drawRectWithColor:(CGRect)rect theColor:(UIColor *)color {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetStrokeColor(context, CGColorGetComponents(color.CGColor));
    CGContextAddRect(context, rect);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

- (void)drawRects:(NSArray *)rects withColor:(UIColor *)color {
    for (int i = 0; i < rects.count; ++i) {
        CGRect rect = [[rects objectAtIndex:i] CGRectValue];
        [self drawRectWithColor:rect theColor:color];
    }
}

- (CGRect)getImageBoundsWithMargin {
    CGRect rect = self.bounds;
    if (self.marginRatio == 0) {
        return rect;
    }    
    
    rect.size.width = self.bounds.size.width * (1 - (self.marginRatio * 2));
    rect.size.height = self.bounds.size.height * (1 - (self.marginRatio * 2));
    
    if (self.maintainAspectRatio) {
        double selfAspectRatio = self.bounds.size.width / (double)self.bounds.size.height;
        double imageAspectRatio = self.croppableImage.originalImage.size.width / (double)self.croppableImage.originalImage.size.height;
        if (selfAspectRatio > imageAspectRatio) {
            // The image is wider than the view, so we shrink it so the specified margin appears at the top and bottom, with extra margin at the left and right
            rect.size.width = rect.size.height * imageAspectRatio;
        } else {
            // The image is taller than the view, so we shrink it so the specified margin appears at the left and right, with extra margin at the top and bottom
            rect.size.height = rect.size.width / imageAspectRatio;
        }
    }
    
    // We adjusted the rect's size, now center it
    rect.origin.x = (self.bounds.size.width - rect.size.width) / 2.0;
    rect.origin.y = (self.bounds.size.height - rect.size.height) / 2.0;
    
    return rect;
}

- (CGLayerRef)createCGLayerRectFromImage:(UIImage *)image {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect imageBounds = [self getImageBoundsWithMargin];
    CGLayerRef ret = CGLayerCreateWithContext(context, image.size, /*auxiliaryInfo*/ NULL);
    CGContextRef layerContext = CGLayerGetContext(ret);
    // We may not get a valid context if we're still initializing
    if (layerContext) {
        NSLog(@"Drawing!");
        
        // Account for the iPhone's flipping the y axis
        CGContextTranslateCTM(layerContext, 0, self.bounds.size.height);
        CGContextScaleCTM(layerContext, 1.0, -1.0);
        
        CGContextDrawImage(layerContext, imageBounds, image.CGImage);
        /*
        CGContextSetFillColorWithColor(layerContext, [UIColor blueColor].CGColor);
        CGContextFillRect(layerContext, CGRectMake(imageBounds.origin.x, imageBounds.origin.y, imageBounds.size.width / 2, imageBounds.size.height / 2));
        CGContextSetFillColorWithColor(layerContext, [UIColor redColor].CGColor);
        CGContextFillRect(layerContext, CGRectMake(imageBounds.origin.x + imageBounds.size.width / 2, imageBounds.origin.y + imageBounds.size.height / 2, imageBounds.size.width / 2, imageBounds.size.height / 2));
         */
        /*
         CGContextSetRGBFillColor(layerContext, 0, 0, 0, .75);
         CGContextFillRect(layerContext, CGRectMake(0, 0, self.image.size.width, self.image.size.height));
         */
    } else {
        NSLog(@"invalid layerContext");
    }
    return ret;
}

/*
- (NSArray *)getRectDifference:(CGRect)topRect butIncludeOnlyPartsOfThisRect:(CGRect)bottomRect {
    NSMutableArray *differenceRects = [[NSMutableArray alloc] init];
    
    //CGRect intersection = CGRectIntersection(topRect, bottomRect);
    // We want all the parts of bottomRect that aren't in intersection. This is up to 4 rects (if intersection is contained entirely within bottomRect)
    
    int bottomMinX = CGRectGetMinX(bottomRect);
    int bottomMaxX = CGRectGetMaxX(bottomRect);
    int bottomMinY = CGRectGetMinY(bottomRect);
    int bottomMaxY = CGRectGetMaxY(bottomRect);
    int topMinX = CGRectGetMinX(topRect);
    int topMaxX = CGRectGetMaxX(topRect);
    int topMinY = CGRectGetMinY(topRect);
    int topMaxY = CGRectGetMaxY(topRect);
    
    if (bottomMinX < topMinX) {
        [differenceRects addObject:[NSValue valueWithCGRect:CGRectMake(bottomMinX, bottomMinY, topMinX - bottomMinX, bottomRect.size.height)]];
    }
    if (bottomMaxX > topMaxX) {
        [differenceRects addObject:[NSValue valueWithCGRect:CGRectMake(topMaxX, bottomMinY, bottomMaxX - topMaxX, bottomRect.size.height)]];
    }
    if (bottomMinY < topMinY) {
        [differenceRects addObject:[NSValue valueWithCGRect:CGRectMake(bottomMinX, bottomMinY, bottomRect.size.width, topMinY - bottomMinY)]];
    }
    if (bottomMaxY > topMaxY) {
        [differenceRects addObject:[NSValue valueWithCGRect:CGRectMake(bottomMinX, topMaxY, bottomRect.size.width, bottomMaxY - topMaxY)]];
    }
    
    return differenceRects;
}
*/

- (void)drawRect:(CGRect)rect
{
    if (!self.croppableImage) {
        NSLog(@"Invalid image; unable to draw CroppableImageView");
        return; 
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    //CGContextClearRect(context, rect);
    
    /* This exhibits the weird even/odd context image described here: http://stackoverflow.com/questions/4771028/even-and-odd-buffers-in-uiview-drawrect
     CGRect r = CGRectMake(num * 50, 0, 50, 50);
     //CGContextSaveGState(context);
     CGContextClipToRect(context, r);
     CGContextSetRGBFillColor(context, 0, 1, 0, 1);
     CGContextFillRect(context, r);
     
     return;
     */
    
    //UIGraphicsBeginImageContextWithOptions;
    
    //bool forceFullRefresh = true;
    
    //CGRect imageRect = [self getImageBoundsWithMargin];
    
    if (!_backgroundLayer || !_backgroundLayerDark) {
        NSLog(@"Creating background layers");
        // Cache the images to a layer so we can draw them quickly
        _backgroundLayer = [self createCGLayerRectFromImage:self.croppableImage.originalImage];
        _backgroundLayerDark = [self createCGLayerRectFromImage:self.croppableImage.originalImage];
        
        CGContextRef darkLayerContext = CGLayerGetContext(_backgroundLayerDark);
        if (darkLayerContext) {
            CGContextSetRGBFillColor(darkLayerContext, 0, 0, 0, .75);
            CGContextFillRect(darkLayerContext, CGRectMake(0, 0, self.croppableImage.originalImage.size.width, self.croppableImage.originalImage.size.height));
            
            // We created the background images for the first time. Force a full refresh.
            //NSLog(@"Just created background layers, so forcing full refresh");
            //forceFullRefresh = true;
        }
    }
    
    if (_backgroundLayer && _backgroundLayerDark) {
        
        /*
         CGRect prevCropRect = _previouslyDrawnCropRect;        
         if (CGRectEqualToRect(prevCropRect, CGRectMake(0, 0, 0, 0))) {
         NSLog(@"No previous crop rect. Forcing full refresh.");
         forceFullRefresh = true;
         }
         
         NSArray *dirtyRectsNowOutOfCropRegion = [self getRectDifference:self.cropRect butIncludeOnlyPartsOfThisRect:prevCropRect];
         CGRect cStyleDirtyRectsNowOutOfCropRegion[dirtyRectsNowOutOfCropRegion.count];
         for (int i = 0; i < dirtyRectsNowOutOfCropRegion.count; ++i) {
         cStyleDirtyRectsNowOutOfCropRegion[i] = [[dirtyRectsNowOutOfCropRegion objectAtIndex:i] CGRectValue];
         }
         NSArray *dirtyRectsNowInCropRegion = [self getRectDifference:prevCropRect butIncludeOnlyPartsOfThisRect:self.cropRect];
         CGRect cStyleDirtyRectsNowInCropRegion[dirtyRectsNowInCropRegion.count];
         for (int i = 0; i < dirtyRectsNowInCropRegion.count; ++i) {
         cStyleDirtyRectsNowInCropRegion[i] = [[dirtyRectsNowInCropRegion objectAtIndex:i] CGRectValue];
         }
         
         
         if (forceFullRefresh || dirtyRectsNowOutOfCropRegion.count > 0) {
         CGContextSaveGState(context);
         if (!forceFullRefresh)
         CGContextClipToRects(context, cStyleDirtyRectsNowOutOfCropRegion, dirtyRectsNowOutOfCropRegion.count);
         */
        CGContextDrawLayerAtPoint(context, CGPointZero, _backgroundLayerDark);
        /*
         CGContextRestoreGState(context);
         }
         
         
         if (forceFullRefresh || dirtyRectsNowInCropRegion.count > 0) {
         CGContextSaveGState(context);
         if (forceFullRefresh) {
         CGContextClipToRect(context, self.cropRect);
         } else {
         CGContextClipToRects(context, cStyleDirtyRectsNowInCropRegion, dirtyRectsNowInCropRegion.count);
         }*/
        CGRect cropRectInScreenSpace = [self getCropRectInScreenSpace];
        //NSLog(@"drawing cropRectInScreenSpace: %@", NSStringFromCGRect(cropRectInScreenSpace));
        
        CGContextClipToRect(context, cropRectInScreenSpace);
        CGContextDrawLayerAtPoint(context, CGPointZero, _backgroundLayer);
        /*
         CGContextRestoreGState(context);
         }
         */
        
        //[self drawTapRegionLines];
        //[self drawRects:dirtyRectsNowOutOfCropRegion withColor:[UIColor blueColor]];
        //[self drawRects:dirtyRectsNowInCropRegion withColor:[UIColor redColor]];
        
        //_previouslyDrawnCropRect = self.cropRect;
    }
}

- (CroppableImage *)croppableImage {
    return _croppableImage;
}
- (void)setCroppableImage:theCroppableImage {
    _croppableImage = theCroppableImage;
    
    // Release the cached background layers so we recreate them when we draw
    if (_backgroundLayer) {
        CFRelease(_backgroundLayer);
        _backgroundLayer = nil;
    }
    if (_backgroundLayerDark) {
        CFRelease(_backgroundLayerDark);
        _backgroundLayerDark = nil;
    }
        
    // Reset the crop rect
 //   CGRect rect = [self getImageBoundsWithMargin];
 //   self.cropRect = CGRectMake(rect.origin.x + 10, rect.origin.y + 10, rect.size.width - 20, rect.size.height - 20);
    
    //[(ManagedCALayer*)self.layer setDisplayImage:_image];
    //self.layer.contents = _image;
    
    [self setNeedsDisplay];
}

/*
 
 - (CroppableImage *)getCroppedImage
 {
 CroppableImage *croppableImage = [CroppableImage croppableImageWithImage:_image];
 
 CGRect rect = self.cropRect;
 
 CGRect marginsRect = [self getImageBoundsWithMargin];
 double widthRatio = rect.size.width / marginsRect.size.width;
 double heightRatio = rect.size.height / marginsRect.size.height;
 double xRatio = (rect.origin.x - marginsRect.origin.x) / marginsRect.size.width;
 double yRatio = (rect.origin.y - marginsRect.origin.y) / marginsRect.size.height;
 
 CGRect cropRectInImageSpace = CGRectMake(xRatio * _image.size.width, yRatio * _image.size.height,
 widthRatio * _image.size.width, heightRatio * _image.size.height);
 
 // Account for the iPhone's flipping the y axis by "flipping" the rect (actually just shifting it along y)
 int newRectBottom = _image.size.height - cropRectInImageSpace.origin.y;
 cropRectInImageSpace.origin.y = newRectBottom - cropRectInImageSpace.size.height;
 
 croppableImage.cropRect = cropRectInImageSpace;
 
 return croppableImage;
}
 */


- (CGRect)getCGRectWithCorner:(CGPoint)firstCorner andOtherCorner:(CGPoint)secondCorner
{
    CGPoint topLeft = CGPointMake(MIN(firstCorner.x, secondCorner.x), MIN(firstCorner.y, secondCorner.y));
    CGPoint bottomRight = CGPointMake(MAX(firstCorner.x, secondCorner.x), MAX(firstCorner.y, secondCorner.y));
    return CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
}

- (CGPoint)screenPointToImageSpace:(CGPoint)screenSpacePoint
{
    CGRect fullImageRectOnScreen = [self getImageBoundsWithMargin];
    CGRect imageRect = CGRectMake(0, 0, self.croppableImage.originalImage.size.width, self.croppableImage.originalImage.size.height);
    
    double widthRatio = imageRect.size.width / fullImageRectOnScreen.size.width;
    double heightRatio = imageRect.size.height / fullImageRectOnScreen.size.height;
    
    double newX = (screenSpacePoint.x - fullImageRectOnScreen.origin.x) * widthRatio;
    double newY = (screenSpacePoint.y - fullImageRectOnScreen.origin.y) * heightRatio;
    
    return CGPointMake(newX, newY);
}
- (CGPoint)imagePointToScreenSpace:(CGPoint)imageSpacePoint
{
    CGRect fullImageRectOnScreen = [self getImageBoundsWithMargin];
    CGRect imageRect = CGRectMake(0, 0, self.croppableImage.originalImage.size.width, self.croppableImage.originalImage.size.height);
    
    double widthRatio = imageRect.size.width / fullImageRectOnScreen.size.width;
    double heightRatio = imageRect.size.height / fullImageRectOnScreen.size.height;
    
    double newX = (imageSpacePoint.x / widthRatio) + fullImageRectOnScreen.origin.x;
    double newY = (imageSpacePoint.y / heightRatio) + fullImageRectOnScreen.origin.y;
    
    return CGPointMake(newX, newY);
}
- (CGRect)screenRectToImageSpace:(CGRect)screenSpaceRect
{
    CGPoint topLeft = [self screenPointToImageSpace:screenSpaceRect.origin];
    CGPoint bottomRight = [self screenPointToImageSpace:CGPointMake(CGRectGetMaxX(screenSpaceRect), CGRectGetMaxY(screenSpaceRect))];
                          
    return [self getCGRectWithCorner:topLeft andOtherCorner:bottomRight];
}
- (CGRect)imageRectToScreenSpace:(CGRect)imageSpaceRect
{
    CGPoint topLeft = [self imagePointToScreenSpace:imageSpaceRect.origin];
    CGPoint bottomRight = [self imagePointToScreenSpace:CGPointMake(CGRectGetMaxX(imageSpaceRect), CGRectGetMaxY(imageSpaceRect))];
    
    return [self getCGRectWithCorner:topLeft andOtherCorner:bottomRight];
}

- (CGRect)getCropRectInScreenSpace {
    return [self imageRectToScreenSpace:self.croppableImage.cropRect];
}

- (void)setCropRectInScreenSpace:(CGRect)cropRectInScreenSpace
{
    //NSLog(@"new CropRect in screen space: %@", NSStringFromCGRect(cropRectInScreenSpace));
    CGRect imageSpaceRect = [self screenRectToImageSpace:cropRectInScreenSpace];
    //NSLog(@"new CropRect in image space : %@", NSStringFromCGRect(imageSpaceRect));
    self.croppableImage.cropRect = imageSpaceRect;
    [self setNeedsDisplay];
}


- (void)adjustCropRectToPointInScreenSpace:(CGPoint)point withOtherPointInScreenSpace:(CGPoint)otherPoint
{
    [self setCropRectInScreenSpace:[self getCGRectWithCorner:point andOtherCorner:otherPoint]];
}

- (void)adjustCropRectToPointInScreenSpace:(CGPoint)point withInitialTapRegion:(TapRegion)tapRegion
{
    CGPoint userPointInScreenSpace = point;
    CGPoint fixedPointInScreenSpace;
    
    CGRect initialCropRectInScreenSpace = [self getCropRectInScreenSpace];
    
    if (tapRegion & TapRegionMiddle) {
        fixedPointInScreenSpace = CGPointMake(userPointInScreenSpace.x + initialCropRectInScreenSpace.size.width, userPointInScreenSpace.y + initialCropRectInScreenSpace.size.height);
    } else {
        // Make fixedPoint be the corner opposite the corner the user tapped. If the user taped an edge, this will make fixedPoint be one of the corners not included in that edge. In this case, the logic below for choosing userPoint will pick the appropriate opposite corner.
        fixedPointInScreenSpace = CGPointMake(!(tapRegion & TapRegionRight) ? 
                                         CGRectGetMaxX(initialCropRectInScreenSpace) : CGRectGetMinX(initialCropRectInScreenSpace),
                                         !(tapRegion & TapRegionBottom) ? 
                                         CGRectGetMaxY(initialCropRectInScreenSpace) : CGRectGetMinY(initialCropRectInScreenSpace));
        
        // Only adjust userPoint if the user selected an edge
        if (tapRegion == TapRegionLeft ||
            tapRegion == TapRegionRight) {
            
            userPointInScreenSpace.y = CGRectGetMinY(initialCropRectInScreenSpace);
        }
        else if (tapRegion == TapRegionTop ||
                 tapRegion == TapRegionBottom) {
            
            userPointInScreenSpace.x = CGRectGetMinX(initialCropRectInScreenSpace);        
        }
    }

    [self adjustCropRectToPointInScreenSpace:fixedPointInScreenSpace withOtherPointInScreenSpace:userPointInScreenSpace];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
{
    return YES;
}

- (void)setInitialTapRegionAndCrop:(CGPoint)location {
    _initialTapRegion = [self getTapRegionForPoint:location];
    //NSLog(@"touchesBegan at: %@, %@", NSStringFromCGPoint(location), [CroppableImageView tapRegionToString:_initialTapRegion]);
    
    // Don't modify anything if we're beginning a pan
    if (_initialTapRegion & TapRegionMiddle) {
        NSLog(@"Tapped middle");
        // If we're panning, we allow the cropRect to go out of bounds so it doesn't get clipped if we drag it off the screen. Note that we also don't adjust the cropRect here; beginning a pan should have no effect on cropRect.
        self.croppableImage.allowCropRectOutOfBounds = true;
    } else {
        [self adjustCropRectToPointInScreenSpace:location withInitialTapRegion:_initialTapRegion];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    NSLog(@"touchesBegan");
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    
    if (!CGRectContainsPoint([self getImageBoundsWithMargin], location)) {
        return;
    }
    
    [self setInitialTapRegionAndCrop:location];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer { 
    NSLog(@"Double Tap");
    //self.image = [self getCroppedImage];
    [self setCropRectInScreenSpace:[self getImageBoundsWithMargin]];
    _initialTapRegion = TapRegionNone;
    //[self setCropRect:CGRectMake(self.cropRect.origin.x, self.cropRect.origin.y, self.cropRect.size.width + 5, self.cropRect.size.height + 5)];
    
    //CGPoint tapLoc = [recognizer locationInView:self];
    //recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x, 
    //                                     recognizer.view.center.y + translation.y);
    //TapRegion tapRegion = [self getTapRegionForPoint:tapLoc];
    //NSLog(@"Tap! %@ (%@)", NSStringFromCGPoint(tapLoc), [CroppableImageView tapRegionToString:tapRegion]);
    
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateCancelled ||
        recognizer.state == UIGestureRecognizerStateEnded) {
        
        NSLog(@"Pan gesture ended!");
        _initialTapRegion = TapRegionNone;
        self.croppableImage.allowCropRectOutOfBounds = false;
        return;
    }
    
    // Actually, maybe a second touch when the first touch is middle should cause a scale of cropRect
    bool hasSecondTouch = recognizer.numberOfTouches > 1 && !(_initialTapRegion & TapRegionMiddle);
    CGPoint firstTouch = [recognizer locationOfTouch:0 inView:self];
    CGPoint secondTouch = hasSecondTouch ? [recognizer locationOfTouch:1 inView:self] : CGPointMake(-1, -1);
    
    if (_initialTapRegion == TapRegionNone) {
        // Check to see if we just moved into the image bounds and set _initialTapRegion accordingly
        if (CGRectContainsPoint([self getImageBoundsWithMargin], firstTouch)) {
            NSLog(@"Moved into image region. Setting initial tap region");
            [self setInitialTapRegionAndCrop:firstTouch];
        } else if (hasSecondTouch && CGRectContainsPoint([self getImageBoundsWithMargin], secondTouch)){
            NSLog(@"Second touch moved into image region. Setting initial tap region");
            [self setInitialTapRegionAndCrop:secondTouch];
        } else {
            NSLog(@"Dragging out of bounds. Ignoring.");
            return;
        }
    }
    
    CGRect cropRectInScreenSpace = [self getCropRectInScreenSpace];
    
    if (_twoFingersDown && recognizer.numberOfTouches == 1) {
        // The user just picked up their second-to-last finger leaving only one finger on the view. Make sure _initialTapRegion is set to the corner that the remaining finger is currently controlling (which may not be at what _initialTapRegion was set to when that finger was placed, e.g. if the user first tapped an edge).
        _initialTapRegion = TapRegionNone;
        // Set the tap region to the corner of the rect that the remaining finger is closest to
        if (ABS(firstTouch.x - CGRectGetMinX(cropRectInScreenSpace)) <
            ABS(firstTouch.x - CGRectGetMaxX(cropRectInScreenSpace))) {
            
            _initialTapRegion |= TapRegionLeft;
        } else {
            _initialTapRegion |= TapRegionRight;
        }
        if (ABS(firstTouch.y - CGRectGetMinY(cropRectInScreenSpace)) <
            ABS(firstTouch.y - CGRectGetMaxY(cropRectInScreenSpace))) {
            
            _initialTapRegion |= TapRegionTop;
        } else {
            _initialTapRegion |= TapRegionBottom;
        }
                
                
                
    }
    
    _twoFingersDown = hasSecondTouch;
    
    //NSLog(@"Pan with %i touches: %@ and %@", recognizer.numberOfTouches, NSStringFromCGPoint(firstTouch), NSStringFromCGPoint(secondTouch));

    
    
    //NSLog(@"Panned to %@", NSStringFromCGPoint(location));
    //NSLog(@"    delta %@", NSStringFromCGPoint(translation));
    
    // Adjust the initialTapRegion to compensate for the user crossing the boundaries of cropRect (e.g. if they drag the left side of cropRect past the right side, we switch initialTapRegion to have the user start dragging the right side
    
    CGPoint adjustedPoint = CGPointMake(firstTouch.x, firstTouch.y);
    TapRegion newTapRegion = _initialTapRegion;
    
    if (_initialTapRegion & TapRegionLeft && firstTouch.x > CGRectGetMaxX(cropRectInScreenSpace)) {
        NSLog(@"Went too far right. Adjusting tap region.");
        // When switching the side the user is dragging, we first adjust the side we're dragging so that when we switch to dragging the other side, we leave the previous side at the position the new side started at.
        adjustedPoint.x = CGRectGetMaxX(cropRectInScreenSpace);
        newTapRegion ^= TapRegionLeft;
        newTapRegion |= TapRegionRight;
    }
    if (_initialTapRegion & TapRegionRight && firstTouch.x < CGRectGetMinX(cropRectInScreenSpace)) {
        NSLog(@"Went too far left. Adjusting tap region.");
        adjustedPoint.x = CGRectGetMinX(cropRectInScreenSpace);
        newTapRegion ^= TapRegionRight;
        newTapRegion |= TapRegionLeft;
    }
    if (_initialTapRegion & TapRegionTop && firstTouch.y > CGRectGetMaxY(cropRectInScreenSpace)) {
        NSLog(@"Went too far down. Adjusting tap region.");
        adjustedPoint.y = CGRectGetMaxY(cropRectInScreenSpace);
        newTapRegion ^= TapRegionTop;
        newTapRegion |= TapRegionBottom;
    }
    if (_initialTapRegion & TapRegionBottom && firstTouch.y < CGRectGetMinY(cropRectInScreenSpace)) {
        NSLog(@"Went too far up. Adjusting tap region.");
        adjustedPoint.y = CGRectGetMinY(cropRectInScreenSpace);
        newTapRegion ^= TapRegionBottom;
        newTapRegion |= TapRegionTop;
    }
    
    // If we realized above that we had to adjust, do the adjustment now
    if (!CGPointEqualToPoint(adjustedPoint, firstTouch)) {
        NSLog(@"Adjusting!");
        [self adjustCropRectToPointInScreenSpace:adjustedPoint withInitialTapRegion:_initialTapRegion];
    }
    
    _initialTapRegion = newTapRegion;
     
    
    // If we're panning cropRect, find the new origin based on the change in location from the last time we were here
    if (_initialTapRegion & TapRegionMiddle) {
        CGPoint translation = [recognizer translationInView:self];
        firstTouch = CGPointMake(cropRectInScreenSpace.origin.x + translation.x, cropRectInScreenSpace.origin.y + translation.y);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self];
    }
    
    
    if (hasSecondTouch) {
        [self adjustCropRectToPointInScreenSpace:firstTouch withOtherPointInScreenSpace:secondTouch];
    } else {
        [self adjustCropRectToPointInScreenSpace:firstTouch withInitialTapRegion:_initialTapRegion];
    }
}



-(void)dealloc {
    if (_backgroundLayer)
        CFRelease(_backgroundLayer);
    if (_backgroundLayerDark)
        CFRelease(_backgroundLayerDark);
}


@end
