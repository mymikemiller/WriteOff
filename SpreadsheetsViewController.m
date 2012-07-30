//
//  SpreadsheetsViewController.m
//  WriteOff
//
//  Created by Mike Miller on 5/28/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "SpreadsheetsViewController.h"

#import "GDataEntrySpreadsheet.h"
#import "GDataEntrySpreadsheetDoc.h"
#import "GTMOAuth2Authentication.h"
#import "CroppableImage.h"

#import <AssetsLibrary/ALAssetRepresentation.h>
#import <AssetsLibrary/ALAsset.h>

#import "Settings.h"
#import "ImageManager.h"

@implementation SpreadsheetsViewController

@synthesize googleManager;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}



- (void)spreadsheetsFetched {
    NSLog(@"Did fetch spreadsheets!!!");
    [self.tableView reloadData];
}
- (void)spreadsheetFetched {
    NSLog(@"Did fetch single spreadsheet!!!");
    [self.tableView reloadData];
    [self performSegueWithIdentifier:@"PickSpreadsheet" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"PickSpreadsheet"])
	{
		AddRowViewController *addRowViewController = 
        segue.destinationViewController;
		//addRowViewController.delegate = self;
        

        // If we didn't select a cell but we're trying segue, just select the first spreadsheet (this happens when we fetched a single spreadsheet, in which case that spreadsheet will be the first in the array)
        // Why doesn't this work? Casting sender below into a UITableViewCell* should invalidate the pointer when the type is a SpreadsheetsViewController (self) as is sent from spreadsheetFetched and I shouldn't have to use isKindOfClass. But the pointer doesn't evaluate to false and we try to get the tag and it fails: NSInteger selectedIndex = selectedCell ? selectedCell.tag : 0;
        
        NSInteger selectedIndex = 0;
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *selectedCell = (UITableViewCell *)sender;
            selectedIndex = selectedCell.tag;
        }
        
        GDataEntrySpreadsheetDoc *spreadsheet = [googleManager.spreadsheets objectAtIndex:selectedIndex];
        //GDataEntrySpreadsheet *s = (GDataEntrySpreadsheet *)spreadsheet;
        //s.worksheetsFeedURL;
        
        NSLog(@"spreadsheet: %@", spreadsheet.title.stringValue);
        //[spreadsheet worksheetsFeedURL];
        
        SpreadsheetManager *spreadsheetManager = [[SpreadsheetManager alloc] initWithSpreadsheet:spreadsheet
                                                  andGoogleManager:self.googleManager];
        
		addRowViewController.spreadsheetManager = spreadsheetManager;
        addRowViewController.googleManager = self.googleManager;
        
        // Save the selected spreadsheet so we can automatically load it next time
        Settings *settings = [Settings instance];
        settings.mostRecentSpreadsheetURL = spreadsheet.selfLink.URL;
        [settings save]; //move this so it's automatic when setting
        
	} else if ([segue.identifier isEqualToString:@"DebugCropImage"])
	{
        NSLog(@"Preparing for debug segue to Image Crop!");
		ImageCropViewController *imageCropViewController = segue.destinationViewController;
		imageCropViewController.delegate = self;
        
        
        
        NSLog(@"loading image from url");
        
        NSString *mediaurl = @"assets-library://asset/asset.JPG?id=0AD7ACF9-152F-43FD-A2B3-82538D831B45&ext=JPG";
        
        //
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
        {
            ALAssetRepresentation *rep = [myasset defaultRepresentation];
            CGImageRef iref = [rep fullResolutionImage];
            
            if (iref) {
                NSLog(@"Image loaded. setting.");
                UIImage *largeimage = [ImageManager makeResizedImage:[UIImage imageWithCGImage:iref] withNewLargestDimension:600 andQuality:kCGInterpolationHigh];
                //[largeimage retain];
                imageCropViewController.croppableImage = [CroppableImage croppableImageWithImage:largeimage];
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

        
	}
}

- (void)imageCropViewControllerDidCancel:(ImageCropViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropViewControllerDidSave:(ImageCropViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didSignIn {
    NSLog(@"Signed in! Loading spreadsheet.");
    if (![self loadSingleSpreadsheetFromSettings]) {
        NSLog(@"No spreadsheet saved in settings; loading all");
        [self loadAllSpreadsheets];
    }
}

- (void)loadAllSpreadsheets {
    if (googleManager.auth.canAuthorize) {
        [googleManager fetchSpreadsheets:@selector(spreadsheetsFetched)];
    } else {
        NSLog(@"Can't authorize, so not loading spreadsheets");
    }
}
- (bool)loadSingleSpreadsheetFromSettings {
    if (googleManager.auth.canAuthorize) {
        Settings *settings = [Settings instance];
        [settings load]; //move this to make it automatic...
        
        NSURL *url = settings.mostRecentSpreadsheetURL; //[NSURL URLWithString:@"https://spreadsheets.google.com/feeds/spreadsheets/private/full/ts2O1C66JYwufMmm1IbVgRw"]; //selfLink
        
        if (url) {
            NSLog(@"Found url from settings, loading spreadsheet %@", url);
            [googleManager fetchSingleSpreadsheet:url fetchedSelector:@selector(spreadsheetFetched)];
            return true;
        } else {
            NSLog(@"No url stored in settings");
            return false;
        }
    } else {
        NSLog(@"Can't authorize, so not loading spreadsheet");
        return false;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!googleManager)
        googleManager = [[GoogleManager alloc] init];
    
    NSLog(@"viewDidAppear");
    if (!googleManager.auth.canAuthorize) {
        NSLog(@"View did appear, so signing in");
        [googleManager signIn:self didFinishSignInSelector:@selector(didSignIn)];
        
        //NSLog(@"Launching photo page");
        //[self performSegueWithIdentifier:@"DebugCropImage" sender:self];
    } else {
        // Already signed in, but might not have the full list of spreadsheets (if we loaded a single spreadsheet after signing in initially)
        if (googleManager.spreadsheets.count <= 1) { // We should also provide a way to refresh the list in case the user only had 1 doc and then added more.
            [self loadAllSpreadsheets];
        }
    }
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"for num rows: googleManager.spreadsheets.count: %i", [googleManager.spreadsheets count]);
    return [googleManager.spreadsheets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [tableView 
                             dequeueReusableCellWithIdentifier:@"SpreadsheetCell"];
	
    GDataEntrySpreadsheetDoc *spreadsheet = [googleManager.spreadsheets objectAtIndex:indexPath.row];
	cell.textLabel.text = spreadsheet.title.stringValue;
    cell.tag = indexPath.row;
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
