//
//  GoogleManager.h
//  WriteOff
//
//  Created by Mike Miller on 5/24/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTMOAuth2Authentication;
@class GDataServiceGoogleDocs;
@class GTMOAuth2ViewControllerTouch;
@class GDataFeedDocList;
@class GDataServiceTicket;

@interface GoogleManager : NSObject
{
    UIViewController *mOwner; // We use the owner to launch the modal dialog asking the user to log in, and to notify when the document fetch is finished
    GTMOAuth2Authentication *mAuth;
    
    SEL mDidFinishSignInSelector;
    SEL mDidFetchSelector;
    GDataFeedDocList *mDocListFeed;
    
    //NSMutableArray *mSpreadsheets;
}

@property (nonatomic, strong) GTMOAuth2Authentication *auth;
@property (nonatomic, copy) NSArray *spreadsheets;

- (GDataServiceGoogleDocs *)docsService;

- (void)signIn:(UIViewController *)viewController
didFinishSignInSelector:(SEL)finishedSignInSelector;
- (void)signOut;
- (BOOL)isSignedIn;


- (void)fetchSpreadsheets: (SEL)fetchedSelector;
- (void)fetchSingleSpreadsheet:(NSURL *)url 
               fetchedSelector:(SEL)fetched;

- (BOOL)shouldSaveInKeychain;

@end
