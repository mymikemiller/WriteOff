//
//  ImageManager.m
//  WriteOff
//
//  Created by Mike Miller on 5/24/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#import "ImageManager.h"

#import "GDataEntryStandardDoc.h"
#import "GDataEntrySpreadsheetDoc.h"
#import "GDataServiceGoogleDocs.h"
#import "GDataQueryDocs.h"
#import "GoogleManager.h"
#import "SpreadsheetManager.h"
#import "Settings.h"


#import "GDataEntryFolderDoc.h" //can probably remove this

#import "GTMOAuth2Authentication.h"
#import "UIImage+normalize.h"

@implementation ImageManager

@synthesize uploadableImage = _uploadableImage;
@synthesize spreadsheetManager = _spreadsheetManager;


- (id)initWithImage:(UploadableImage *)theImage
   andSpreadsheetManager:(SpreadsheetManager *)theSpreadsheetManager
{
    self = [super init];
    if (self) {        
        self.uploadableImage = theImage;
        self.spreadsheetManager = theSpreadsheetManager;
        mPreviousNumberOfBytesUploaded = 0;
    }
    return self;
}

// This code came from here: http://www.iphonedevsdk.com/forum/iphone-sdk-development/5204-resize-image-high-quality.html
// Returns a rescaled copy of the image; its imageOrientation will be UIImageOrientationUp
// If the new size is not integral, it will be rounded up
+ (UIImage *)makeResizedImage:(UIImage *)image 
      withNewLargestDimension:(int)newLargestDimension
                   andQuality:(CGInterpolationQuality)interpolationQuality
{
    UIImage *theImage = [image rotated]; // re-orients the image to match the exif data (the orientation of the phone when the picture was taken) so it appears rightside up.
    
    CGRect newRect;
    if (theImage.size.width > theImage.size.height) {
        newRect = CGRectIntegral(CGRectMake(0, 0, newLargestDimension, newLargestDimension * theImage.size.height / theImage.size.width));
    } else {
        newRect = CGRectIntegral(CGRectMake(0, 0, newLargestDimension * theImage.size.width / theImage.size.height, newLargestDimension));
    }
    
    NSLog(@"RESIZING IMAGE TO KEEP LARGEST DIMENSION AT %i GIVES NEW SIZE: %@", newLargestDimension, NSStringFromCGRect(newRect));
    
    CGImageRef imageRef = theImage.CGImage;
    // Compute the bytes per row of the new image
    size_t bytesPerRow = CGImageGetBitsPerPixel(imageRef) / CGImageGetBitsPerComponent(imageRef) * newRect.size.width;
    bytesPerRow = (bytesPerRow + 15) & ~15;  // Make it 16-byte aligned
    
    // Build a bitmap context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                bytesPerRow,
                                                CGImageGetColorSpace(imageRef),
                                                CGImageGetBitmapInfo(imageRef));
    
    CGContextSetInterpolationQuality(bitmap, interpolationQuality);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef resizedImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *resizedImage = [UIImage imageWithCGImage:resizedImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(resizedImageRef);
    
    return resizedImage;
}



- (void)uploadFile:(SEL)uploadedSelector
    notifyObject:(AddRowViewController *)objectToNotify
{
    
    mUploadedSelector = uploadedSelector;
    mObjectToNotifyWhenUploaded = objectToNotify;
    
    // this function came from here: http://gdata-objectivec-client.googlecode.com/svn/trunk/Examples/DocsSample/DocsSampleWindowController.m
    //NSString *errorMsg = nil;
    
    // make a new entry for the file
    
    //getMIMEType in DocsSampleWindowController.m has these for other file types
    NSString *mimeType = @"image/jpeg";
    Class entryClass = [GDataEntryStandardDoc class];
    
    GDataEntryDocBase *newEntry = [entryClass documentEntry];
    
    NSString *title = [self.uploadableImage getFinalName];
    [newEntry setTitleWithString:title];
    
    [newEntry setUploadData:[self.uploadableImage getJPEGRepresentation]]; 
    
    //NSLog(@"Upload length: %i", [photoData length]);
        
    // This would also probably work:
    //[newEntry setUploadLocationURL:(the url from chosen photo)]
    
    [newEntry setUploadMIMEType:mimeType];
    //[newEntry setUploadSlug:@"testImage.jpg"];
    
    //GDataEntrySpreadsheetDoc *spreadsheet = self.spreadsheetManager.spreadsheet;
    
    NSURL *uploadURL;
    if (self.spreadsheetManager.parentFolderLink) {
        NSString *link = self.spreadsheetManager.parentFolderLink.href;
        // The link is in the format:      https://docs.google.com/feeds/default/private/full/folder%XXX
        // We need it to be in the format: https://docs.google.com/feeds/upload/create-session/default/private/full/folder%XXX/contents
        
        NSString *folderID;
        NSRange range = [link rangeOfString:@"%" options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            folderID = [link substringFromIndex:(1 + range.location)];
        }
        
        NSLog(@"FOLDER ID: %@", folderID);
        
        uploadURL = [NSURL URLWithString:[@"https://docs.google.com/feeds/upload/create-session/default/private/full/folder%" stringByAppendingFormat:@"%@%@", folderID, @"/contents"]];
        NSLog(@"UPLOAD URL: %@", uploadURL);
        
        
        //               https://docs.google.com/feeds/default/private/full/folder%3A0BxJZgQVaVOYPNjRkMmI4OTUtNGM4Yy00ZGM0LTk2MGMtY2YwYmQzYWViNTAw
        //need link like https://docs.google.com/feeds/upload/create-session/default/private/full/folder%3A0BxJZgQVaVOYPUksySmE5aFFqTUE/contents?convert=false
    }
    
    // If we couldn't get the parent folder for any reason (most likely because the spreadsheet isn't in a folder; it's in the root feed), upload to the root
    if (!uploadURL) {
        uploadURL = [GDataServiceGoogleDocs docsUploadURL];
    }
    
    GDataQueryDocs *query = [GDataQueryDocs queryWithFeedURL:uploadURL];
    [query setShouldConvertUpload:NO];
    [query setShouldOCRUpload:NO];
    uploadURL = [query URL];
    
    NSLog(@"uploadURL: %@", uploadURL);

    // make service tickets call back into our upload progress selector
    GDataServiceGoogleDocs *service = [self.spreadsheetManager.googleManager docsService];
    
    //NSLog(@"CanAuthorize: %@", [[self.googleManager auth] canAuthorize]);
    
    // insert the entry into the docList feed
    //
    // to update (replace) an existing entry by uploading a new file,
    // use the fetchEntryByUpdatingEntry:forEntryURL: with the URL from
    // the entry's uploadEditLink
    GDataServiceTicket *ticket;
    ticket = [service fetchEntryByInsertingEntry:newEntry
                                      forFeedURL:uploadURL
                                        delegate:self
                               didFinishSelector:@selector(uploadFileTicket:finishedWithEntry:error:)];
    //ticket.userData = folderFeed; //save the folder so we know what folder it needs to be placed in after it's uploaded.
    
    [ticket setUploadProgressHandler:^(GDataServiceTicketBase *ticket, unsigned long long numberOfBytesRead, unsigned long long dataLength) {
        // progress callback

        /*
         [mUploadProgressIndicator setMinValue:0.0];
         [mUploadProgressIndicator setMaxValue:(double)dataLength];
         [mUploadProgressIndicator setDoubleValue:(double)numberOfBytesRead];
         */

        NSLog(@"Upload at %llu of %llu, (%i%%)", numberOfBytesRead, dataLength, (int)floor(((double)numberOfBytesRead / (double)dataLength) * 100));
        
        [mObjectToNotifyWhenUploaded imageUploadProgressUpdate:(numberOfBytesRead - mPreviousNumberOfBytesUploaded)];
        mPreviousNumberOfBytesUploaded = numberOfBytesRead;
        
        if (numberOfBytesRead == dataLength) {
            NSLog(@"Uploaded all data, but the upload isn't quite finished");
            [mObjectToNotifyWhenUploaded allDataForImageUploaded];
        }
    }];
    
    NSError *e = [ticket fetchError];
    if (e) {
        NSLog(@"%@", e);
    }
    
    // we turned automatic retry on when we allocated the service, but we
    // could also turn it on just for this ticket
    
    //[self setUploadTicket:ticket];
    
    /*if (errorMsg) {
        // we're currently in the middle of the file selection sheet, so defer our
        // error sheet
        NSLog(@"Had upload error :( %@", errorMsg);
    }*/
    
    NSLog(@"Submitted upload ticket");
    
    //[self updateUI];
}

// upload finished callback
- (void)uploadFileTicket:(GDataServiceTicket *)ticket
       finishedWithEntry:(GDataEntryDocBase *)entry
                   error:(NSError *)error {
    
    //[self setUploadTicket:nil];
    //[mUploadProgressIndicator setDoubleValue:0.0];
    
    if (error == nil) {
        // refetch the current doc list
        //[self fetchDocList];
        
        // tell the user that the add worked
        NSLog(@"File uploaded!! %@", [[entry title] stringValue]);
        NSLog(@"HTML link to image:%@", [[entry HTMLLink] URL]);
        self.uploadableImage.url = [[entry HTMLLink] URL];
        [mObjectToNotifyWhenUploaded performSelector:mUploadedSelector withObject:self.uploadableImage];
        
        mPreviousNumberOfBytesUploaded = 0;
        
        
        
        
        //Now set the folder. can probably do this when uploading instead.
        // This came from http://gdata-objectivec-client.googlecode.com/svn/trunk/Examples/DocsSample/DocsSampleWindowController.m
        // the selected menu item represents a folder; fetch the folder's feed
        //
        // with the folder's feed, we can insert or remove the selected document
        // entry in the folder's feed
        /*
        GDataFeedDocList *folderFeed = ticket.userData;
        NSLog(@"folderFeed URL: %@", [[folderFeed selfLink] URL]);
        GDataEntryFolderDoc *folderEntry = [folderFeed.entries objectAtIndex:0];
        NSURL *folderFeedURL = [[folderEntry content] sourceURL];
        NSLog(@"folder's content sourceURL: %@", folderFeedURL);
        if (folderFeedURL != nil) {
            
            GDataServiceGoogleDocs *service = self.spreadsheetManager.googleManager.docsService;
            
            GDataServiceTicket *ticket;
            NSLog(@"fetching folder feed.");
            ticket = [service fetchFeedWithURL:folderFeedURL
                                      delegate:self
                             didFinishSelector:@selector(fetchFolderTicket:finishedWithFeed:error:)];
            
            // save the selected doc in the ticket's userData
            GDataEntryDocBase *doc = entry;
            [ticket setUserData:doc];
        } else {
            NSLog(@"null feed url");
        }*/
        
        
    } else {
        NSLog(@"Upload failed: %@", error);
    }
    //[self updateUI];
}

/*
- (void) useCamera
{    
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
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
        newMedia = YES;
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
        newMedia = NO;
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info
                           objectForKey:UIImagePickerControllerMediaType];
    [self dismissModalViewControllerAnimated:YES];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info 
                          objectForKey:UIImagePickerControllerOriginalImage];
        
        imageView.image = image;
        NSURL *url=[info objectForKey:UIImagePickerControllerReferenceURL];
        NSLog(@"URL for image picked: %@", url);
        
        if (newMedia)
            UIImageWriteToSavedPhotosAlbum(image, 
                                           self,
                                           @selector(image:finishedSavingWithError:contextInfo:),
                                           nil);
    }
    else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie])
    {
		// Code here to support video if enabled
	}
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

*/




@end
