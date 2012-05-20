//
//  ViewController.m
//  WriteOff
//
//  Created by Mike Miller on 4/14/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>

#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2SignIn.h"
#import "GData.h"
#import "GDataServiceGoogleDocs.h"

#import "EditableCell.h"

#import <AssetsLibrary/ALAssetRepresentation.h>



static NSString *const kKeychainItemName = @"WriteOff: Docs and Spreadsheets";
static NSString *const kShouldSaveInKeychainKey = @"shouldSaveInKeychain";

static NSString *const kClientIDKey = @"970839269491.apps.googleusercontent.com";
static NSString *const kClientSecretKey = @"eaTahaI9Wa0h0OFMHd-h48O6";// pre-assigned by service. Found here: https://code.google.com/apis/console/


@interface ViewController()
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error;
- (BOOL)shouldSaveInKeychain;

@end


@implementation ViewController


@synthesize imageView;
@synthesize spreadsheetTableView;
@synthesize auth = mAuth;
@synthesize headers = mHeaders;


- (void)updateUI {
    /*
    NSLog(@"Updating UI");
    for(NSString *header in self.headers) {
        NSLog(@"Updating UI with header: %@", header);
    }*/
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
    [self updateUI];
    return self.headers.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TextCell";
    EditableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[EditableCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
    }    
    
    cell.textLabel.text = [self.headers objectAtIndex:indexPath.row];
    cell.textField.placeholder = [self.headers objectAtIndex:indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //Calculate the expected size based on the font and linebreak mode of your label
    
    
    UIFont *labelFont = [UIFont boldSystemFontOfSize:12.0];
    UIFont *textFont = [UIFont boldSystemFontOfSize:15.0];
    CGSize constraintSize = CGSizeMake(90, MAXFLOAT); // 90 is a magic number! It's the width EditableCell's textLabel's frame ends up with in layoutSubviews when iphone is vertical.
    
    CGSize labelSize = [[self.headers objectAtIndex:indexPath.row] sizeWithFont:labelFont
                                      constrainedToSize:constraintSize 
                                                                  lineBreakMode:UILineBreakModeWordWrap]; 
    CGSize textSize = [@"Test" sizeWithFont:textFont
                                                              constrainedToSize:constraintSize 
                                                                  lineBreakMode:UILineBreakModeWordWrap]; 
    
    CGFloat largestSubviewHeight = MAX(labelSize.height, textSize.height);

    return largestSubviewHeight + 20.0; //magic number: 2x spacing at top and bottom of label
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

- (void)signIn
{
    NSLog(@"Signing in...");
    
    [self signOut];
    
    NSString *clientID = kClientIDKey;
    NSString *clientSecret = kClientSecretKey;
    
    NSString *keychainItemName = nil;
    if ([self shouldSaveInKeychain]) {
        keychainItemName = kKeychainItemName;
        
        
        // First try logging in from the keychain. Should try this when launching without having to click sign in
        // Get the saved authentication, if any, from the keychain.
        GTMOAuth2Authentication *auth;
        auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:keychainItemName
                 clientID:kClientIDKey
             clientSecret:kClientSecretKey];
        
        // Retain the authentication object, which holds the auth tokens
        //
        // We can determine later if the auth object contains an access token
        // by calling its -canAuthorize method
        self.auth = auth;
        if ([self.auth canAuthorize]) {
            NSLog(@"Logged in from keychain!");
            return;
        } else {
            NSLog(@"Failed to log in from keychain. Loading window");
        }
    }
    
    // Failed to log in from keychain. Pop up log in window.
    // remove the stored Google authentication from the keychain, if any
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    
    // For Google APIs, the scope strings are available
    // in the service constant header files.
    NSString *scope = [GTMOAuth2Authentication scopeWithStrings:
                      [GDataServiceGoogleDocs authorizationScope],
                      [GDataServiceGoogleSpreadsheet authorizationScope],
                      nil];
    //The above creates this string, which would work just as well:
    //NSString *scope = @"https://docs.google.com/feeds/ https://spreadsheets.google.com/feeds"; // scope for Google Docs and spreadsheets
    
        
    // Note:
    // GTMOAuth2ViewControllerTouch is not designed to be reused. Make a new
    // one each time you are going to show it.
    
    // Display the autentication view.
    SEL finishedSel = @selector(viewController:finishedWithAuth:error:);
    
    GTMOAuth2ViewControllerTouch *viewController;
    
    
    viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                                              clientID:clientID
                                                          clientSecret:clientSecret
                                                      keychainItemName:keychainItemName
                                                              delegate:self
                                                      finishedSelector:finishedSel];
    
    // You can set the title of the navigationItem of the controller here, if you
    // want.
    
    // If the keychainItemName is not nil, the user's authorization information
    // will be saved to the keychain. By default, it saves with accessibility
    // kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, but that may be
    // customized here. For example,
    //
    viewController.keychainItemAccessibility = kSecAttrAccessibleAlways;
    
    // During display of the sign-in window, loss and regain of network
    // connectivity will be reported with the notifications
    // kGTMOAuth2NetworkLost/kGTMOAuth2NetworkFound
    //
    // See the method signInNetworkLostOrFound: for an example of handling
    // the notification.
    
    // Optional: Google servers allow specification of the sign-in display
    // language as an additional "hl" parameter to the authorization URL,
    // using BCP 47 language codes.
    //
    // For this sample, we'll force English as the display language.
    NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"en", @"force", @"offline", nil]
                                                       forKeys:[NSArray arrayWithObjects:@"hl", @"approval_prompt", @"access_type", nil]];
    viewController.signIn.additionalAuthorizationParameters = params;
    
    // By default, the controller will fetch the user's email, but not the rest of
    // the user's profile.  The full profile can be requested from Google's server
    // by setting this property before sign-in:
    //
    //   viewController.signIn.shouldFetchGoogleUserProfile = YES;
    //
    // The profile will be available after sign-in as
    //
    //   NSDictionary *profile = viewController.signIn.userProfile;
    
    // Optional: display some html briefly before the sign-in page loads
    NSString *html = @"<html><body bgcolor=silver><div align=center>Loading sign-in page...</div></body></html>";
    viewController.initialHTMLString = html;
    
    NSLog(@"Pushing view controller...");
    //[[self navigationController] pushViewController:viewController animated:YES];
    [self presentModalViewController:viewController animated:YES];
    
    
}



- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    if (error != nil) {
        // Authentication failed (perhaps the user denied access, or closed the
        // window before granting access)
        NSLog(@"Authentication error: %@", error);
        NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // show the body of the server's authentication failure response
            NSString *str = [[[NSString alloc] initWithData:responseData
                                                   encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"%@", str);
        }
        
        self.auth = nil;
    } else {
        // Authentication succeeded
        //
        // At this point, we either use the authentication object to explicitly
        // authorize requests, like
        //
        //  [auth authorizeRequest:myNSURLMutableRequest
        //       completionHandler:^(NSError *error) {
        //         if (error == nil) {
        //           // request here has been authorized
        //         }
        //       }];
        //
        // or store the authentication object into a fetcher or a Google API service
        // object like
        //
        //   [fetcher setAuthorizer:auth];
        
        [self dismissModalViewControllerAnimated:YES];
        //[viewController removeFromParentViewController];
        
        // save the authentication object
        self.auth = auth;
        
        NSLog(@"Signed in!!");
    }
    
    //[self updateUI];
}



- (void)signOut {
    if ([self.auth.serviceProvider isEqual:kGTMOAuth2ServiceProviderGoogle]) {
        // remove the token from Google's servers
        [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.auth];
    }
    
    // remove the stored Google authentication from the keychain, if any
    //[GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    
    // Discard our retained authentication object.
    self.auth = nil;
    
    //[self updateUI];
}

- (BOOL)isSignedIn {
    BOOL isSignedIn = self.auth.canAuthorize;
    return isSignedIn;
}

- (BOOL)shouldSaveInKeychain {
    return true;
    // Could do the below to allow a toggle for the user to choose whether or not to use the keychain (stay logged in)
    /*NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL flag = [defaults boolForKey:kShouldSaveInKeychainKey];
    NSLog(@"shouldSaveInKeychain? %i", flag);
    return flag;*/
}


- (GDataServiceGoogleDocs *)docsService {
    
    static GDataServiceGoogleDocs* service = nil;
    
    if (!service) {
        service = [[GDataServiceGoogleDocs alloc] init];
        
        [service setShouldCacheResponseData:YES];
        [service setServiceShouldFollowNextLinks:YES];
        [service setIsServiceRetryEnabled:YES];
    }
    
    return service;
}


// get a spreadsheet service object with the current username/password
//
// A "service" object handles networking tasks.  Service objects
// contain user authentication information as well as networking
// state information (such as cookies and the "last modified" date for
// fetched data.)

- (GDataServiceGoogleSpreadsheet *)spreadsheetService {
    
    static GDataServiceGoogleSpreadsheet* service = nil;
    
    if (!service) {
        service = [[GDataServiceGoogleSpreadsheet alloc] init];
        
        [service setShouldCacheResponseData:YES];
        [service setServiceShouldFollowNextLinks:YES];
    }
    
    return service;
}


// begin retrieving the list of the user's docs
- (void)fetchDocList {
    
    //[self setDocListFeed:nil];
    //[self setDocListFetchError:nil];
    //[self setDocListFetchTicket:nil];
    
    if ([self.auth canAuthorize]) {
        NSLog(@"Can authorize");
    } else {
        NSLog(@"Cannot authorize");
    }
    
    GDataServiceGoogleDocs *service = [self docsService];
    [service setAuthorizer:self.auth];
    GDataServiceTicket *ticket;
    
    // Fetching a feed gives us 25 responses by default.  We need to use
    // the feed's "next" link to get any more responses.  If we want more
    //than 25
    // at a time, instead of calling fetchDocsFeedWithURL, we can create
    //a
    // GDataQueryDocs object, as shown here.
    
    NSURL *feedURL = [GDataServiceGoogleDocs docsFeedURL];
    
    GDataQueryDocs *query = [GDataQueryDocs
                             documentQueryWithFeedURL:feedURL];
    [query setTitleQuery:@"2012 Home Purchases"];
    [query setIsTitleQueryExact:TRUE];
    
    [query setMaxResults:1000];
    [query setShouldShowFolders:YES];
    
    NSLog(@"Fetching feed");
    ticket = [service fetchFeedWithQuery:query
                                delegate:self
              
                       didFinishSelector:@selector(docListFetchTicket:finishedWithFeed:error:)];
    
    //[self setDocListFetchTicket:ticket];
    
    // update our metadata entry for this user
    //[self fetchMetadataEntry];
    
}

// docList list fetch callback
- (void)docListFetchTicket:(GDataServiceTicket *)ticket
          finishedWithFeed:(GDataFeedDocList *)feed
                     error:(NSError *)error {
    
    NSLog(@"Got feed!");
    if (error) {
        NSLog(@"...but got an error :(");
        NSLog(@"%@",[error localizedDescription]);
        NSLog(@"%@", error);
    }
    
    
    // get the docList entry's title, and the kind of document
    GDataEntryDocBase *doc = [feed entryAtIndex:0];
    
    NSString *docKind = @"unknown";
    
    // the kind category for a doc entry includes a label like "document"
    // or "spreadsheet"
    NSArray *categories;
    categories = [GDataCategory categoriesWithScheme:kGDataCategoryScheme
                                      fromCategories:[doc categories]];
    if ([categories count] >= 1) {
        docKind = [[categories objectAtIndex:0] label];
    }
    
    // mark if the document is starred
    if ([doc isStarred]) {
        const UniChar kStarChar = 0x2605;
        docKind = [NSString stringWithFormat:@"%C, %@", kStarChar, docKind];
    }
    
    NSString *displayStr = [NSString stringWithFormat:@"%@ (%@)",
                            [[doc title] stringValue], docKind];
    NSLog(@"%@", displayStr);
    
    
    
    //this part came from fetchSelectedSpreadsheet in the example project
    GDataEntrySpreadsheetDoc *spreadsheet = (GDataEntrySpreadsheetDoc*)doc;
    NSURL *feedURL = [[spreadsheet worksheetsLink] URL];
    if (feedURL) {
                
        GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
        [service setAuthorizer:self.auth];
        [service fetchFeedWithURL:feedURL
                         delegate:self
                didFinishSelector:@selector(worksheetsTicket:finishedWithFeed:error:)];
        //[self updateUI];
    }
    
    //[self setDocListFeed:feed];
    //[self setDocListFetchError:error];
    //[self setDocListFetchTicket:nil];
    
    //[self updateUI];
    
} 

// fetch worksheet feed callback
- (void)worksheetsTicket:(GDataServiceTicket *)ticket
        finishedWithFeed:(GDataFeedWorksheet *)feed
                   error:(NSError *)error {
    NSLog(@"Got worksheet!");
    if (error) {
        NSLog(@"But had error :( %@", error);
    }
    mWorksheetFeed = feed;
    GDataEntryWorksheet *worksheet = [feed entryAtIndex:0];
    
    // Fetch cells to get the column headers
    NSURL *feedURL = [[worksheet cellsLink] URL];
    
    GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
    [service fetchFeedWithURL:feedURL
                     delegate:self
            didFinishSelector:@selector(cellsTicket:finishedWithFeed:error:)];
 
    
    /* This works to fetch the list feed, which we may not need to do to be able to post. seems like all we use from that is [[list postLink] URL]
    NSURL *feedURL = [worksheet listFeedURL]; //or could use [[worksheet cellsLink] URL]; for individual cells
    cellFeedURL = feedURL;// [[feed postLink] URL];
    
    if (feedURL) {
        
        GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
        [service fetchFeedWithURL:feedURL
                         delegate:self
                didFinishSelector:@selector(entriesTicket:finishedWithFeed:error:)];
    }
     */

}

- (void)entriesTicket:(GDataServiceTicket *)ticket
     finishedWithFeed:(GDataFeedBase *)feed
                error:(NSError *)error {
    
    NSLog(@"Got entries (list) feed!");
    // entry fetch result or selected item
    if (error) {
        NSLog(@"But had error :( %@", error);
    } else {
        // attempting lists again. success!.
        GDataFeedSpreadsheetList* list = (GDataFeedSpreadsheetList*)feed;
        
        GDataEntrySpreadsheetList *rowEntry = [GDataEntrySpreadsheetList listEntry];
        [rowEntry setCustomElement:[GDataSpreadsheetCustomElement elementWithName:@"price" stringValue:@"$test"]];
        [rowEntry setCustomElement:[GDataSpreadsheetCustomElement elementWithName:@"description" stringValue:@"test description"]];
        [rowEntry setCustomElement:[GDataSpreadsheetCustomElement elementWithName:@"datepurchased" stringValue:@"test date"]];
        [rowEntry setCustomElement:[GDataSpreadsheetCustomElement elementWithName:@"notes" stringValue:@"test note"]];
        [rowEntry setCustomElement:[GDataSpreadsheetCustomElement elementWithName:@"receipt" stringValue:@"test receipt"]];
        
        NSLog(@"Created row: %@", rowEntry);
        
        GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
        NSLog(@"Adding a row using url %@", [[list postLink] URL]);
        
        [service fetchEntryByInsertingEntry:rowEntry
                                 forFeedURL:[[list postLink] URL]
                                   delegate:self
                          didFinishSelector:@selector
         (addObjectsTicket:finishedWithEntry:error:)
         ];
        
        /*// copying the first row (works!)
         GDataFeedSpreadsheetList* list = (GDataFeedSpreadsheetList*)feed;
         
         GDataEntrySpreadsheetList *rowEntry = [list entryAtIndex:0];
         
         NSLog(@"Found row: %@", rowEntry);
         
         GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
         NSLog(@"Adding a row using url %@", [[list postLink] URL]);
         
         [service fetchEntryByInsertingEntry:rowEntry
         forFeedURL:[[list postLink] URL]
         delegate:self
         didFinishSelector:@selector
         (addObjectsTicket:finishedWithEntry:error:)
         ];
         */
        /*
         //working with lists: but not working :(
         GDataFeedSpreadsheetList* list = (GDataFeedSpreadsheetList*)feed;
         
         GDataEntrySpreadsheetList *rowEntry = [GDataEntrySpreadsheetList
         listEntry];
         GDataSpreadsheetCustomElement *obj1 = [GDataSpreadsheetCustomElement
         elementWithName:@"Price"
         stringValue:@"Test Price!"];
         GDataSpreadsheetCustomElement *obj2 = [GDataSpreadsheetCustomElement
         elementWithName:@"Description"
         stringValue:@"test description"];
         GDataSpreadsheetCustomElement *obj3 = [GDataSpreadsheetCustomElement
         elementWithName:@"notes"
         stringValue:@"test note"];
         GDataSpreadsheetCustomElement *obj4 = [GDataSpreadsheetCustomElement
         elementWithName:@"SomethingReceipt"
         stringValue:@"test x"];
         NSArray* array = [NSArray arrayWithObjects:obj1, obj2, obj3, obj4, nil];
         [rowEntry setCustomElements:array];
         
         GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
         NSLog(@"Adding a row using url %@", [[list postLink] URL]);
         [service fetchEntryByInsertingEntry:rowEntry
         forFeedURL:[[list postLink] URL]
         delegate:self
         didFinishSelector:@selector
         (addObjectsTicket:finishedWithEntry:error:)
         ];
         */
        
        /*// working with cells:
         for(GDataEntryBase *entry in [feed entries]){ //= [feed entryAtIndex:1];
         
         if (entry) {
         
         // Posting Changes
         GDataEntrySpreadsheetCell *cellEntry = (GDataEntrySpreadsheetCell*)entry;
         GDataSpreadsheetCell *cell = [cellEntry cell];
         
         NSLog(@"Entry %i, %i: %@", cell.row, cell.column, [cell description]);
         
         
         [cell setInputString:@"Updated again!"];
         
         //NSLog(@"FEED %@" , [[feed entries] objectAtIndex:0]);
         
         NSURL *feedURL = cellFeedURL;
         
         GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
         ticket = [service fetchEntryByInsertingEntry:entry
         forFeedURL:feedURL
         delegate:nil
         didFinishSelector:nil];
         
         }
         }*/
        
    }
}



// fetch entries callback
- (void)cellsTicket:(GDataServiceTicket *)ticket
     finishedWithFeed:(GDataFeedBase *)feed
                error:(NSError *)error {
    
    NSLog(@"Got entries (cells) feed!");
    // entry fetch result or selected item
    if (error) {
        NSLog(@"But had error :( %@", error);
    } else {
        self.headers = [NSMutableArray array]; 
        for(GDataEntryBase *entry in [feed entries]){
            if (entry) {
                // Posting Changes
                GDataEntrySpreadsheetCell *cellEntry = (GDataEntrySpreadsheetCell*)entry;
                GDataSpreadsheetCell *cell = [cellEntry cell];
                
                NSLog(@"Entry %i, %i: %@", cell.row, cell.column, [cell description]);
                if (cell.row > 1) {
                    NSLog(@"Done with header. Breaking");
                    break;
                }
                [self.headers addObject:[cell inputString]];
            }
        }
    }
    
    [self updateUI];
}


- (void)addObjectsTicket:(GDataServiceTicket *)ticket
       finishedWithEntry:(GDataFeedBase *)feed 
                   error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error updating spreadsheet: %@", error);
    } else {
        NSLog(@"Updated spreadsheet!");
    }
    
}





- (void)sendToGoogle {
    NSLog(@"Sending to Google");
    [self fetchDocList];
    
    
}


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
    
    self.headers = [[NSMutableArray alloc] initWithObjects:@"Price", @"Longer Header With Extra Words. Oh so many words.", nil];
    
    NSLog(@"View did load, so logging in");
    [self signIn];
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
        ALAssetsLibrary* assetslibrary = [[[ALAssetsLibrary alloc] init] autorelease];
        [assetslibrary assetForURL:asseturl 
                       resultBlock:resultblock
                      failureBlock:failureblock];
    }


    
    
    /*UIImage *image = [info 
                      objectForKey:UIImagePickerControllerOriginalImage];
    
    imageView.image = image;*/

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
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
