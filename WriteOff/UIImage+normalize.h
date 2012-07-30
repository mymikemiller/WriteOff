//
//  UIImage+normalize.h
//  WriteOff
//
//  Created by Mike Miller on 6/22/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (normalize)

//- (UIImage *)normalizedImage;
//- (UIImage *)fixOrientation;
- (UIImage *)rotated;
- (UIImage*)flippedVertically;

@end
