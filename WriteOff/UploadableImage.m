//
//  UploadableImage.m
//  WriteOff
//
//  Created by Mike Miller on 6/29/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "UploadableImage.h"
#import "CroppableImage.h"


@implementation UploadableImage {
    // We re-declare this as an NSMutableArray here so we can manipulate it within this class. External classes see the immutable NSArray declared in the header.
    NSMutableArray *_croppableImages;
    ImageMergeStyle _imageMergeStyle;
}

@synthesize croppableImages = _croppableImages;

@synthesize columnIndexForName;
@synthesize name;
@synthesize url;
@synthesize spreadsheetManager;

- (void)initialize {
    _croppableImages = [[NSMutableArray alloc] init];
    columnIndexForName = 1;
    name = @"Image";
    _finalImageIsValid = false;
    _imageMergeStyle = ImageMergeStyleLeftToRight;
}

- (id)initWithSpreadsheetManager:(SpreadsheetManager *)theSpreadsheetManager {
    if (self = [super init])
    {
        [self initialize];
        self.spreadsheetManager = theSpreadsheetManager;
    }
    return self;
}

- (id)initWithCroppableImage:(CroppableImage *)croppableImage
       andSpreadsheetManager:(SpreadsheetManager *)theSpreadsheetManager {
    if (self = [super init])
    {
        [self initialize];
        [_croppableImages addObject:croppableImage];
        self.spreadsheetManager = theSpreadsheetManager;
    }
    return self;
}

+ (UploadableImage *)uploadableImageWithCroppableImage:(CroppableImage *)croppableImage
                                 andSpreadsheetManager:(SpreadsheetManager *)spreadsheetManager {
    return [[UploadableImage alloc] initWithCroppableImage:croppableImage
                                     andSpreadsheetManager:spreadsheetManager];
}

- (void)setImageMergeStyle:(ImageMergeStyle)imageMergeStyle {
    if (_imageMergeStyle != imageMergeStyle) {
        _imageMergeStyle = imageMergeStyle;
        _finalImageIsValid = false;
    }
}
- (ImageMergeStyle)imageMergeStyle {
    return _imageMergeStyle;
}

- (NSString *)getFinalName{
    if (self.columnIndexForName >= 0){
        if (self.spreadsheetManager.headerToValueMap.count > self.columnIndexForName) {            NSString *theName = [[self.spreadsheetManager.headerToValueMap objectAtIndex:self.columnIndexForName] objectAtIndex:1];
            if (theName.length > 0) {
                return theName;
            }
        }
    }
    return self.name;
}

- (UIImage *)finalImage {
    if (_finalImageIsValid) {
        return _finalImage;
    }
    
    CGSize finalImageSize = CGSizeZero;
    for (CroppableImage *croppableImage in _croppableImages) {
        if (_imageMergeStyle == ImageMergeStyleLeftToRight) {
            finalImageSize.width += croppableImage.croppedImage.size.width;
            finalImageSize.height = MAX(finalImageSize.height, croppableImage.originalImage.size.height);
        } else {
            finalImageSize.width = MAX(finalImageSize.width, croppableImage.originalImage.size.width);
            finalImageSize.height += croppableImage.croppedImage.size.height;
        }
    }
    
    UIGraphicsBeginImageContext(finalImageSize);
    
    CGPoint currentImagePosition = CGPointZero;
    for (CroppableImage *croppableImage in _croppableImages) {
        [croppableImage.croppedImage drawInRect:CGRectMake(currentImagePosition.x, currentImagePosition.y, croppableImage.croppedImage.size.width, croppableImage.croppedImage.size.height)];
        if (_imageMergeStyle == ImageMergeStyleLeftToRight) {
            currentImagePosition.x += croppableImage.croppedImage.size.width;
        } else {
            currentImagePosition.y += croppableImage.croppedImage.size.height;
        }
    }
    
    _finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return _finalImage;
}


- (void)addCroppableImage:(CroppableImage *)croppableImage
{    
    [_croppableImages addObject:croppableImage];
    _finalImageIsValid = false;
}


- (NSInteger)getUploadFileSizeEstimate
{
    return [self getJPEGRepresentation].length;
}
- (NSData *)getJPEGRepresentation
{
    //int newLargestDimension = [Settings instance].maximumSourceImageLongestDimension;    
    UIImage *resizedImage = self.finalImage; //For now, don't make any adjustments.
    //UIImage *resizedImage = [ImageManager makeResizedImage:self.uploadableImage.finalImage withNewLargestDimension:newLargestDimension andQuality:kCGInterpolationHigh];
    return UIImageJPEGRepresentation(resizedImage, 1); // jpeg quality and size setting should be user-controlled
    
}

@end
