//
//  SMFavoritesUtil.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 24/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMAPIRequest.h"

@class SMFavoritesUtil;

@protocol SMFavoritesDelegate <NSObject>
- (void)favoritesOperationFinishedSuccessfully:(id)req withData:(id)data;
@optional
- (void)favoritesOperation:(id)req failedWithError:(NSError*)error;
@end

@interface SMFavoritesUtil : NSObject <SMAPIRequestDelegate>

@property (nonatomic, weak) id<SMFavoritesDelegate>delegate;

+ (NSMutableArray*)getFavorites;
+ (BOOL)saveToFavorites:(NSDictionary*)dict;
+ (BOOL)saveFavorites:(NSArray*)fav;

+ (SMFavoritesUtil *)instance;

- (SMFavoritesUtil *)initWithDelegate:(id<SMFavoritesDelegate>)delegate;
- (void)fetchFavoritesFromServer;
- (void)addFavoriteToServer:(NSDictionary*)favData;
- (void)deleteFavoriteFromServer:(NSDictionary*)favData;
- (void)editFavorite:(NSDictionary*)favData;

@end
