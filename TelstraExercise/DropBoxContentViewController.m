//
//  ViewController.m

//  Created by ramya on 03.03/15.
//  Main View controller to load the json data into tableview
//  Copyright (c) 2015 cognizant. All rights reserved.
//

#import "DropBoxContentViewController.h"

#import "OverViewModel.h"
#import "JsonTableViewCell.h"
#import "ImageDownloadClient.h"

#import "Feeds.h"
static NSString *CellIdentifier = @"Cell";

@interface DropBoxContentViewController ()

@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;
@property (nonatomic,retain) UIRefreshControl *refreshControl;


@end

@implementation DropBoxContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self downloadJsonData];
    // Do any additional setup after loading the view, typically from a nib.
    
    // An instance of UIrefreshview control is created.
    UIRefreshControl *refreshControl=[[UIRefreshControl alloc]initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100.0f)];
    self.refreshControl=refreshControl;
    [refreshControl release];
    [self.refreshControl addTarget:self action:@selector(reloadTable) forControlEvents:UIControlEventValueChanged];
    [self.tableView.tableHeaderView addSubview:self.refreshControl];
    
    [self.navigationItem setHidesBackButton:YES];
    
}

-(void)downloadJsonData{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *response = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/g41ldl6t0afw9dv/facts.json"]]; //use static string
        NSError *parseError = nil;
        NSMutableDictionary *jsonFeedDictionary = [[NSMutableDictionary alloc]init];
        NSString* string = [[[[NSString alloc] initWithData:response encoding:NSASCIIStringEncoding] stringByReplacingOccurrencesOfString:@"\t" withString:@""] stringByReplacingOccurrencesOfString:@"\0" withString:@""];
   
        response = [string dataUsingEncoding:NSUTF8StringEncoding];
        jsonFeedDictionary = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableContainers error:&parseError];
        if(!parseError){
           
            
            NSMutableArray *jsonArrayOfRowsFromDict = [[NSMutableArray alloc] init];
            
            
            for(NSDictionary *rowDict in [jsonFeedDictionary objectForKey:@"rows"]){
                //assign and reuse
                if(!([rowDict objectForKey:@"title"]==(id)[NSNull null] && [rowDict objectForKey:@"description"]==(id)[NSNull null]&& [rowDict objectForKey:@"imageHref"]==(id)[NSNull null])){
                    
                    Feeds *records = [[Feeds alloc] init];
                    if([records containsAllElements:rowDict]){
                        
                        [jsonArrayOfRowsFromDict addObject:records];
                    }
                }
            }
            self.data = [[OverViewModel alloc] initWithTitle:[jsonFeedDictionary objectForKey:@"title"] andFeeds:jsonArrayOfRowsFromDict];
            [self.navigationItem setTitle:self.data.newsTitle];
         
            
            dispatch_sync(dispatch_get_main_queue(), ^{
               if([self.refreshControl isRefreshing])
                   [self.refreshControl endRefreshing];
                [self.tableView reloadData];
                
            });
        }
        else{
            [self showErrorAlert:parseError];
        }
    });
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark -
#pragma mark TableView Datasource Methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([[self.data feeds] count]==0)
        return 1;
    else
        return [[self.data feeds] count]; // The number of rows is the feeds count which is got from the response
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return [self basicCellAtIndexPath:indexPath];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return [self heightForBasicCellAtIndexPath:indexPath];
    
}

#pragma mark -
#pragma mark Orientation handlers

-(BOOL)shouldAutorotate
{
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.tableView reloadData];
}



#pragma mark -
#pragma mark Custom Methods

/*
 
 This function is used to create or dequeue the instance of the cell
 and load the label and the imageview in the cell with data from the
 'Feed' object
 
 */

- (JsonTableViewCell *)basicCellAtIndexPath:(NSIndexPath *)indexPath {
    
    
    JsonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier] ;
    
    if (!cell) {
        cell = [[[JsonTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease]   ;
    }
    
    if([[self.data feeds]count]==0){
        [cell loadDataInitialCell];
        
    }
    else{
        
        
        
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        
        [cell loadDataInCell:[self.data.feeds objectAtIndex:indexPath.row]];
        
                if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
                {
                    if(![[[self.data.feeds objectAtIndex:indexPath.row] feedsImage] isEqualToString:@""]){
                        [self startIconDownload:[self.data.feeds objectAtIndex:indexPath.row] forIndexPath:indexPath];
                    }
                    else{
                        [cell.feedImage  setImage:[UIImage imageNamed:@""]];
                    }
                    
                }
                else
                {
                    [cell.feedImage setImage: [(Feeds*)[self.data.feeds objectAtIndex:indexPath.row] appIcon]];
                }

        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    return cell ;
    
}




#pragma mark - Table cell image support

// -------------------------------------------------------------------------------
//	startIconDownload:forIndexPath:
// -------------------------------------------------------------------------------
- (void)startIconDownload:(Feeds *)appRecord forIndexPath:(NSIndexPath *)indexPath
{
    ImageDownloadClient *iconDownloader = (self.imageDownloadsInProgress)[indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[ImageDownloadClient alloc] init];
        iconDownloader.appRecord = appRecord;
        [iconDownloader setCompletionHandler:^{
            
            JsonTableViewCell *cell = (JsonTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            
            // Display the newly loaded image
            [cell.feedImage setImage:appRecord.appIcon];
            
            // Remove the IconDownloader from the in progress list.
            // This will result in it being deallocated.
            [self.imageDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        (self.imageDownloadsInProgress)[indexPath] = iconDownloader;
        [iconDownloader startDownload];
    }
}

// -------------------------------------------------------------------------------
//	loadImagesForOnscreenRows
//  This method is used in case the user scrolled into a set of cells that don't
//  have their app icons yet.
// -------------------------------------------------------------------------------
- (void)loadImagesForOnscreenRows
{
    if (self.data.feeds.count > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            Feeds *appRecord = (self.data.feeds)[indexPath.row];
            if(![appRecord.feedsImage isEqualToString:@""]){
                
                if (!appRecord.appIcon)
                    // Avoid the app icon download if the app already has an icon
                {
                    [self startIconDownload:appRecord forIndexPath:indexPath];
                }
            }
        }
    }
}


#pragma mark - UIScrollViewDelegate

// -------------------------------------------------------------------------------
//	scrollViewDidEndDragging:willDecelerate:
//  Load images for all onscreen rows when scrolling is finished.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self loadImagesForOnscreenRows];
    }
}

// -------------------------------------------------------------------------------
//	scrollViewDidEndDecelerating:scrollView
//  When scrolling stops, proceed to load the app icons that are on screen.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}


/*
 
 This function is suposed to return the dynamic height of the
 cells based on their content
 
 */


- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath {
    
    JsonTableViewCell *sizingCell = [self basicCellAtIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}


/*
 
 The height of the tableview cell is calculated in this method.
 Since autolayout is used 'systemLayoutSizeFittingSize' method is
 used to find the size of tableview cell
 
 */
- (CGFloat)calculateHeightForConfiguredSizingCell:(JsonTableViewCell *)sizingCell {
    
    [sizingCell setFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(sizingCell.bounds))];
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height + 1.0f; // Add 1.0f for the cell separator height
}

/*
 
 This function is called to make the service call
 and reload the table view.
 
 */

-(void)reloadTable{
    [self.refreshControl beginRefreshing];
    [self downloadJsonData];
}

/*
 This method is used to display the alertview
 
 */


-(void)showErrorAlert:(NSError *)error
{
    UIAlertView *alertView=[[[UIAlertView alloc]initWithTitle:@"Error" message:[NSError description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];
    [alertView show];
}

#pragma mark -
#pragma marl dealloc method

-(void)dealloc{
    
    [_data release];
    [_newsRow release];
    [_imageDownloadsInProgress release];
    [super dealloc];
    
}

@end
