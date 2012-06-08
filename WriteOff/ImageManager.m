//
//  ImageManager.m
//  WriteOff
//
//  Created by Mike Miller on 5/24/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "ImageManager.h"

#import "GDataEntryStandardDoc.h"
#import "GDataServiceGoogleDocs.h"
#import "GDataQueryDocs.h"
#import "GoogleManager.h"

#import "GTMOAuth2Authentication.h"

@implementation ImageManager

@synthesize image = _image;
@synthesize googleManager = _googleManager;


- (id)initWithImage:(UIImage *)theImage
   andGoogleManager:(GoogleManager *)theGoogleManager
{
    self = [super init];
    if (self) {        
        self.image = theImage;
        self.googleManager = theGoogleManager;
    }
    return self;
}

//http://blog.logichigh.com/2008/06/05/uiimage-fix/
- (UIImage *)scaleAndRotateImage:(UIImage *)theImage
{  
    int kMaxResolution = 320; // Or whatever  
    
    CGImageRef imgRef = theImage.CGImage;  
    
    CGFloat width = CGImageGetWidth(imgRef);  
    CGFloat height = CGImageGetHeight(imgRef);  
    
    CGAffineTransform transform = CGAffineTransformIdentity;  
    CGRect bounds = CGRectMake(0, 0, width, height);  
    if (width > kMaxResolution || height > kMaxResolution) {  
        CGFloat ratio = width/height;  
        if (ratio > 1) {  
            bounds.size.width = kMaxResolution;  
            bounds.size.height = bounds.size.width / ratio;  
        }  
        else {  
            bounds.size.height = kMaxResolution;  
            bounds.size.width = bounds.size.height * ratio;  
        }  
    }  
    
    CGFloat scaleRatio = bounds.size.width / width;  
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));  
    CGFloat boundHeight;  
    UIImageOrientation orient = theImage.imageOrientation;
    switch(orient) {  
            
        case UIImageOrientationUp: //EXIF = 1  
            NSLog(@"image orientation: up");
            transform = CGAffineTransformIdentity;  
            break;  
            
        case UIImageOrientationUpMirrored: //EXIF = 2  
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);  
            transform = CGAffineTransformScale(transform, -1.0, 1.0);  
            break;  
            
        case UIImageOrientationDown: //EXIF = 3  
            NSLog(@"image orientation: down");
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);  
            transform = CGAffineTransformRotate(transform, M_PI);  
            break;  
            
        case UIImageOrientationDownMirrored: //EXIF = 4  
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);  
            transform = CGAffineTransformScale(transform, 1.0, -1.0);  
            break;  
            
        case UIImageOrientationLeftMirrored: //EXIF = 5  
            boundHeight = bounds.size.height;  
            bounds.size.height = bounds.size.width;  
            bounds.size.width = boundHeight;  
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);  
            transform = CGAffineTransformScale(transform, -1.0, 1.0);  
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);  
            break;  
            
        case UIImageOrientationLeft: //EXIF = 6 
            NSLog(@"image orientation: Left"); 
            boundHeight = bounds.size.height;  
            bounds.size.height = bounds.size.width;  
            bounds.size.width = boundHeight;  
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);  
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);  
            break;  
            
        case UIImageOrientationRightMirrored: //EXIF = 7  
            boundHeight = bounds.size.height;  
            bounds.size.height = bounds.size.width;  
            bounds.size.width = boundHeight;  
            transform = CGAffineTransformMakeScale(-1.0, 1.0);  
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);  
            break;  
            
        case UIImageOrientationRight: //EXIF = 8  
            NSLog(@"image orientation: right");
            boundHeight = bounds.size.height;  
            bounds.size.height = bounds.size.width;  
            bounds.size.width = boundHeight;  
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);  
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);  
            break;  
            
        default:  
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];  
            
    }  
    
    UIGraphicsBeginImageContext(bounds.size);  
    
    CGContextRef context = UIGraphicsGetCurrentContext();  
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {  
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);  
        CGContextTranslateCTM(context, -height, 0);  
    }  
    else {  
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);  
        CGContextTranslateCTM(context, 0, -height);  
    }  
    
    CGContextConcatCTM(context, transform);  
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);  
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();  
    UIGraphicsEndImageContext();  
    
    return imageCopy;
}  

// This code came from here: http://www.iphonedevsdk.com/forum/iphone-sdk-development/5204-resize-image-high-quality.html
// Returns a rescaled copy of the image; its imageOrientation will be UIImageOrientationUp
// If the new size is not integral, it will be rounded up
- (UIImage *)makeResizedImage:(CGSize)newSize quality:(CGInterpolationQuality)interpolationQuality {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    
    UIImage *theImage = [self scaleAndRotateImage:self.image]; // re-orients the image to match the exif data (the orientation of the phone when the picture was taken) so it appears rightside up.
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

- (void)uploadFile {
    
    // this function came from here: http://gdata-objectivec-client.googlecode.com/svn/trunk/Examples/DocsSample/DocsSampleWindowController.m
    NSString *errorMsg = nil;
    
    // make a new entry for the file
    
    //getMIMEType in DocsSampleWindowController.m has these for other file types
    NSString *mimeType = @"image/jpeg";
    Class entryClass = [GDataEntryStandardDoc class];
    
    GDataEntryDocBase *newEntry = [entryClass documentEntry];
    
    NSString *title = @"Test image title";
    [newEntry setTitleWithString:title];
    
    CGSize newSize = CGSizeMake(self.image.size.width / 10, self.image.size.height / 10);
    UIImage *resizedImage = [self makeResizedImage:newSize quality:kCGInterpolationHigh];
    NSData *photoData = UIImageJPEGRepresentation(resizedImage, 0.6); // jpeg quality and size setting should be user-controlled
    [newEntry setUploadData:photoData]; 
        
    // This would also probably work:
    //[newEntry setUploadLocationURL:(the url from chosen photo)]
    
    [newEntry setUploadMIMEType:mimeType];
    [newEntry setUploadSlug:@"testImage.jpg"];
    
    NSURL *uploadURL = [GDataServiceGoogleDocs docsUploadURL];
    
    // add the OCR or translation parameters, if the user set the pop-up
    // button appropriately
    
    GDataQueryDocs *query = [GDataQueryDocs queryWithFeedURL:uploadURL];
    
    [query setShouldConvertUpload:NO];
    [query setShouldOCRUpload:NO];
    
    // we'll leave out the sourceLanguage parameter to get
    // auto-detection of the file's language
    //
    // language codes: http://www.loc.gov/standards/iso639-2/php/code_list.php
    //[query setTargetLanguage:targetLanguage];
    
    uploadURL = [query URL];
    NSLog(@"uploadURL: %@", uploadURL);
    
    
    // make service tickets call back into our upload progress selector
    GDataServiceGoogleDocs *service = [self.googleManager docsService];
    
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
    
    [ticket setUploadProgressHandler:^(GDataServiceTicketBase *ticket, unsigned long long numberOfBytesRead, unsigned long long dataLength) {
        // progress callback

        /*
         [mUploadProgressIndicator setMinValue:0.0];
         [mUploadProgressIndicator setMaxValue:(double)dataLength];
         [mUploadProgressIndicator setDoubleValue:(double)numberOfBytesRead];
         */

        NSLog(@"Upload at %llu of %llu, (%i%%)", numberOfBytesRead, dataLength, (int)floor(((double)numberOfBytesRead / (double)dataLength) * 100));
    }];
    
    NSError *e = [ticket fetchError];
    NSLog(@"%@", e);
    
    // we turned automatic retry on when we allocated the service, but we
    // could also turn it on just for this ticket
    
    //[self setUploadTicket:ticket];
    
    if (errorMsg) {
        // we're currently in the middle of the file selection sheet, so defer our
        // error sheet
        NSLog(@"Had upload error :( %@", errorMsg);
    }
    
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
        
        NSLog(@"HTML link to image:%@", [entry HTMLLink]);
        
        
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
