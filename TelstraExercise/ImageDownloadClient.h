/*
    File: ImageDownloadClient.m
    load images for visible cells
*/

 #import <Foundation/Foundation.h>

 
@class Feeds;

@interface ImageDownloadClient : NSObject

@property (nonatomic, strong) Feeds *appRecord;
@property (nonatomic, copy) void (^completionHandler)(void);

- (void)startDownload;
- (void)cancelDownload;

@end
