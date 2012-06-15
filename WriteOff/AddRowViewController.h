//
//  AddRowViewController.h
//  WriteOff
//
//  Created by Mike Miller on 4/14/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/ALAsset.h>

#import "GoogleManager.h"
#import "SpreadsheetManager.h"
#import "ImageCropViewController.h"

@interface AddRowViewController : UIViewController
<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, ImageCropViewControllerDelegate>
{
    BOOL newMedia;
}

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UITableView *spreadsheetTableView;
@property (nonatomic, strong) SpreadsheetManager *spreadsheetManager;
@property (nonatomic) bool headersLoaded;
@property (nonatomic, strong) GoogleManager *googleManager;

- (void)editRow:(NSInteger)row;

- (void)updateUI;
- (void)didFetchHeaders;



// Google Docs
- (IBAction)sendToGoogle;


// Camera
//- (IBAction)useCamera;
//- (IBAction)useCameraRoll;

typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@end
