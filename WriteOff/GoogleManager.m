//
//  GoogleManager.m
//  WriteOff
//
//  Created by Mike Miller on 5/24/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


#import "GoogleManager.h"

#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2SignIn.h"
#import "GData.h"
#import "GDataServiceGoogleDocs.h"

static NSString *const kKeychainItemName = @"WriteOff: Docs and Spreadsheets";
static NSString *const kShouldSaveInKeychainKey = @"shouldSaveInKeychain";

static NSString *const kClientIDKey = @"970839269491.apps.googleusercontent.com";
static NSString *const kClientSecretKey = @"eaTahaI9Wa0h0OFMHd-h48O6";// pre-assigned by service. Found here: https://code.google.com/apis/console/



@implementation GoogleManager {
    // We re-declare this as an NSMutableArray here so we can manipulate it within this class. External classes see the immutable NSArray declared in the header.
    NSMutableArray *_spreadsheets;
}

@synthesize auth = _auth;
@synthesize spreadsheets = _spreadsheets;


- (id)init {
    self = [super init];
    if (self) {
        _spreadsheets = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)signIn:(UIViewController *)viewController
didFinishSignInSelector:(SEL)finishedSignInSelector
{
    mOwner = viewController;
    mDidFinishSignInSelector = finishedSignInSelector;
    NSLog(@"Signing in...");
    
    
    
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
            
            // Notify our owner that we signed in successfully
            [mOwner performSelector:mDidFinishSignInSelector];
            
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
    
    GTMOAuth2ViewControllerTouch *authViewController;
    
    
    authViewController = [GTMOAuth2ViewControllerTouch controllerWithScope:scope
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
    authViewController.keychainItemAccessibility = kSecAttrAccessibleAlways;
    
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
    authViewController.signIn.additionalAuthorizationParameters = params;
    
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
    authViewController.initialHTMLString = html;
    
    NSLog(@"Pushing view controller...");
    //[[self navigationController] pushViewController:viewController animated:YES];
    [mOwner presentModalViewController:authViewController animated:YES];
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
            NSString *str = [[NSString alloc] initWithData:responseData
                                                  encoding:NSUTF8StringEncoding];
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
        
        [mOwner dismissModalViewControllerAnimated:YES];
        //[viewController removeFromParentViewController];
        
        // save the authentication object
        self.auth = auth;
        
        NSLog(@"Signed in!!");
        
        // Notify our owner that we signed in successfully
        [mOwner performSelector:mDidFinishSignInSelector];
        
    }
    
    //[self updateUI];
}



- (void)signOut {
    if ([self.auth.serviceProvider isEqual:kGTMOAuth2ServiceProviderGoogle]) {
        // remove the token from Google's servers
        [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.auth];
    }
    
    NSLog(@"Signing out!");
    
    // remove the stored Google authentication from the keychain, if any
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    
    // Discard our retained authentication object.
    self.auth = nil;
    
    //[self updateUI];
}

- (BOOL) isSignedIn {
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

// docList list fetch callback
- (void)spreadsheetsFetchTicket:(GDataServiceTicket *)ticket
               finishedWithFeed:(GDataFeedDocList *)feed
                          error:(NSError *)error{
    
    NSLog(@"Got feed!");
    if (error) {
        NSLog(@"...but got an error :(");
        NSLog(@"%@",[error localizedDescription]);
        NSLog(@"%@", error);
    }
    
    // Cache the feed
    mDocListFeed = feed;
    
    
    self.spreadsheets = [NSMutableArray array];
    
    for (GDataEntryBase *doc in feed.entries) {        
        NSString *displayStr = [NSString stringWithFormat:@"%@",
                                [[doc title] stringValue]];
        
        
        /*NSArray *parentLinks = [doc parentLinks];        
        NSLog(@"Loading all spreadsheets, number of parentLinks: %i", parentLinks.count);
        for (id item in parentLinks) {
            NSLog(@"Got an item: %@", item);
        }*/

        
        GDataEntrySpreadsheet *spreadsheet = (GDataEntrySpreadsheet *)doc;
        if (spreadsheet) {
            NSLog(@"Found doc %@", displayStr);
            // This should work. I should be able to do this, but it doesn't work... [(NSMutableArray *)_spreadsheets addObject:spreadsheet];
            NSMutableArray *s = [self mutableArrayValueForKey:@"spreadsheets"];
            [s addObject:spreadsheet];

            NSURL *url = [[spreadsheet spreadsheetLink] URL];
            NSLog(@"  spreadsheetLink: %@", [url absoluteString]);
            url = [[spreadsheet selfLink] URL];
            NSLog(@"  selfLink: %@", [url absoluteString]);
            url = [[spreadsheet feedLink] URL];
            NSLog(@"  feedLink: %@", [url absoluteString]);
            url = [[spreadsheet HTMLLink] URL];
            NSLog(@"  HTMLLink: %@", [url absoluteString]);
            
        }
    }
    
    // Notify our owner that we finished fetching
    [mOwner performSelector:mDidFetchSelector];
    
} 

// begin retrieving the list of the user's docs
- (void)fetchSpreadsheets:(SEL)fetchedSelector {
    
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
    mDidFetchSelector = fetchedSelector;
    
    // Fetching a feed gives us 25 responses by default.  We need to use
    // the feed's "next" link to get any more responses.  If we want more
    //than 25
    // at a time, instead of calling fetchDocsFeedWithURL, we can create
    //a
    // GDataQueryDocs object, as shown here.
    
    
    /* This queries for a specific title
    NSURL *feedURL = [GDataServiceGoogleDocs docsFeedURL];
    GDataQueryDocs *query = [GDataQueryDocs
                             documentQueryWithFeedURL:feedURL];
    [query setTitleQuery:titleQuery];
    [query setIsTitleQueryExact:TRUE];
    [query setMaxResults:1000];
    [query setShouldShowFolders:YES];
     
    NSLog(@"Fetching feed");
    // Cache the didFetch selector so we can call it when fetching is complete.
    ticket = [service fetchFeedWithQuery:query
    delegate:self
    didFinishSelector:@selector(docListFetchTicket:finishedWithFeed:error:)
    ];

    */
    
    NSURL *feedURL = [NSURL URLWithString:kGDataGoogleSpreadsheetsPrivateFullFeed];
    ticket = [service fetchFeedWithURL:feedURL
                     delegate:self
            didFinishSelector:@selector(spreadsheetsFetchTicket:finishedWithFeed:error:)];

        
    //[self setDocListFetchTicket:ticket];
    
    // update our metadata entry for this user
    //[self fetchMetadataEntry];
}


//delete this
/*
- (void)refetchTicket:(GDataServiceTicket *)ticket
         finishedWithFeed:(GDataFeedDocList *)feed
                    error:(NSError *)error{
    
    
    NSLog(@"REFETCHED DOC");
    
    
    for (GDataEntryDocBase *doc in feed.entries) {        
        NSString *displayStr = [NSString stringWithFormat:@"%@",
                                [[doc title] stringValue]];
        NSLog(@"found: %@", displayStr);
        
        NSArray *parentLinks = [doc parentLinks];        
        NSLog(@"refetched parentLinks: %i", parentLinks.count);
        for (id item in parentLinks) {
            NSLog(@"Got an item: %@", item);
        }
    }
        
}*/

// single doc fetch callback
- (void)singleSpreadsheetFetchTicket:(GDataServiceTicket *)ticket
                    finishedWithSpreadsheet:(GDataEntrySpreadsheet *)spreadsheet
                               error:(NSError *)error{
    
    NSLog(@"Got single spreadsheet feed!");
    if (error) {
        NSLog(@"...but got an error :(");
        NSLog(@"%@",[error localizedDescription]);
        NSLog(@"%@", error);
    }
    
    // Cache the feed
    //mDocListFeed = feed;
    
    self.spreadsheets = [NSMutableArray array];
    if (spreadsheet) {
        NSString *displayStr = [NSString stringWithFormat:@"%@",
                                [[spreadsheet title] stringValue]];
        NSLog(@"Found doc %@", displayStr);
        
        NSArray *links = [spreadsheet links];
        NSLog(@"Number of links: %i", links.count);
        for (id item in links) {
            NSLog(@"Got an item: %@", item);
        }
        /*
        // fetch it again but as a GDataEntryDoc to get the parent list. mikem: moved this into SpreadsheetManager
        GDataServiceGoogleDocs *service = [self docsService];
        [service setAuthorizer:self.auth];
        GDataServiceTicket *ticket;           
        // This queries for a specific title
        NSURL *feedURL = [GDataServiceGoogleDocs docsFeedURL];
        GDataQueryDocs *query = [GDataQueryDocs
        documentQueryWithFeedURL:feedURL];
        //[query set
        [query setFeedURL:[spreadsheet.selfLink URL]];
        //[query setTitleQuery:[[spreadsheet title] stringValue]];
        //[query setIsTitleQueryExact:TRUE];
        [query setMaxResults:1000];
        [query setShouldShowFolders:NO];
        
        
        NSString *userName = [service username];
        NSArray *categories = [spreadsheet categories];
        // See if there's an intervening folder.
        NSString *folderScheme = [kGDataNamespaceDocuments
                                  stringByAppendingFormat:@"/folders/%@",
                                  userName];
        NSLog(@"folder scheme: %@", folderScheme);
        NSArray *folders = [GDataCategory categoriesWithScheme:folderScheme
                                                fromCategories:categories];
        if (folders) {
            NSLog(@"Found %i folders", folders.count);
        } else {
            NSLog(@"no folders");
        }
        if (folders && [folders count]) {
            NSString *label = [[folders objectAtIndex:0] label];
            NSLog(@"  %@", label);
        }
        */
             /*              
        NSLog(@"Refetching feed");   ////mikem: refetching feed doesn't work. i need to find the right url to use. it works when searhing by name.
        
        ticket = [service fetchFeedWithURL:[spreadsheet.selfLink URL] delegate:self didFinishSelector:@selector(refetchTicket:finishedWithFeed:error:)];
        */
        //ticket = [service fetchFeedWithQuery:query
        //delegate:self
        //didFinishSelector:@selector(refetchTicket:finishedWithFeed:error:)
        //];
        
        
        /*
        GDataEntrySpreadsheetDoc *doc = spreadsheet;
        NSArray *parentLinks = [doc parentLinks];
        NSLog(@"Number of parentLinks: %i", parentLinks.count);
        for (id item in parentLinks) {
            NSLog(@"Got an item: %@", item);
        }
        NSArray *parentHrefs = [parentLinks valueForKey:@"href"];
        NSLog(@"Number of parentHrefs: %i", parentHrefs.count);
        for (id item in parentHrefs) {
            NSLog(@"Got an item: %@", item);
        }
        */
        // This should work. I should be able to do this, but it doesn't work... [(NSMutableArray *)_spreadsheets addObject:spreadsheet];
        NSMutableArray *s = [self mutableArrayValueForKey:@"spreadsheets"];
        [s addObject:spreadsheet];
    }
    
    // Notify our owner that we finished fetching
    [mOwner performSelector:mDidFetchSelector];
}


// begin retrieving the list of the user's docs
- (void)fetchSingleSpreadsheet:(NSURL *)url 
               fetchedSelector:(SEL)fetched {
    
    if ([self.auth canAuthorize]) {
        NSLog(@"Can authorize");
    } else {
        NSLog(@"Cannot authorize");
    }
    
    GDataServiceGoogleDocs *service = [self docsService];
    [service setAuthorizer:self.auth];
    GDataServiceTicket *ticket;
    mDidFetchSelector = fetched; 

    NSLog(@"Fetching feed at url %@", url);
    ticket = [service fetchFeedWithURL:url 
                              delegate:self 
                     didFinishSelector:@selector(singleSpreadsheetFetchTicket:finishedWithSpreadsheet:error:)];
    
    /*ticket = [service fetchFeedWithQuery:query
    delegate:self
    didFinishSelector:@selector(docListFetchTicket:finishedWithFeed:error:)
    ];*/
     
     
    /* this fetches all spreadsheets
    NSURL *feedURL = [NSURL URLWithString:kGDataGoogleSpreadsheetsPrivateFullFeed];
    ticket = [service fetchFeedWithURL:feedURL
                              delegate:self
                     didFinishSelector:@selector(spreadsheetsFetchTicket:finishedWithFeed:error:)];
     */
}







@end
