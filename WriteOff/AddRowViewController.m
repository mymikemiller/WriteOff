//
//  AddRowViewController.m
//  WriteOff
//
//  Created by Mike Miller on 4/14/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "AddRowViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

#import "GTMOAuth2Authentication.h"
#import "GDataServiceGoogleDocs.h" //can probably remove this
#import "GDataQueryDocs.h" //and this
#import "GDataFeedDocList.h" //and this
#import "GDataEntryDocBase.h" //and this




#import "EditableCell.h"
#import "ImageCell.h"
#import "ImageManager.h"
#import "TransparentToolbar.h"
#import "SpreadsheetManager.h"
#import "EditImageViewController.h"
#import "Settings.h"
#import "CroppableImage.h"
#import "UIImage+normalize.h"



@implementation AddRowViewController


@synthesize spreadsheetManager;
@synthesize headersLoaded;
@synthesize googleManager;
@synthesize submitButton;

const int kTableSectionRowDetails = 0;
const int kTableSectionImages = 1;
const int kTableSectionMergeOptions = 2;
const int kTableSectionImageNameAndLink = 3;



- (void)initialize {
    loaded = false;
    _images = [[NSMutableArray alloc] init];
    _imagesToUpload = [[NSMutableArray alloc] init];
    _imagesUploaded = [[NSMutableArray alloc] init];
    _imageMergeOption = ImageMergeOptionNone;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(noticeShowKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(noticeHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    _totalBytesToUploadEstimate = 0;
    _totalBytesUploaded = 0;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}
- (id)init{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}
-(void) noticeShowKeyboard:(NSNotification *)inNotification {
    submitButton.title = @"Done";
}

-(void) noticeHideKeyboard:(NSNotification *)inNotification {
    submitButton.title = @"Submit";
}


- (void)updateUI {
    
    NSLog(@"Updating AddRowViewController UI");
    for(NSMutableArray *headerToValue in spreadsheetManager.headerToValueMap) {
        NSLog(@"Updating UI with header: %@", [headerToValue objectAtIndex:0]);
    }
    [self.tableView reloadData];
}

- (void)didFetchHeaders {
    self.headersLoaded = true;
    [self updateUI];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kTableSectionRowDetails) {
        return spreadsheetManager.spreadsheetTitle;
    } else if (section == kTableSectionImages) {
        return @"Receipts";
    } else if (section == kTableSectionMergeOptions) {
        if (_images.count > 1) {
            return @"Merge Images?";
        }
    }
    
    return @"";
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kTableSectionRowDetails) {
        return spreadsheetManager.headerToValueMap.count;
    } else if (section == kTableSectionImages) {
        return _images.count + 1;
    } else if (section == kTableSectionMergeOptions) {
        if (_images.count > 1) {
            // Only offer to merge images if there is more than one image.
            return 3;
        } else {
            return 0;
        }
    }
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kTableSectionRowDetails) {
        static NSString *CellIdentifier = @"TextCell";
        EditableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[EditableCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
        }
        
        bool linkColumnAndHasImage = indexPath.row == spreadsheetManager.headerToValueMap.count - 1 && _images.count > 0;
        
        cell.textLabel.text = [[spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row] objectAtIndex:0];
        cell.textField.placeholder = linkColumnAndHasImage ? @"(link to image)" : cell.textLabel.text;
        
        cell.textField.text = linkColumnAndHasImage ? @"" : [[spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row] objectAtIndex:1];
        
        cell.textField.enabled = !linkColumnAndHasImage;
        
        cell.textField.delegate = self;
         
        if ([cell.textLabel.text isEqualToString:@"Price"] || 
            [cell.textLabel.text isEqualToString:@"Cost"] || 
            [cell.textLabel.text isEqualToString:@"Total"]) {
            [cell.textField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
        } else {
            [cell.textField setKeyboardType:UIKeyboardTypeAlphabet];
        }
        
        if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
            [cell.textField setReturnKeyType:UIReturnKeyDone];
        } else {
            [cell.textField setReturnKeyType:UIReturnKeyNext];
        }
        
        cell.textField.tag = indexPath.row;
        return cell;
    } else if (indexPath.section == kTableSectionImages) {
        if (indexPath.row < _images.count) {
            static NSString *CellIdentifier = @"ImageCell";
            ImageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[ImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            cell.label.numberOfLines = 3;
            cell.label.font = [UIFont boldSystemFontOfSize:12.0];
            
            CroppableImage *croppableImage =  [_images objectAtIndex:indexPath.row];
            //NSString *imageName = [uploadableImage getFinalName];
            
            cell.label.text = @"Tap to crop";
            cell.imageView.image = croppableImage.croppedImage;
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            // We'll need the row to find which row we clicked when we prepareForSegue
            cell.tag = indexPath.row;
            
            return cell;
        } else {
            static NSString *CellIdentifier = @"AddImageCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
            backView.backgroundColor = [UIColor clearColor];
            cell.backgroundView = backView;
            return cell;
        }
    } else { // if (indexPath.section == kTableSectionMergeOptions) {
        static NSString *CellIdentifier = @"MergeImagesCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Don't merge";
            if (_imageMergeOption == ImageMergeOptionNone) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Merge Left to Right";
            if (_imageMergeOption == ImageMergeOptionLeftToRight) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        } else {
            cell.textLabel.text = @"Merge Top to Bottom";
            if (_imageMergeOption == ImageMergeOptionTopToBottom) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kTableSectionRowDetails) {
        //Calculate the expected size based on the font and linebreak mode of your label
        UIFont *labelFont = [UIFont boldSystemFontOfSize:12.0];
        UIFont *textFont = [UIFont boldSystemFontOfSize:15.0];
        CGSize constraintSize = CGSizeMake(90, MAXFLOAT); // 90 is a magic number! It's the width EditableCell's textLabel's frame ends up with in layoutSubviews when iphone is vertical.
        
        CGSize labelSize = [[[spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row] objectAtIndex:0] sizeWithFont:labelFont
                                          constrainedToSize:constraintSize 
                                                                      lineBreakMode:UILineBreakModeWordWrap]; 
        CGSize textSize = [@"Test" sizeWithFont:textFont
                                                                  constrainedToSize:constraintSize 
                                                                      lineBreakMode:UILineBreakModeWordWrap]; 
        
        CGFloat largestSubviewHeight = MAX(labelSize.height, textSize.height);

        return largestSubviewHeight + 26.0; //magic number: 2*10 for vertical buffer for the outer edge of the label + 2*3 for spacing between the text and the top and bottom of the textView
    } else if (indexPath.section == kTableSectionImages) {
        // Image rows get a fixed height
        if (indexPath.row < _images.count) {
            return 84;
        } else {
            return 64;
        }
    } else { 
        return 48;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return (indexPath.section == kTableSectionImages && indexPath.row < _images.count);
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_images removeObjectAtIndex:indexPath.row];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (_images.count == 1) {
            // If we just deleted the second-to-last image, we need to remove the merge images rows.
            NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
            for (int i = 0; i < [tableView numberOfRowsInSection:kTableSectionMergeOptions]; ++i) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:kTableSectionMergeOptions]];
            }
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else if (_images.count == 0) {
            // If we just deleted the last image, we need to update the last detail row to show that it will no longer contain a link to an image.
            NSIndexPath *indexPathToLastRowInSpreadsheet = [NSIndexPath indexPathForRow:spreadsheetManager.headerToValueMap.count - 1 inSection:kTableSectionRowDetails];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPathToLastRowInSpreadsheet] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView endUpdates];
    }    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kTableSectionRowDetails) {
        NSLog(@"Selected index %d", indexPath.row);
        [self editRow:indexPath.row];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == kTableSectionMergeOptions) {
        switch (indexPath.row) {
            case 0:
                _imageMergeOption = ImageMergeOptionNone;
                break;
            case 1:
                _imageMergeOption = ImageMergeOptionLeftToRight;
                break;
            case 2:
                _imageMergeOption = ImageMergeOptionTopToBottom;
                break;
            default:
                break;
        }
        [self updateUI];
    }
}

- (void)editRow:(NSInteger)row
{
    [self.view endEditing:YES];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    EditableCell *cell = (EditableCell*)[self.tableView cellForRowAtIndexPath:path];    
    NSLog(@"Editing row %d", row);
    NSLog(@"  row text: %@", cell.textLabel.text);
    
    
    if([cell.textField becomeFirstResponder]) {
        NSLog(@"Became first responder");
    } else {
        NSLog(@"Could not become first responder");
    }
}

- (void)saveTextFieldToMap:(UITextField *)textField {
    NSLog(@"saveTextFieldToMap");
    NSMutableArray *headerToValue = [spreadsheetManager.headerToValueMap objectAtIndex:textField.tag];
    [headerToValue removeObjectAtIndex:1];
    NSLog(@"Added string %@ value to header %@", textField.text, [headerToValue objectAtIndex:0]);
    [headerToValue addObject:textField.text]; //mikem: if this text field is destroyed from too long a list in the tabieview when it scrolls out of view, should i create a copy of the string instead of using the pointer here? Test this!
    
}

- (void)textFieldDidChange:(NSNotification *)notif {
    NSLog(@"Got textFieldDidChange!");
    NSLog(@"With textfield object with text %@", [(UITextField*)notif.object text]);
    [self saveTextFieldToMap:(UITextField*)notif.object];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self saveTextFieldToMap:textField];
    
    if (textField.returnKeyType == UIReturnKeyDone) {
        [textField resignFirstResponder];
        // We may have updated the row that determines the name for an image
        [self updateUI];
    } else {
        // Move on to the next textField
        NSInteger nextTextFieldIndex = textField.tag + 1;
        [self editRow:nextTextFieldIndex];
    }

    return YES;
}

- (void)didUpdateSpreadsheet {
    NSLog(@"Finished updating spreadsheet! Yay!");
    [_uploadHUD hide:true];
}

- (void)imageUploadProgressUpdate:(unsigned long long)incrementUploaded
{
    NSLog(@"Increment uploaded: %llu", incrementUploaded);
    _totalBytesUploaded += incrementUploaded;
    _uploadHUD.progress = fminf(_totalBytesUploaded / (float)_totalBytesToUploadEstimate, 1);
}
- (void)allDataForImageUploaded {
    NSLog(@"allDataForImageUploaded.");
    // Assume that if we're within 10% of our estimated total bytes, we've finished uploading the final image.
    if (_totalBytesUploaded > 0.9 * _totalBytesToUploadEstimate) {
        // We uploaded the last of the data for the last image, though the upload hasn't completed all the way. Still, we don't want the HUD to sit at 100% because that's annoying. Switch to the "Updating spreadsheet" HUD.
        NSLog(@"Switching HUD text early");
        _uploadHUD.mode = MBProgressHUDModeIndeterminate;
        _uploadHUD.labelText = @"Updating Spreadsheet";
    }
}

- (void)uploadToGoogle {
    NSLog(@"Sending to Google");
    
    // If we have images, upload them before modifying the spreadsheet. The spreadsheet is modified after the last image finishes uploading.
    if (_images.count > 0) {
        //NSLog(@"Initing with google manager whose auth canAuthorize: %@", self.googleManager.auth.canAuthorize);
        
        [_imagesToUpload removeAllObjects];
        [_imagesUploaded removeAllObjects];
        
        if (_imageMergeOption == ImageMergeOptionNone) {
            for (CroppableImage *image in _images) {
                UploadableImage *uploadableImage = [UploadableImage uploadableImageWithCroppableImage:image andSpreadsheetManager:self.spreadsheetManager];
                [_imagesToUpload addObject:uploadableImage];
            }
        } else {
            UploadableImage *uploadableImage = [[UploadableImage alloc] initWithSpreadsheetManager:self.spreadsheetManager];
            for (CroppableImage *image in _images) {
                [uploadableImage addCroppableImage:image];
            }
            uploadableImage.imageMergeStyle = _imageMergeOption == ImageMergeOptionLeftToRight ? ImageMergeStyleLeftToRight : ImageMergeStyleTopToBottom;
            [_imagesToUpload addObject:uploadableImage];
        }
        
        // Estimate how many bytes we have to upload so we can update the HUD as we are notified of the progress
        _totalBytesToUploadEstimate = 0;
        for (UploadableImage *image in _imagesToUpload) {
            _totalBytesToUploadEstimate += [image getUploadFileSizeEstimate];
        }
        
        _totalBytesUploaded = 0;
        for (UploadableImage *image in _imagesToUpload) {
            ImageManager *manager = [[ImageManager alloc] initWithImage:image andSpreadsheetManager:self.spreadsheetManager];
            
            [manager uploadFile:@selector(didUploadImage:) notifyObject:self];
        }
    } else {
        [self updateGoogleSpreadsheet];
    }
}

- (IBAction)submit {
    if ([submitButton.title isEqualToString:@"Done"]) {
        // Dismiss the keyboard
        [self.view endEditing:YES];
        // We may have updated the row that determines the name for an image
        [self updateUI];
    } else {
        _uploadHUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_uploadHUD];
        
        // Set determinate mode
        _uploadHUD.mode = MBProgressHUDModeDeterminate;
        
        _uploadHUD.delegate = self;
        if (_imageMergeOption == ImageMergeOptionNone && _images.count >1) {
            _uploadHUD.labelText = @"Uploading Images";
        } else {
            _uploadHUD.labelText = @"Uploading Image";
        }
        
        _uploadHUD.progress = 0;
        
        [_uploadHUD show:true];
        
        // myProgressTask uses the HUD instance to update progress
        //[_uploadHUD showWhileExecuting:@selector(uploadToGoogle) onTarget:self withObject:nil animated:YES];
        
        [self uploadToGoogle];
    }
}

- (void)didUploadImage:(UploadableImage *)theImage
{
    NSLog(@"Image uploaded, AddRowViewController responding!");
    NSLog(@"URL: %@", theImage.url);
    
    [_imagesToUpload removeObject:theImage];
    [_imagesUploaded addObject:theImage];
    
    // Check if we've uploaded all the images
    if (_imagesToUpload.count > 0) {
        NSLog(@"Not all images have been uploaded yet. Waiting for final image.");
        return;
    }
    
    // We just finished uploading the final image. Add links to the images in the last column (the formula expands the link if there are multiple images so they take up as many columns to the right as necessary)
    NSInteger imageLinkColumn = spreadsheetManager.headerToValueMap.count - 1;
    
    NSMutableArray *linksArray = [[NSMutableArray alloc] initWithCapacity:_imagesUploaded.count];
    NSMutableArray *textArray = [[NSMutableArray alloc] initWithCapacity:_imagesUploaded.count];
    for (UploadableImage *image in _imagesUploaded) {
        [linksArray addObject:image.url.absoluteString];
        [textArray addObject:image.name];
    }
    
    NSMutableString *linksFormula;
    
    if (_imagesUploaded.count == 1) {
        linksFormula = [NSString stringWithFormat:@"=HYPERLINK(\"%@\", \"%@\")",
                        [linksArray objectAtIndex:0], [textArray objectAtIndex:0]];
    } else {
        linksFormula = [NSMutableString stringWithString:@"=ARRAYFORMULA(HYPERLINK({\""];
        [linksFormula appendString:[linksArray componentsJoinedByString:@"\", \""]];
        [linksFormula appendString:@"\"}, {\""];
        [linksFormula appendString:[textArray componentsJoinedByString:@"\", \""]];
        [linksFormula appendString:@"\" }))"];
    }
    
    NSLog(@"Final string: %@", linksFormula);
    
    NSMutableArray *headerToValue = [spreadsheetManager.headerToValueMap objectAtIndex:imageLinkColumn];
    [headerToValue removeObjectAtIndex:1];
    [headerToValue addObject:linksFormula];
    
    // Now add the row to the spreadsheet
    [self updateGoogleSpreadsheet];
}

- (void)updateGoogleSpreadsheet {
    _uploadHUD.mode = MBProgressHUDModeIndeterminate;
    _uploadHUD.labelText = @"Updating Spreadsheet";
    [spreadsheetManager uploadToGoogle:@selector(didUpdateSpreadsheet) notifyObjectWhenDone:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"AddRowViewController ViewDidLoad");
    if (loaded) {
        // We've already initialized.
        NSLog(@"Already initialized, so returning");
        [self updateUI];
        return;
    }
    
	// Do any additional setup after loading the view, typically from a nib.
    
    // Create the camera button (code from http://osmorphis.blogspot.com/2009/05/multiple-buttons-on-navigation-bar.html)
    // create a toolbar to contain the button
    /*
    TransparentToolbar* cameraToolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, 64, 44)];
    
    // create the array to hold the buttons, which then gets added to the toolbar
    NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:3];
    
    // create a standard "add" button
    UIBarButtonItem* cameraButton = [[UIBarButtonItem alloc]
                           initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(photoButtonClicked)];
    cameraButton.style = UIBarButtonItemStyleBordered;
    
    // Create a spacer
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [buttons addObject:spacer];
    
    
    [buttons addObject:spacer];
    [buttons addObject:cameraButton];
    [buttons addObject:spacer];
    
    
    // create a standard "refresh" button
    //bi = [[UIBarButtonItem alloc]
    //      initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    //bi.style = UIBarButtonItemStyleBordered;
    //[buttons addObject:bi];
    
    // stick the buttons in the toolbar
    [cameraToolbar setItems:buttons animated:NO];
    
    [cameraToolbar setBackgroundColor:[UIColor clearColor]];
    [cameraToolbar setTranslucent:TRUE];
    
    // and put the toolbar in the nav bar
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cameraToolbar];

    self.navigationItem.titleView = cameraToolbar;
    */
    
    
    // Set the Camera icon
    /*
    UIButton* titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [titleButton addTarget:self action:@selector(photoButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    titleButton.frame = CGRectMake(0, 0, 40, 40);
    
    
    UIImage *img = [UIImage imageNamed:@"86-camera.png"];
    [titleButton setImage:img forState:UIControlStateNormal];
    self.navigationItem.titleView = titleButton;
    */
    
    
    self.headersLoaded = false;
    [spreadsheetManager fetchHeaders:@selector(didFetchHeaders) notifyObjectWhenDone:self];
       
    
    
    
    
    // Add an observer for text changed events for all textViews
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(textFieldDidChange:)
     name:UITextFieldTextDidChangeNotification 
     object:nil]; // Specifying nil here instead of a textField makes the function respond to any text field change.

    
    /*
        
    NSLog(@"loading image from url");
    
    NSString *mediaurl = @"assets-library://asset/asset.JPG?id=0AD7ACF9-152F-43FD-A2B3-82538D831B45&ext=JPG";
    
    //
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        
        if (iref) {
            UIImage *largeimage = [ImageManager makeResizedImage:[UIImage imageWithCGImage:iref] withNewLargestDimension:600 andQuality:kCGInterpolationHigh];
            UploadableImage *uploadableImage = [UploadableImage uploadableImageWithCroppableImage:[CroppableImage croppableImageWithImage:largeimage]];
            
            //Add duplicate image for testing
            [uploadableImage addCroppableImage:[CroppableImage croppableImageWithImage:largeimage]];
            
            
            [_images addObject:uploadableImage];
            [self updateUI];
        }
    };
    
    //
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        NSLog(@"booya, cant get image - %@",[myerror localizedDescription]);
    };
    
    if(mediaurl && [mediaurl length])
    {
        NSURL *asseturl = [NSURL URLWithString:mediaurl];
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:asseturl 
                       resultBlock:resultblock
                      failureBlock:failureblock];
    }


    NSLog(@"done loading image");
    */
    //UIImage *image = [info
    //                  objectForKey:UIImagePickerControllerOriginalImage];
    
    //imageView.image = image;
    loaded = true;
}


- (void) useCamera
{    
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
        NSLog(@"Popping up camera");
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = 
        UIImagePickerControllerSourceTypeCamera;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:
                                  (NSString *) kUTTypeImage,
                                  nil];
        imagePicker.allowsEditing = NO;
        [self presentModalViewController:imagePicker 
                                animated:YES];
    }
}

- (void) useCameraRoll
{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    {
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = 
        UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:
                                  (NSString *) kUTTypeImage,
                                  nil];
        imagePicker.allowsEditing = NO;
        [self presentModalViewController:imagePicker animated:YES];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info
                           objectForKey:UIImagePickerControllerMediaType];
    
    //[self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:^() {
        NSLog(@"Completed dismissing camera view.");
        
        if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
            
            NSLog(@"Took picture. Getting rotated image.");
            
            
            MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:hud];
            
            hud.delegate = self;
            //hud.labelText = @"Processing Image";
            //HUD.detailsLabelText = @"updating data";
            hud.square = YES;
            
            __block UIImage *resizedImage;
            
            //[HUD showWhileExecuting:@selector(myTask) onTarget:self withObject:image animated:YES];
            [hud showAnimated:YES whileExecutingBlock:^{
                UIImage *image = [[info objectForKey:UIImagePickerControllerOriginalImage] rotated];
                
                int newLargestDimension = [Settings instance].maximumSourceImageLongestDimension;
                NSLog(@"newLargestDimension: %i", newLargestDimension);
                
                resizedImage = [ImageManager makeResizedImage:image withNewLargestDimension:newLargestDimension andQuality:kCGInterpolationHigh];
                
            } completionBlock:^{
                [hud removeFromSuperview];
                CroppableImage *croppableImage = [CroppableImage croppableImageWithImage:resizedImage];
                NSLog(@"Adding image to table");
                NSMutableArray *indexPathsForNewCells = [[NSMutableArray alloc] initWithCapacity:1];
                [indexPathsForNewCells addObject:[NSIndexPath indexPathForRow:_images.count inSection:kTableSectionImages]];
                
                [_images addObject:croppableImage];
                
                // Also insert the "merge options" rows if we added a second image
                if (_images.count == 2) {
                    [indexPathsForNewCells addObject:[NSIndexPath indexPathForRow:0 inSection:kTableSectionMergeOptions]];
                    [indexPathsForNewCells addObject:[NSIndexPath indexPathForRow:1 inSection:kTableSectionMergeOptions]];
                    [indexPathsForNewCells addObject:[NSIndexPath indexPathForRow:2 inSection:kTableSectionMergeOptions]];
                }
                
                
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPathsForNewCells withRowAnimation:UITableViewRowAnimationAutomatic];
                if (_images.count == 1) {
                    // If we just added the first image, we need to update the last row in the spreadsheet to state that it's now going to contain a link to the image.
                    NSIndexPath *indexPathToLastRowInSpreadsheet = [NSIndexPath indexPathForRow:spreadsheetManager.headerToValueMap.count - 1 inSection:kTableSectionRowDetails];
                    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPathToLastRowInSpreadsheet] withRowAnimation:UITableViewRowAnimationFade];
                }

                [self.tableView endUpdates];
                
                
                //NSLog(@"Updating UI");
                //[self updateUI];
                NSLog(@"Done");
                
                // Scroll to the newly added image
                /*CGPoint bottomOffset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height);
                 [self.tableView setContentOffset:bottomOffset animated:YES];
                 */
                
            }];
            
        }

    }];
}


-(void)image:(UIImage *)image
finishedSavingWithError:(NSError *)error 
 contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Save failed"
                              message: @"Failed to save image"\
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imageCropViewControllerDidCancel:(ImageCropViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (void)imageCropViewControllerDidSave:(ImageCropViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"crop view saved, getting cropped image");
    //UploadableImage *image = [UploadableImage imageWithCGImage:[[controller getCroppedImage] CGImage]];
    //[_images addObject:image];
    [self updateUI];
}

- (void)imageSettingsButtonClicked {
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"prepareForSegue");
    if ([segue.identifier isEqualToString:@"EditImage"]) {
        EditImageViewController *editImageViewController = segue.destinationViewController;
        ImageCell *clickedCell = sender;
        NSInteger selectedIndex = clickedCell.tag;

        editImageViewController.uploadableImage = [_images objectAtIndex:selectedIndex];      
    
    }
    else if ([segue.identifier isEqualToString:@"CropImage"])
	{
        NSInteger row = ((UIButton *)sender).tag;
        CroppableImage *croppableImage = [_images objectAtIndex:row];
        
        NSLog(@"Preparing for CropImage segue from row %i!", row);
        ImageCropViewController *imageCropViewController = segue.destinationViewController;
        imageCropViewController.delegate = self;
        if (croppableImage) {
            NSLog(@"valid image in prepareForSegue, so setting on imageCropViewController");
            imageCropViewController.croppableImage = croppableImage;
        } else {
            NSLog(@"INVALID IMAGE in prepareForSegue");
        }
	}
	else if ([segue.identifier isEqualToString:@"CropImage"])
	{
        /*
        NSLog(@"Preparing for CropImage segue!");
		ImageCropViewController *imageCropViewController = segue.destinationViewController;
		imageCropViewController.delegate = self;
        if (_preCroppedImage) {
            NSLog(@"valid image in prepareForSegue, so setting on imageCropViewController");
            imageCropViewController.image = _preCroppedImage;
        } else {
            NSLog(@"INVALID IMAGE in prepareForSegue");
        }*/
	}
}




- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    NSLog(@"AddRowViewController viewDidUnload");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateUI];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}

#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[_uploadHUD removeFromSuperview];
	_uploadHUD = nil;
}

@end
