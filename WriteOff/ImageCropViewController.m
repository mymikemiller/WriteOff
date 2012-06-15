//
//  ImageCropViewController.m
//  WriteOff
//
//  Created by Mike Miller on 6/8/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "ImageCropViewController.h"
#import "CroppableImageView.h"

@implementation ImageCropViewController
@synthesize cancelButton;
@synthesize doneButton;
@synthesize delegate;
@synthesize imageView;

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

- (void)setImage:(UIImage *)theImage {
    NSLog(@"Setting image in ImageCropViewController");
    [self.imageView setImage:theImage];
}

- (UIImage *)image {
    return self.imageView.image;
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
    NSLog(@"viewDidLoad, so setting image");
    
    [self.imageView setImage:self.image];
}


- (void)viewDidUnload
{
    [self setCancelButton:nil];
    [self setDoneButton:nil];
    [self setImageView:nil];
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
