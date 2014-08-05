//
//  SMAsyncImageView.h
//  Lauritz
//
//  Created by Ivan Pavlovic on 8/10/12.
//  Copyright (c) 2012 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AsyncImageViewDelegate <NSObject>
- (void) imageLoadingDone:(UIImageView*) obj;
@required
- (void) newImageSize:(CGSize) size forObj:(UIImageView*) obj;
@end

/**
 * \ingroup libs
 * \ingroup sm
 * Asynchronously loads an image
 *
 * loadImage: - asynchronously loads na image checking the cache first
 * loadImage:withBackup: - asynchronously load an image with backup link in case the first one doesn't exist
 */
@interface AsyncImageView : UIImageView <NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    BOOL hasBackup;
}


@property (nonatomic, weak) id<AsyncImageViewDelegate> delegate;
/**
 * URL connection
 */
@property (nonatomic, strong) NSURLConnection * conn;

/**
 * asynchronously loads na image checking the cache first
 */
- (void) loadImage:(NSString*)imagePath;
/**
 * asynchronously load an image with backup link in case the first one doesn't exist (cache is checked in both cases)
 */
- (void) loadImage:(NSString*)imagePath withBackup:(NSString*) backup;

/**
 * Cancel loading
 */
- (void)cancelLoad;

@end
