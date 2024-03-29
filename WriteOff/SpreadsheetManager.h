//
//  SpreadsheetManager.h
//  WriteOff
//
//  Created by Mike Miller on 5/24/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <Foundation/Foundation.h>


@class GDataServiceGoogleDocs;
@class GDataEntrySpreadsheetDoc;
@class GDataFeedWorksheet;
@class GDataServiceGoogleSpreadsheet;
@class GoogleManager;
@class AddRowViewController;
@class GDataLink;

@interface SpreadsheetManager : NSObject
{
    GDataFeedWorksheet *mWorksheetFeed;
    
    //NSURL *cellFeedURL;
    NSURL *mListFeedURL;
    
    //NSArray* headerToValueMap; // An array of 2-element NSMutableArrays of NSStrings, the first being the header (formatted as it is in the spreadsheet, not lower-cased and spaces-removed). The second is the current value in the associated text box, updated as soon as the user commits a change to the text.
    
    SEL mFetchedSelector;
    UIViewController *mObjectToNotifyWhenHeadersFetched;
    SEL mSpreadsheetUploadedSelector;
    UIViewController *mObjectToNotifyWhenSpreadsheetUploaded;
}

- (id)initWithSpreadsheet:(GDataEntrySpreadsheetDoc *)theSpreadsheet
        andGoogleManager:(GoogleManager *)googleManager;
- (void)fetchHeaders:(SEL)fetchedSelector
        notifyObjectWhenDone:(UIViewController *)objectToNotify;

- (void)uploadToGoogle:(SEL)spreadsheetUploadedSelector
   notifyObjectWhenDone:(UIViewController *)objectToNotify;

- (GDataServiceGoogleSpreadsheet *)spreadsheetService;

- (NSString *)spreadsheetTitle;

@property (nonatomic, strong) GDataEntrySpreadsheetDoc *spreadsheet;
@property (nonatomic, strong) GoogleManager *googleManager;
@property (nonatomic, strong) GDataLink *parentFolderLink;
@property (nonatomic, copy) NSArray *headerToValueMap; // See mHeaderToValueMap


@end
