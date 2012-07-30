//
//  Settings.m
//  WriteOff
//
//  Created by Mike Miller on 6/28/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "Settings.h"

@implementation Settings

@synthesize mostRecentSpreadsheetURL;
@synthesize maximumSourceImageLongestDimension;

static Settings *_instance = NULL;

+ (Settings *)instance
{
    @synchronized(self)
    {
        if (_instance == NULL) {
            _instance = [[self alloc] init];
            
            _instance.maximumSourceImageLongestDimension = 1600;
        }
    }
    
    return(_instance);
}

- (NSString *) pathForStoredData {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = @"~/Library/Application Support/WriteOff/";
    folder = [folder stringByExpandingTildeInPath];
    if ([fileManager fileExistsAtPath: folder] == NO) {
        [fileManager createDirectoryAtPath:folder withIntermediateDirectories:true attributes:nil error:nil];
    }
    NSString *fileName = @"WriteOff.saveddata";
    return [folder stringByAppendingPathComponent: fileName];
}


- (void)save {
    NSString * path = [self pathForStoredData];
    NSMutableDictionary * rootObject;
    rootObject = [NSMutableDictionary dictionary];
    
    [rootObject setValue:self.mostRecentSpreadsheetURL forKey:@"mostRecentSpreadsheetURL"];
    NSNumber *maxDimension = [NSNumber numberWithInt:self.maximumSourceImageLongestDimension];
    [rootObject setValue:maxDimension forKey:@"maximumSourceImageLongestDimension"];
    [NSKeyedArchiver archiveRootObject: rootObject toFile: path];
}
- (void)load {
    NSString * path = [self pathForStoredData];
    NSDictionary * rootObject;
    rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    self.mostRecentSpreadsheetURL = [rootObject valueForKey:@"mostRecentSpreadsheetURL"];
    NSNumber *maxDimension = [rootObject valueForKey:@"maximumSourceImageLongestDimension"];
    if (maxDimension) {
    //    self.maximumSourceImageLongestDimension = [maxDimension intValue];
    }
}


@end
