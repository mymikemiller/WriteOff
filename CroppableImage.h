//
//  CroppedImage.h
//  WriteOff
//
//  Created by Mike Miller on 7/7/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CroppableImage : NSObject
{
    UIImage *_originalImage;
    UIImage *_croppedImage;
    bool _croppedImageIsValid;
    CGRect _cropRect;
    bool _allowCropRectOutOfBounds;
}

+ (CroppableImage *)croppableImageWithImage:(UIImage *)image;

@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, readonly) UIImage *croppedImage;
@property (nonatomic) CGRect cropRect;
@property (nonatomic) bool allowCropRectOutOfBounds;

@end
