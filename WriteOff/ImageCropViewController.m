//
//  ImageCropViewController.m
//  WriteOff
//
//  Created by Mike Miller on 6/8/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "ImageCropViewController.h"
#import "CroppableImageView.h"
#import "CroppableImage.h"

@implementation ImageCropViewController {
    CroppableImage *_croppableImage;
}
@synthesize cancelButton;
@synthesize doneButton;
@synthesize delegate;
@synthesize croppableImageView;
//@synthesize debugImageView;
//@synthesize image = _image;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)cancel:(id)sender
{
	[self.delegate imageCropViewControllerDidCancel:self];
}
- (IBAction)done:(id)sender
{
    [self.delegate imageCropViewControllerDidSave:self];
}

- (CroppableImage*)getCroppableImage
{
    return self.croppableImageView.croppableImage;
}

- (void)setCroppableImage:(CroppableImage *)theCroppableImage {
    NSLog(@"Setting image in ImageCropViewController");
    _croppableImage = theCroppableImage;
    if (self.croppableImageView) {
        self.croppableImageView.croppableImage = theCroppableImage;
        //[self.debugImageView setImage:theImage];
    } else {
        NSLog(@"invalid imageView in ImageCropViewController, so can't set Image. Will wait until loaded.");
    }
}

- (CroppableImage *)croppableImage {
    return _croppableImage;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"ImageCropViewController viewDidLoad, so setting image in view");
    self.croppableImageView.croppableImage = _croppableImage;
}


- (void)viewDidUnload
{
    [self setCancelButton:nil];
    [self setDoneButton:nil];
    [self setCroppableImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
