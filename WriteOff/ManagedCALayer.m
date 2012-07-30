//
//  ManagedCALayer.m
//  WriteOff
//
//  Created by Mike Miller on 6/15/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "ManagedCALayer.h"

@implementation ManagedCALayer

@synthesize displayImage;

- (void)display

{
    NSLog(@"Managed CALayer display!");
        
        // display the no image
        
        //self.contents=[someHelperObject loadStateNoImage];
    self.contents = displayImage;
    
}
@end
