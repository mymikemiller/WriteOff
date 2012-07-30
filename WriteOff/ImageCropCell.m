//
//  ImageCropCell.m
//  WriteOff
//
//  Created by Mike Miller on 6/28/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//


#import "ImageCropCell.h"

@implementation ImageCropCell

@synthesize imageView;
@synthesize cropButton;

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    }
    return self;
}

@end