//
//  ImageManager.h
//  WriteOff
//
//  Created by Mike Miller on 5/24/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GoogleManager;

@interface ImageManager : NSObject
{
    
}

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, strong) GoogleManager *googleManager;


- (id)initWithImage:(UIImage *)theImage
   andGoogleManager:(GoogleManager *)googleManager;


- (void)uploadFile;

@end
