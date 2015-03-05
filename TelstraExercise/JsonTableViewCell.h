//
//  JsonTableViewCell.h

//  Created by ramya on 03.03/15.
//  Copyright (c) 2015 cognizant. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Feeds;

@interface JsonTableViewCell : UITableViewCell

@property(nonatomic,retain) UIImageView *feedImage;

-(void)loadDataInCell:(Feeds *)feeds;
-(void)loadDataInitialCell;

@end
