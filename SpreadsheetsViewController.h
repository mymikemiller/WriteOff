//
//  SpreadsheetsViewController.h
//  WriteOff
//
//  Created by Mike Miller on 5/28/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleManager.h"
#import "AddRowViewController.h"

@interface SpreadsheetsViewController : UITableViewController <ImageCropViewControllerDelegate>


@property (nonatomic, strong) GoogleManager *googleManager;


- (void)spreadsheetsFetched;

@end
