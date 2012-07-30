//
//  CroppableImage.m
//  WriteOff
//
//  Created by Mike Miller on 7/7/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "CroppableImage.h"
#import "UIImage+normalize.h"

@implementation CroppableImage


- (id)initWithImage:(UIImage *)image {
    if (self = [super init])
    {
        _originalImage = image;
        _croppedImage = image;
        _croppedImageIsValid = true;
        _cropRect = CGRectMake(0, 0, image.size.width, image.size.height);
        _allowCropRectOutOfBounds = false;
    }
    return self;
}

+ (CroppableImage *)croppableImageWithImage:(UIImage *)image {
    return [[CroppableImage alloc] initWithImage:image];
}


- (UIImage *)originalImage {
    return _originalImage;
}
- (void)setOriginalImage:(UIImage *)originalImage {
    if (_originalImage != originalImage) {
        _originalImage = originalImage;
        _croppedImageIsValid = false;
    }
}
- (CGRect)cropRect {
    return _cropRect;
}
- (void)setCropRect:(CGRect)theCropRect {
    
    
    CGRect imageBounds = CGRectMake(0, 0, self.originalImage.size.width, self.originalImage.size.height);
    // If specified, don't allow setting cropRect larger than the image
    CGRect adjustedRect = _allowCropRectOutOfBounds ? theCropRect : CGRectIntersection(theCropRect, imageBounds);
    
    if (!CGRectEqualToRect(_cropRect, adjustedRect)) {
        
        //NSLog(@"Changing cropRect from %@", NSStringFromCGRect(_cropRect));
        //NSLog(@"                    to %@", NSStringFromCGRect(adjustedRect));
        _cropRect = adjustedRect;
        _croppedImageIsValid = false;
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

- (UIImage *)croppedImage {
    if (_croppedImageIsValid) {
        return _croppedImage;
    }
    
    if (CGRectEqualToRect(_cropRect, CGRectMake(0, 0, _originalImage.size.width, _originalImage.size.height))) {
        _croppedImage = _originalImage; //should this make a copy instead?
        _croppedImageIsValid = true;
        return _croppedImage;
    }
    
    // Do the cropping
    CGRect cropRect = _cropRect;
    // Account for the iPhone's flipping the y axis by "flipping" the rect (actually just shifting it along y)
    int newRectBottom = _originalImage.size.height - cropRect.origin.y;
    cropRect.origin.y = newRectBottom - cropRect.size.height;
    

    
    //create a context to do our clipping in
    UIGraphicsBeginImageContext(cropRect.size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    //create a rect with the size we want to crop the image to
    //the X and Y here are zero so we start at the beginning of our
    //newly created context
    CGRect clippedRect = CGRectMake(0, 0, cropRect.size.width, cropRect.size.height);
    CGContextClipToRect( currentContext, clippedRect);
    
    //create a rect equivalent to the full size of the image
    //offset the rect by the X and Y we want to start the crop
    //from in order to cut off anything before them
    CGRect drawRect = CGRectMake(cropRect.origin.x * -1,
                                 cropRect.origin.y * -1,
                                 _originalImage.size.width,
                                 _originalImage.size.height);
    
    //draw the image to our clipped context using our offset rect
    CGContextDrawImage(currentContext, drawRect, _originalImage.CGImage);
    
    //pull the image from our cropped context
    UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    //Note: this is autoreleased
    //return cropped;
    _croppedImage = [cropped flippedVertically];
    
    _croppedImageIsValid = true;
    return _croppedImage;
}


@end
