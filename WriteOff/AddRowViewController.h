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
#import "UploadableImage.h"
#import "GDataFeedDocList.h"
#import "ImageCropViewController.h"

#import "MBProgressHUD.h"

typedef enum {
    ImageMergeOptionNone,
    ImageMergeOptionLeftToRight,
    ImageMergeOptionTopToBottom
} ImageMergeOption;

@interface AddRowViewController : UITableViewController
<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, ImageCropViewControllerDelegate, MBProgressHUDDelegate>
{
    bool loaded;
    NSMutableArray *_images;
    NSMutableArray *_imagesToUpload;
    NSMutableArray *_imagesUploaded;
    ImageMergeOption _imageMergeOption;
    MBProgressHUD *_uploadHUD;
    unsigned long long _totalBytesToUploadEstimate;
    unsigned long long _totalBytesUploaded;
}

@property (nonatomic, strong) SpreadsheetManager *spreadsheetManager;
@property (nonatomic) bool headersLoaded;
@property (nonatomic, strong) GoogleManager *googleManager;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *submitButton;

- (void)editRow:(NSInteger)row;

- (void)updateUI;
- (void)didFetchHeaders;

// Google Docs
- (IBAction)submit;
- (void)imageUploadProgressUpdate:(unsigned long long)incrementUploaded;
- (void)allDataForImageUploaded;
- (void)didUploadImage:(UploadableImage *)theImage;
- (void)updateGoogleSpreadsheet;

// Camera
- (IBAction)useCamera;
- (IBAction)useCameraRoll;
- (IBAction)imageSettingsButtonClicked;

typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@end
