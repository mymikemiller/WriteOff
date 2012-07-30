//
//  UploadableImage.h
//  WriteOff
//
//  Created by Mike Miller on 6/29/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpreadsheetManager.h"
@class CroppableImage;

typedef enum {
    ImageMergeStyleLeftToRight,
    ImageMergeStyleTopToBottom
} ImageMergeStyle;

@interface UploadableImage : NSObject
{
    bool _finalImageIsValid;
    UIImage *_finalImage;
}

+ (UploadableImage *)uploadableImageWithCroppableImage:(CroppableImage *)image
                                 andSpreadsheetManager:(SpreadsheetManager *)theSpreadsheetManager;

@property (nonatomic, copy) NSArray *croppableImages;
@property (nonatomic, readonly) UIImage *finalImage;
@property (nonatomic) int columnIndexForName; // if -1, _name is used, otherwise the text in the specified column is used
@property (nonatomic, strong) NSString *name; // only used if _columnIndexForName is >= 0
@property (nonatomic, strong) NSURL *url; // The URL for the image after it is uploaded.
@property (nonatomic) ImageMergeStyle imageMergeStyle;
@property (nonatomic, strong) SpreadsheetManager *spreadsheetManager;

- (id)initWithSpreadsheetManager:(SpreadsheetManager *)theSpreadsheetManager;
- (NSString *)getFinalName;

- (void)addCroppableImage:(CroppableImage *)croppableImage;


- (NSInteger)getUploadFileSizeEstimate;
- (NSData *)getJPEGRepresentation;



@end
