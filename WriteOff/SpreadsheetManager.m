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


#import "AddRowViewController.h"

#import "GoogleManager.h"

@implementation SpreadsheetManager {
    // We re-declare this as an NSMutableArray here so we can manipulate it within this class. External classes see the immutable NSArray declared in the header.
    NSMutableArray *_headerToValueMap;
}

@synthesize spreadsheet = _spreadsheet;
@synthesize headerToValueMap = _headerToValueMap;
@synthesize googleManager = _googleManager;
@synthesize testing = _testing;

- (id)initWithSpreadsheet:(GDataEntrySpreadsheetDoc *)theSpreadsheet
         andGoogleManager:(GoogleManager *)theGoogleManager
{
    self = [super init];
    if (self) {
        NSLog(@"setting spreadsheet");
        
        
        self.spreadsheet = theSpreadsheet;
        self.googleManager = theGoogleManager;
        _headerToValueMap = [[NSMutableArray alloc] init];
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

    
    /* This works to fetch the list feed, which we may not need to do to be able to post. seems like all we use from that is [[list postLink] URL]
     NSURL *feedURL = [worksheet listFeedURL]; //or could use [[worksheet cellsLink] URL]; for individual cells
     cellFeedURL = feedURL;// [[feed postLink] URL];
     
     if (feedURL) {
     
     GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
     [service fetchFeedWithURL:feedURL
     delegate:self
     didFinishSelector:@selector(listTicket:finishedWithFeed:error:)];
     }
     */

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
                NSMutableArray *headerToValue = [NSMutableArray arrayWithObjects:[cell inputString], @"DEBUG_TEXT", nil];
                [_headerToValueMap addObject:headerToValue];
            }
        }
    }
    
    NSLog(@"Notifying object that we fetched cells. This might be where the crash is.");
    if (mObjectToNotifyWhenHeadersFetched) {
        NSLog(@"AddRow page exists");
    } else {
        NSLog(@"AddRow page doesn't exist!");
    }
    
    // Only notify the view if it's visible.
    
    if (mObjectToNotifyWhenHeadersFetched == nil) {
        NSLog(@"nil");
    } else {
        NSLog(@"not nil");
    }
    
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
    }
    
}


@end
