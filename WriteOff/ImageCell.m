//
//  ImageCell.m
//  WriteOff
//
//  Created by Mike Miller on 6/28/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//


#import "ImageCell.h"

@implementation ImageCell

@synthesize imageView;
@synthesize label;

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        /*
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.textLabel.numberOfLines = 0;
        self.textLabel.font = [UIFont boldSystemFontOfSize:12.0];
        
        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        self.textField.autoresizingMask = self.detailTextLabel.autoresizingMask;
        self.textField.font = [UIFont boldSystemFontOfSize:15.0];
        self.textField.textColor = self.detailTextLabel.textColor;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.clearButtonMode = UITextFieldViewModeWhileEditing; // show the clear 'x' button to the right
        */
        /*
         self.textLabel.backgroundColor = [UIColor yellowColor];
         
         self.textField.backgroundColor = [UIColor redColor];*/
        //[self.contentView addSubview:self.textField];
    }
    return self;
}

@end