//
//  Settings.h
//  WriteOff
//
//  Created by Mike Miller on 6/28/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject
{
}

@property (nonatomic, strong) NSURL *mostRecentSpreadsheetURL;
@property (nonatomic) int maximumSourceImageLongestDimension;

+ (Settings *)instance;

- (void)save;
- (void)load;

@end
