//
//  Feeds.m

//  Created by ramya on 03/03/15.
//  Copyright (c) 2015 cognizant. All rights reserved.
//  Data structure to load rows

#import "RowModel.h"


@interface RowModel(){
    
}

@end

@implementation RowModel

static NSString * const kTitleName = @"title";
static NSString * const kDescription = @"description";
static NSString * const kImageHref = @"imageHref";
-(instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    RowModel *copy=[[self class] allocWithZone:zone];
    copy.feedsTitle=self.feedsTitle;
    copy.feedsImage=self.feedsImage;
    copy.feedsDescription=self.feedsDescription;
    return copy ;
    
}

#pragma mark -
#pragma mark Custom Methods

/*
 This function is used to check whether all the elements are returned
 from the response and to assign fefault values incase of any unexpected
 values in the response.
 */

-(BOOL)isValidString:(id)string{
    if ([string isKindOfClass:[NSNull class]]) {
        return NO;
    }
    return YES;
}


-(BOOL)containsAllElements:(NSDictionary *)attributes
{
    if ([ self isValidString:[attributes valueForKeyPath:kTitleName]] ) {
        self.feedsTitle = [attributes valueForKeyPath:kTitleName];
    }
    else{
        return NO;
    }
    
    if ([ self isValidString:[attributes valueForKeyPath:kDescription]]) {
        self.feedsDescription = [attributes valueForKeyPath:kDescription];
        NSRange range = [self.feedsDescription rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];
        self.feedsDescription = [self.feedsDescription stringByReplacingCharactersInRange:range withString:@""];
    }
    else{
        self.feedsDescription = @"";
    }
    
    if ([ self isValidString:[attributes valueForKeyPath:kImageHref]]) {
        self.feedsImage = [attributes valueForKeyPath:kImageHref];
    }
    else{
        self.feedsImage=@"";
    }
    
    return YES;
}

#pragma mark -
#pragma mark Dealloc Method
-(void)dealloc{
    
    [_feedsTitle release];
    [_feedsDescription release];
    [_feedsImage release];
    [_appIcon release];
    
    [super dealloc];
    
}


@end
