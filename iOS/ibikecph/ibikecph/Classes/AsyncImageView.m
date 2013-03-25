//
//  SMAsyncImageView.m
//  
//
//  Created by Ivan Pavlovic on 17/10/12.
//  Copyright (c) 2012 City of Copenhagen. All rights reserved.
//

#import "AsyncImageView.h"

@interface AsyncImageView()
@property (nonatomic, strong) NSMutableData * imageData;
@property (nonatomic, strong) NSString * backupImg;
@property (nonatomic, strong) NSString * currentImage;
@end

@implementation AsyncImageView

@synthesize delegate, conn, imageData, backupImg, currentImage;

- (id) init {
    self = [super init];
    if (self) {
        self.imageData = [NSMutableData data];
        hasBackup = NO;
    }
    return self;
}

- (void)cancelLoad {
    if (self.conn) {
        [self.conn cancel];
    }
    self.currentImage = @"";
    [self setImageData:[NSMutableData data]];
}

- (void) loadImage:(NSString*)imagePath {
    if ([self.currentImage isEqualToString:imagePath]) {
        return;
    }
    [self setCurrentImage:imagePath];
    @try {
//        if ([CacheManager isFileInCache:self.currentImage]) {
//            UIImage * img = [[UIImage alloc] initWithContentsOfFile:[CacheManager getFileFromCache:self.currentImage]];
//            [self performSelectorOnMainThread:@selector(setImage:) withObject:img waitUntilDone:YES];
//            [img release];
//            if (self.delegate) {
//                [self.delegate imageLoadingDone:self];
//            }
//        } else {
            [self setAlpha:0.0f];
            if (self.conn) {
                [self.conn cancel];
            }
            self.imageData = [NSMutableData data];
            NSURLConnection * c = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:imagePath]] delegate:self startImmediately:NO];
            [self setConn:c];
            [self.conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [self.conn start];
//        }
    }
    @catch (NSException *exception) {
        NSLog(@"loadImage: Caught %@: %@", [exception name], [exception  reason]);
    }
    @finally {
        
    }
}

- (void) loadImage:(NSString*)imagePath withBackup:(NSString*) backup {
    hasBackup = YES;
    [self setBackupImg:backup];
    [self loadImage:imagePath];
}

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (hasBackup) {
        hasBackup = NO;
        [self.conn cancel];
        self.conn = nil;
        [self setAlpha:1.0f];
        [self loadImage:self.backupImg];
    } else {
        hasBackup = NO;
        NSLog(@"%@", error);
        [self.conn cancel];
        self.conn = nil;
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    if ([httpResponse statusCode] == 404) {
        if (hasBackup) {
            hasBackup = NO;
            [self.conn cancel];
            self.conn = nil;
            [self setAlpha:1.0f];
            [self loadImage:self.backupImg];
        } else {
            hasBackup = NO;
            [self.conn cancel];
            self.conn = nil;
        }        
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
//    [CacheManager saveFileToCache:self.currentImage withData:self.imageData];
    UIImage * img = [[UIImage alloc] initWithData:self.imageData];
    if ((img != nil) || (hasBackup == NO)) {
        [self setImage:img];
        [self setAlpha:1.0f];
        if (self.delegate) {
            [self.delegate imageLoadingDone:self];
        }
        if (self.delegate) {
            [self.delegate newImageSize:img.size forObj:self];
        }
    } else {
        hasBackup = NO;
        [self.conn cancel];
        self.conn = nil;
        [self setAlpha:1.0f];
        [self loadImage:self.backupImg];
    }
}

@end
