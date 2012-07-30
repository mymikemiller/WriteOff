//
//  CroppableImageView.h
//  WriteOff
//
//  Created by Mike Miller on 6/8/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

@class CroppableImage;
#import <UIKit/UIKit.h>


typedef enum {
    TapRegionNone         = 0,
    TapRegionMiddle       = 1 << 0, // This should never be |'d with anything
    TapRegionTop          = 1 << 1,
    TapRegionBottom       = 1 << 2,
    TapRegionLeft         = 1 << 3,
    TapRegionRight        = 1 << 4
} TapRegion;

@interface CroppableImageView : UIView <UIGestureRecognizerDelegate> {
    CroppableImage *_croppableImage;
    //CGRect _previouslyDrawnCropRect;
    CGLayerRef _backgroundLayerDark;
    CGLayerRef _backgroundLayer;
    TapRegion _initialTapRegion;
    bool _twoFingersDown;
}
    
@property (nonatomic, strong) CroppableImage *croppableImage;
// The margin to display around the edge of the image expressed as a ratio (0 to 0.5) of the width and height of the image
@property (nonatomic) double marginRatio;
@property (nonatomic) bool maintainAspectRatio;

// The view is split into 9 regions like a tic-tac-toe board. Where the user first puts their finger down determines which sides of cropRect will be modified; placing the finger in the top-left region modifies both the top and left side, as though the user is dragging the corner. Placing the finger in the middle-left region causes only the left side to be modified, and so on for the other 8 regions around the outside. Placing the finger in the middle region causes cropRect to pan around without changing size. This value specifies where these imaginary lines are drawn in relation to the current cropRect. All 4 lines always pass through the inside of cropRect, no matter where cropRect is within the view. The value must be between 0 and 0.5; for the {vertical, horizontal} lines it specifies how far into cropRect the lines should be, as a ratio of cropRect's {width, height}. So essentialy the higher the value, the easier it is to grab corners and the harder it is to grab edges and pan.
@property (nonatomic) float tapRegionCornerRatio;

- (CGRect)getImageBoundsWithMargin;

- (CGPoint)screenPointToImageSpace:(CGPoint)screenSpacePoint;
- (CGPoint)imagePointToScreenSpace:(CGPoint)imageSpacePoint;
- (CGRect)screenRectToImageSpace:(CGRect)screenSpaceRect;
- (CGRect)imageRectToScreenSpace:(CGRect)imageSpaceRect;

- (CGRect)getCropRectInScreenSpace;
- (void)setCropRectInScreenSpace:(CGRect)cropRectInScreenSpace;

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer;
- (void)handlePan:(UIPanGestureRecognizer *)recognizer;
//- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer;



@end
