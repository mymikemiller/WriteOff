//
//  ImageManager.h
//  WriteOff
//
//  Created by Mike Miller on 5/24/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UploadableImage.h"
#import "AddRowViewController.h"

#import "GDataFeedDocList.h"

@class GoogleManager;
@class SpreadsheetManager;

@interface ImageManager : NSObject
{
    SEL mUploadedSelector;
    AddRowViewController *mObjectToNotifyWhenUploaded;
    unsigned long long mPreviousNumberOfBytesUploaded;
}

@property (nonatomic, retain) UploadableImage *uploadableImage;
@property (nonatomic, strong) SpreadsheetManager *spreadsheetManager;


- (id)initWithImage:(UploadableImage *)theImage
    andSpreadsheetManager:(SpreadsheetManager *)spreadsheetManager;

+ (UIImage *)makeResizedImage:(UIImage *)image 
      withNewLargestDimension:(int)newLargestDimension
                   andQuality:(CGInterpolationQuality)interpolationQuality;

- (void)uploadFile:(SEL)uploadedSelector
      notifyObject:(AddRowViewController *)objectToNotify;

@end
