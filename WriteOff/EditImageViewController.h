//
//  EditImageViewController.h
//  WriteOff
//
//  Created by Mike Miller on 7/7/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/ALAsset.h>
#import "ImageCropViewController.h"
#import "UploadableImage.h"

@interface EditImageViewController : UITableViewController
<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, ImageCropViewControllerDelegate>
{
    
}

@property (nonatomic, weak) UploadableImage *uploadableImage;

- (IBAction)cropButtonPressed:(id)sender;


// Camera
- (IBAction)useCamera;
- (IBAction)useCameraRoll;

@end
