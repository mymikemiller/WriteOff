//
//  ImageCropCell.h
//  WriteOff
//
//  Created by Mike Miller on 6/28/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCropCell : UITableViewCell
{
}

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *cropButton;

@end