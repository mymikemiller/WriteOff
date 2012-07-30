//
//  ImageCropViewController.h
//  WriteOff
//
//  Created by Mike Miller on 6/8/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageCropViewController;
@class CroppableImageView;
@class CroppableImage;

@protocol ImageCropViewControllerDelegate <NSObject>
- (void)imageCropViewControllerDidCancel:
(ImageCropViewController *)controller;
- (void)imageCropViewControllerDidSave:
(ImageCropViewController *)controller;
@end

@interface ImageCropViewController : UIViewController

@property (nonatomic, weak) id <ImageCropViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet CroppableImageView *croppableImageView;
@property (strong, nonatomic) CroppableImage *croppableImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
