//
//  ViewController.h
//  WriteOff
//
//  Created by Mike Miller on 4/14/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/ALAsset.h>

@class GTMOAuth2Authentication;
@class GDataServiceGoogleDocs;
@class GDataServiceGoogleSpreadsheet;
@class GDataFeedWorksheet;

@interface ViewController : UIViewController
<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIImageView *imageView;
    BOOL newMedia;
    GTMOAuth2Authentication *mAuth;
    NSURL* cellFeedURL;
    
    GDataFeedWorksheet *mWorksheetFeed;
    NSMutableArray* mHeaders;
}
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UITableView *spreadsheetTableView;
@property (nonatomic, retain) GTMOAuth2Authentication *auth;
@property (nonatomic, retain) NSMutableArray *headers;

- (void)editRow:(NSInteger)row;

- (void)updateUI;


// Google Docs
- (IBAction)signIn;
- (void)signOut;
- (BOOL)isSignedIn;

- (IBAction)sendToGoogle;
- (GDataServiceGoogleDocs *)docsService;
- (GDataServiceGoogleSpreadsheet *)spreadsheetService;


// Camera
- (IBAction)useCamera;
- (IBAction)useCameraRoll;

typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@end
