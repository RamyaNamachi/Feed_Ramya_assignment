//
//  DropBoxContentViewController.h

//
//  Created by Ramya on 03/03/15.
//  Copyright (c) 2015 Cognizant. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OverViewModel;
@class RowModel;

@interface DropBoxContentViewController : UITableViewController

@property (nonatomic,retain) OverViewModel *data;

@property (nonatomic,retain) RowModel *newsRow;

@end

