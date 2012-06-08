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


#import "EditableCell.h"
#import "ImageManager.h"
#import "ImageCropViewController.h"






@implementation AddRowViewController


@synthesize imageView;
@synthesize spreadsheetTableView;
@synthesize spreadsheetManager;
@synthesize headersLoaded;
@synthesize googleManager;


- (void)updateUI {
    
    NSLog(@"Updating UI");
    for(NSMutableArray *headerToValue in spreadsheetManager.headerToValueMap) {
        NSLog(@"Updating UI with header: %@", [headerToValue objectAtIndex:0]);
    }
    [self.spreadsheetTableView reloadData];
}

- (void)didFetchHeaders {
    self.headersLoaded = true;
    [self updateUI];
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Home Expenses";
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return spreadsheetManager.headerToValueMap.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TextCell";
    EditableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[EditableCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [[spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row] objectAtIndex:0];
    cell.textField.placeholder = cell.textLabel.text;
    
    NSString *valueText = [[spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row] objectAtIndex:1];
    if (valueText == @"DEBUG_TEXT") {
        //mikem: remove this if block and always do the else.
        cell.textField.text = [@"Test " stringByAppendingString:cell.textLabel.text];
        NSMutableArray *headerToValue = [spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row];
        [headerToValue removeObjectAtIndex:1];
        //NSLog(@"Test added string %@ value to header %@", cell.textField.text, [headerToValue objectAtIndex:0]);
        [headerToValue addObject:cell.textField.text];
    } else {
        //NSLog(@"Setting text to stored text: %@", valueText);
        cell.textField.text = valueText;
    }
    
    
    cell.textField.delegate = self;
     
    if (cell.textLabel.text == @"Price" || cell.textLabel.text == @"Cost" || cell.textLabel.text == @"Total") {
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected index %d", indexPath.row);
    [self editRow:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)editRow:(NSInteger)row
{
    [self.view endEditing:YES];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    EditableCell *cell = (EditableCell*)[self.spreadsheetTableView cellForRowAtIndexPath:path];    
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
    } else {
        // Move on to the next textField
        NSInteger nextTextFieldIndex = textField.tag + 1;
        [self editRow:nextTextFieldIndex];
    }

    return YES;
}

- (void)sendToGoogle {
    NSLog(@"Sending to Google");
    //NSLog(@"Initing with google manager whose auth canAuthorize: %@", self.googleManager.auth.canAuthorize);
    ImageManager *manager = [[ImageManager alloc] initWithImage:self.imageView.image andGoogleManager:self.googleManager];
    [manager uploadFile];
    
    //[self uploadFile];
    /*
    // get the URL for the album
    NSURL *albumURL = [GDataServiceGoogleDocs docsUploadURL
                         photoFeedURLForUserID:@"my.account@gmail.com" albumID:nil
                         albumName:@"MyBestPhotos" photoID:nil kind:nil access:nil];
    
    // make a new entry for this photo
    GDataEntryPhoto *newPhoto = [GDataEntryPhoto photoEntry];
    [newPhoto setTitleWithString:@"Sunset Photo"];
    [newPhoto setPhotoDescriptionWithString:@"A nice day"];
    
    // attach the photo data
    NSData *data = [NSData dataWithContentsOfFile:@"/SunsetPhoto.jpg"];
    [newPhoto setPhotoData:data];
    [newPhoto setPhotoMIMEType:@"image/jpeg"];
    
    // now upload it
    GDataServiceTicket *ticket;
    ticket = [service fetchEntryByInsertingEntry:newPhoto
                  forFeedURL:albumURL
                  delegate:self
                  didFinishSelector:@selector(addPhotoTicket:finishedWithEntry:error:)];
    */
    
    /* Send the spreadsheet data (disabled for now)
    if (listFeedURL) {
        NSLog(@"Using url %@", listFeedURL);
        GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
        [service fetchFeedWithURL:listFeedURL
                         delegate:self
                didFinishSelector:@selector(listTicket:finishedWithFeed:error:)];
    } else { 
        NSLog(@"No listFeedURL. Has the spreadsheet been fetched?");
    }*/
    
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
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set the Camera icon
    UIButton* titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [titleButton addTarget:self action:@selector(photoButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    titleButton.frame = CGRectMake(0, 0, 40, 40);
    
    
    UIImage *img = [UIImage imageNamed:@"86-camera.png"];
    [titleButton setImage:img forState:UIControlStateNormal];
    self.navigationItem.titleView = titleButton;
    
    
    
    self.headersLoaded = false;
    [spreadsheetManager fetchHeaders:@selector(didFetchHeaders) notifyObjectWhenDone:self];
       
    
    
    
    
    // Add an observer for text changed events for all textViews
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(textFieldDidChange:)
     name:UITextFieldTextDidChangeNotification 
     object:nil]; // Specifying nil here instead of a textField makes the function respond to any text field change.

    
        
    NSLog(@"loading image from url");
    
    NSString *mediaurl = @"assets-library://asset/asset.JPG?id=0AD7ACF9-152F-43FD-A2B3-82538D831B45&ext=JPG";
    
    //
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        
        if (iref) {
            UIImage *largeimage = [UIImage imageWithCGImage:iref];
            //[largeimage retain];
            imageView.image = largeimage;
            

            
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
    
    //UIImage *image = [info
    //                  objectForKey:UIImagePickerControllerOriginalImage];
    
    //imageView.image = image;

}

- (void)photoButtonClicked
{
    NSLog(@"Photo button clicked");
    
    [self performSegueWithIdentifier:@"CropImage" sender:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.imageView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

@end
