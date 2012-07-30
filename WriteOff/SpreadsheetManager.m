//
//  SpreadsheetManager.m
//  WriteOff
//
//  Created by Mike Miller on 5/24/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


#import "SpreadsheetManager.h"

#import "GDataServiceGoogleSpreadsheet.h"
#import "GDataEntryWorksheet.h"
#import "GDataFeedSpreadsheetList.h"
#import "GDataEntrySpreadsheetList.h"
#import "GDataEntrySpreadsheetCell.h"
#import "GDataSpreadsheetCell.h"
#import "GDataEntrySpreadsheetDoc.h"
#import "GDataSpreadsheetCustomElement.h"
#import "GDataFeedWorksheet.h"
#import "GDataEntrySpreadsheet.h"
#import "GDataServiceGoogleDocs.h"
#import "GDataQueryDocs.h"
#import "GDataLink.h"

#import "AddRowViewController.h"

#import "GoogleManager.h"

@implementation SpreadsheetManager {
    // We re-declare this as an NSMutableArray here so we can manipulate it within this class. External classes see the immutable NSArray declared in the header.
    NSMutableArray *_headerToValueMap;
}

@synthesize spreadsheet = _spreadsheet;
@synthesize headerToValueMap = _headerToValueMap;
@synthesize googleManager = _googleManager;
@synthesize parentFolderLink;

- (void)spreadsheetDocFetchTicket:(GDataServiceTicket *)ticket
                 finishedWithFeed:(GDataFeedDocList *)feed
                            error:(NSError *)error{
    
}


- (id)initWithSpreadsheet:(GDataEntrySpreadsheetDoc *)theSpreadsheet
         andGoogleManager:(GoogleManager *)theGoogleManager
{
    self = [super init];
    if (self) {
        NSLog(@"setting spreadsheet");
        
        
        self.spreadsheet = theSpreadsheet;
        self.googleManager = theGoogleManager;
        _headerToValueMap = [[NSMutableArray alloc] init];
        
        // Find the folder(s) the spreadsheet belongs to.
        
        /* This searches for a known folder
         GDataServiceGoogleDocs *service = [googleManager docsService];
         [service setAuthorizer:googleManager.auth];
         GDataServiceTicket *ticket;
         //This queries for a specific title
         NSURL *feedURL = [GDataServiceGoogleDocs docsFeedURL];
         GDataQueryDocs *query = [GDataQueryDocs
         documentQueryWithFeedURL:feedURL];
         [query setTitleQuery:@"testFolder"];
         [query setIsTitleQueryExact:TRUE];
         [query setMaxResults:1000];
         [query setShouldShowFolders:YES];
         [query setShouldShowFolders:YES];
         ticket = [service fetchFeedWithQuery:query
         delegate:self
         didFinishSelector:@selector(folderFetchTicket:finishedWithFeed:error:)
         ];*/
        
        GDataServiceGoogleDocs *service = [self.googleManager docsService];
        GDataServiceTicket *ticket;
        //This queries for a specific title
        NSURL *feedURL = [GDataServiceGoogleDocs docsFeedURL];
        GDataQueryDocs *query = [GDataQueryDocs
                                 documentQueryWithFeedURL:feedURL];
        [query setTitleQuery:[[self.spreadsheet title] stringValue]];
        [query setIsTitleQueryExact:TRUE];
        [query setMaxResults:1000];
        [query setShouldShowFolders:NO];
        ticket = [service fetchFeedWithQuery:query completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
            
            NSLog(@"FOUND DOC");
            
            //folderFeed = feed;
            
            for (GDataEntryDocBase *doc in feed.entries) {        
                NSString *displayStr = [NSString stringWithFormat:@"%@",
                                        [[doc title] stringValue]];
                NSLog(@"found: %@", displayStr);
                NSLog(@"Does this doc match?");
                NSLog(@"  spreadsheet: %@", self.spreadsheet.HTMLLink.href);
                NSLog(@"          doc: %@", doc.HTMLLink.href);
                
                NSString *spreadsheetHref = self.spreadsheet.HTMLLink.href;
                NSString *docHref = doc.HTMLLink.href;
                NSString *spreadsheetID;
                NSString *docID;
                
                NSRange range = [spreadsheetHref rangeOfString:@"=" options:NSBackwardsSearch];
                spreadsheetID = (range.location != NSNotFound) ?
                [spreadsheetHref substringFromIndex:(1 + range.location)] :
                spreadsheetHref;
                
                range = [docHref rangeOfString:@"=" options:NSBackwardsSearch];
                docID = (range.location != NSNotFound) ?
                [docHref substringFromIndex:(1 + range.location)] :
                docHref;
                
                NSLog(@"Found spreadsheetID %@", spreadsheetID);
                NSLog(@"Found         docID %@", docID);
                
                if (![docID isEqualToString:spreadsheetID]) {
                    // We found a doc that happens to have the same name. Skip it.
                    NSLog(@"Skipping");
                    continue;
                }
                
                NSLog(@"Found match");
                
                
                NSArray *parentLinks = [doc parentLinks];
                NSLog(@"Number of parentLinks: %i", parentLinks.count);
                for (GDataLink *item in parentLinks) {
                    NSLog(@"Got an item: %@", item);
                    
                    // Only items with titles are valid folders
                    if ([item title]) {
                        NSLog(@"FOUND FOLDER: %@", [item title]);
                        self.parentFolderLink = item;
                        
                        NSLog(@"href: %@", [item href]);
                        
                        // Only use the first folder. We may eventually want to give the user the choice of which folder to use.
                        return;
                    }
                }
            }
        }];
        /*ticket = [service fetchFeedWithQuery:query
                                    delegate:self
                           didFinishSelector:@selector(spreadsheetDocFetchTicket:finishedWithFeed:error:)
                  ];
        */

    }
    
    return self;
}


- (void)fetchHeaders:(SEL)fetchedSelector
notifyObjectWhenDone:(UIViewController *)objectToNotify {
    
    mFetchedSelector = fetchedSelector;
    mObjectToNotifyWhenHeadersFetched = objectToNotify;
    
    
    //this part came from fetchSelectedSpreadsheet in the example project
    
    GDataEntrySpreadsheet *s = (GDataEntrySpreadsheet *)self.spreadsheet;
    NSURL *feedURL = [s worksheetsFeedURL];
    if (feedURL) {
        
        GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
        [service setAuthorizer:self.googleManager.auth];
        [service fetchFeedWithURL:feedURL
                         delegate:self
                didFinishSelector:@selector(worksheetsTicket:finishedWithFeed:error:)];
    }
}

- (void)uploadToGoogle:(SEL)spreadsheetUploadedSelector
  notifyObjectWhenDone:(UIViewController *)objectToNotify {
    
    mSpreadsheetUploadedSelector = spreadsheetUploadedSelector;
    mObjectToNotifyWhenSpreadsheetUploaded = objectToNotify;
    
    // This works to fetch the list feed, which we may not need to do to be able to post. seems like all we use from that is [[list postLink] URL]
     //NSURL *feedURL = [worksheet listFeedURL]; //or could use [[worksheet cellsLink] URL]; for individual cells
     //cellFeedURL = feedURL;// [[feed postLink] URL];
     
     //if (feedURL) {
    NSLog(@"SpreadsheetManager attempting to upload.");
     
     GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
     [service fetchFeedWithURL:mListFeedURL
     delegate:self
     didFinishSelector:@selector(listTicket:finishedWithFeed:error:)];
     
     

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

- (NSString *)spreadsheetTitle {
    return [NSString stringWithFormat:@"%@", [[self.spreadsheet title] stringValue]];
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
    
    // Save this for later, when we want to update the list
    mListFeedURL = [[worksheet listFeedURL] copy];
    
    // Fetch cells to get the column headers
    NSURL *feedURL = [[worksheet cellsLink] URL];
    
    GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
    [service fetchFeedWithURL:feedURL
                     delegate:self
            didFinishSelector:@selector(cellsTicket:finishedWithFeed:error:)];

    
}

- (void)listTicket:(GDataServiceTicket *)ticket
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
        for (NSMutableArray *headerToValue in self.headerToValueMap) {
            NSString *headerInGoogleFormat = [[[headerToValue objectAtIndex:0] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSLog(@"%@ -> %@ (value: %@)", [headerToValue objectAtIndex:0], headerInGoogleFormat, [headerToValue objectAtIndex:1]);
            [rowEntry setCustomElement:[GDataSpreadsheetCustomElement elementWithName:headerInGoogleFormat stringValue:[headerToValue objectAtIndex:1]]];
        }
        
        NSLog(@"Created row: %@", rowEntry);
        
        GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
        NSLog(@"Adding a row using url %@", [[list postLink] URL]);
        
        [service fetchEntryByInsertingEntry:rowEntry
                                 forFeedURL:[[list postLink] URL]
                                   delegate:self
                          didFinishSelector:@selector
         (addObjectsTicket:finishedWithEntry:error:)
         ];

        
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
        self.headerToValueMap = [NSMutableArray array]; 
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
                NSMutableArray *headerToValue = [NSMutableArray arrayWithObjects:[cell inputString], @"", nil];
                // I should be able to do this, but it doesn't work: 
                //[_headerToValueMap addObject:headerToValue];
                
                NSMutableArray *m = [self mutableArrayValueForKey:@"headerToValueMap"];
                [m addObject:headerToValue];
            }
        }
    }
        
    // Only notify the view if it's visible.
    if (mObjectToNotifyWhenHeadersFetched.isViewLoaded && mObjectToNotifyWhenHeadersFetched.view.window) {
        NSLog(@"View is loaded, so notifying");
        [mObjectToNotifyWhenHeadersFetched performSelector:mFetchedSelector];
    } else {
        NSLog(@"View is not loaded. Not notifying.");
    }

    NSLog(@"No crash :)");
}


- (void)addObjectsTicket:(GDataServiceTicket *)ticket
       finishedWithEntry:(GDataFeedBase *)feed 
                   error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error updating spreadsheet: %@", error);
    } else {
        NSLog(@"Updated spreadsheet!");
        [mObjectToNotifyWhenSpreadsheetUploaded performSelector:mSpreadsheetUploadedSelector];
    }
}


@end
