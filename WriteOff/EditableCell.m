/*
 Copyright 2011 Dmitry Stadnik. All rights reserved.
 Redistribution and use in source and binary forms, with or without modification, are
 permitted provided that the following conditions are met:
 1. Redistributions of source code must retain the above copyright notice, this list of
 conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice, this list
 of conditions and the following disclaimer in the documentation and/or other materials
 provided with the distribution.
 THIS SOFTWARE IS PROVIDED BY DMITRY STADNIK ``AS IS'' AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DMITRY STADNIK OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 The views and conclusions contained in the software and documentation are those of the
 authors and should not be interpreted as representing official policies, either expressed
 or implied, of Dmitry Stadnik.
 */

#import "EditableCell.h"

#define kTextFieldDefaultWidth 180

@implementation EditableCell

@synthesize textField;

- (void)dealloc {
    self.textField = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.textLabel.numberOfLines = 0;
        self.textLabel.font = [UIFont boldSystemFontOfSize:12.0];
        
        self.textField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
        self.textField.autoresizingMask = self.detailTextLabel.autoresizingMask;
        self.textField.font = [UIFont boldSystemFontOfSize:15.0];
        self.textField.textColor = self.detailTextLabel.textColor;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.clearButtonMode = UITextFieldViewModeWhileEditing; // show the clear 'x' button to the right
        [self.contentView addSubview:self.textField];
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    const CGFloat width = self.contentView.bounds.size.width;
    
    const CGFloat height = self.contentView.bounds.size.height;
    
    const CGFloat spacing = self.textLabel.frame.origin.x;    
    // The label should take up 1/3 of the cell
    const CGFloat labelWidth = (width - (spacing * 3)) * (1/3.0);
    
    //Calculate the expected size based on the font and linebreak mode of your label
    //CGSize maximumLabelSize = CGSizeMake(labelWidth,9999);
    //NSLog(@"Sizing based on text: %@", self.textLabel.text);
    //CGSize labelSize = [self.textLabel.text sizeWithFont: [UIFont fontWithName:@"Helvetica" size:17.0] dconstrainedToSize:maximumLabelSize lineBreakMode:self.textLabel.lineBreakMode]; 
    CGSize labelSize = CGSizeMake(labelWidth, height - (spacing  * 2));
    const CGFloat labelHeight = labelSize.height;

    //const CGFloat labelHeight = self.textLabel.bounds.size.height;
    
    // The textbox should take up the rest of the width
    const CGFloat textWidth = width - labelWidth - (spacing * 3);
    const CGFloat textHeight = labelHeight;//self.textLabel.bounds.size.height;
    
    //self.textField.frame = CGRectMake(width - spacing - textWidth, (height - textHeight) / 2, textWidth, textHeight);
    self.textLabel.frame = CGRectMake(spacing, spacing, labelWidth, labelHeight);
    self.textField.frame = CGRectMake(spacing + labelWidth + spacing, spacing, textWidth, textHeight);
    /*NSLog(@"Laying out subview textField with frame %@", NSStringFromCGRect(CGRectMake(width - spacing - textWidth, (height - textHeight) / 2, textWidth, textHeight)));
    */
    //self.textLabel.backgroundColor = [UIColor redColor];
    //self.textField.backgroundColor = [UIColor cyanColor];
}

+ (void)stopEditing:(UITableView *)tableView {
    for (UITableViewCell *cell in [tableView visibleCells]) {
        if ([cell isKindOfClass:[EditableCell class]]) {
            EditableCell *editableCell = (EditableCell *)cell;
            [editableCell.textField resignFirstResponder];
        }
    }
}

@end