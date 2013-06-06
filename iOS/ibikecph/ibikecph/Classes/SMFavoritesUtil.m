//
//  SMFavoritesUtil.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 24/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMFavoritesUtil.h"

@interface SMFavoritesUtil ()
@property (nonatomic, strong) SMAPIRequest * apr;
@property (nonatomic, weak) SMAppDelegate * appDelegate;
@end

@implementation SMFavoritesUtil

+ (NSMutableArray*)getFavorites {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"favorites.plist"]]) {
        NSMutableArray * arr = [NSArray arrayWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"favorites.plist"]];
        NSMutableArray * arr2 = [NSMutableArray array];
        if (arr) {
            for (NSDictionary * d in arr) {
                [arr2 addObject:@{
                 @"id" : [d objectForKey:@"id"],
                 @"name" : [d objectForKey:@"name"],
                 @"address" : [d objectForKey:@"address"],
                 @"startDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"startDate"]],
                 @"endDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"endDate"]],
                 @"source" : [d objectForKey:@"source"],
                 @"subsource" : [d objectForKey:@"subsource"],
                 @"lat" : [d objectForKey:@"lat"],
                 @"long" : [d objectForKey:@"long"],
                 @"order" : @0
                 }];
            }
            return arr2;
        }
    }
    return [NSMutableArray array];
}

+ (BOOL)saveFavorites:(NSArray*)fav {
    NSMutableArray * r = [NSMutableArray array];
    for (NSDictionary * d in fav) {
        [r addObject:@{
         @"id" : [d objectForKey:@"id"]?[d objectForKey:@"id"]:@"0",
         @"name" : [d objectForKey:@"name"],
         @"address" : [d objectForKey:@"address"],
         @"startDate" : [NSKeyedArchiver archivedDataWithRootObject:[d objectForKey:@"startDate"]],
         @"endDate" : [NSKeyedArchiver archivedDataWithRootObject:[d objectForKey:@"endDate"]],
         @"source" : [d objectForKey:@"source"],
         @"subsource" : [d objectForKey:@"subsource"],
         @"lat" : [d objectForKey:@"lat"],
         @"long" : [d objectForKey:@"long"]
         }];
    }
    return [r writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"favorites.plist"] atomically:YES];
}

+ (BOOL)saveToFavorites:(NSDictionary*)dict {
    NSMutableArray * arr = [NSMutableArray array];
    NSMutableArray * a = [self getFavorites];
    for (NSDictionary * srch in a) {
        if ([[srch objectForKey:@"name"] isEqualToString:[dict objectForKey:@"name"]] == NO) {
            [arr addObject:srch];
        }
    }
    [arr addObject:dict];
    
    
    
    BOOL x = [SMFavoritesUtil saveFavorites:arr];
    
    return x;
}

+ (SMFavoritesUtil *)instance {
	static SMFavoritesUtil *instance;
	if (instance == nil) {
		instance = [[SMFavoritesUtil alloc] init];
        instance.appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
	}
    instance.delegate = nil;
	return instance;
}

- (SMFavoritesUtil *)initWithDelegate:(id<SMFavoritesDelegate>)delegate {
    self = [super init];
    if (self) {
        self.appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    }
    return self;
}

- (void)fetchFavoritesFromServer {
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"fetchList"];
    [self.apr executeRequest:API_LIST_FAVORITES withParams:@{@"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"]}];
}

- (void)addFavoriteToServer:(NSDictionary*)favData {
    [SMFavoritesUtil saveToFavorites:favData];
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"addFavorite"];
    [self.apr executeRequest:API_ADD_FAVORITE withParams:@{
     @"auth_token":[self.appDelegate.appSettings objectForKey:@"auth_token"], @
     "favourite": @{
     @"name": [favData objectForKey:@"name"],
     @"address": [favData objectForKey:@"address"],
     @"lattitude": [NSString stringWithFormat:@"%f", [[favData objectForKey:@"lat"] doubleValue]],
     @"longitude": [NSString stringWithFormat:@"%f", [[favData objectForKey:@"long"] doubleValue]],
     @"source": @"favourites",
     @"sub_source": [favData objectForKey:@"subsource"] }}
];
}

- (void)deleteFavoriteFromServer:(NSDictionary*)favData {
    NSMutableArray * a = [SMFavoritesUtil getFavorites];
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.id = %@", [favData objectForKey:@"id"]];
    NSArray * arr = [a filteredArrayUsingPredicate:pred];
    if ([arr count] > 0) {
        [a removeObjectsInArray:arr];
    }
    [SMFavoritesUtil saveFavorites:a];
    
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"addFavorite"];
    NSMutableDictionary * params = [API_DELETE_FAVORITE mutableCopy];
    [params setValue:[NSString stringWithFormat:@"%@/%@", [params objectForKey:@"service"], [favData objectForKey:@"id"]] forKey:@"service"];
    [self.apr executeRequest:params withParams:@{
     @"auth_token":[self.appDelegate.appSettings objectForKey:@"auth_token"]}];
}

- (void)editFavorite:(NSDictionary*)favData {
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"editFavorite"];
    NSMutableDictionary * params = [API_EDIT_FAVORITE mutableCopy];
    [params setValue:[NSString stringWithFormat:@"%@/%@", [params objectForKey:@"service"], [favData objectForKey:@"id"]] forKey:@"service"];
    [self.apr executeRequest:params withParams:@{
     @"auth_token":[self.appDelegate.appSettings objectForKey:@"auth_token"], @
     "favourite": @{
     @"name": [favData objectForKey:@"name"],
     @"address": [favData objectForKey:@"address"],
     @"lattitude": [NSString stringWithFormat:@"%f", [[favData objectForKey:@"lat"] doubleValue]],
     @"longitude": [NSString stringWithFormat:@"%f", [[favData objectForKey:@"long"] doubleValue]],
     @"source": @"favourites",
     @"sub_source": [favData objectForKey:@"subsource"] }}];
}


#pragma mark - api delegate

- (void)serverNotReachable {

}

-(void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    NSLog(@"%@", error);
//    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
//    [av show];
    if (self.delegate && [self.delegate respondsToSelector:@selector(favoritesOperation:failedWithError:)]) {
        [self.delegate favoritesOperation:self failedWithError:error];
    }
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([result objectForKey:@"error"]) {
        [SMFavoritesUtil saveFavorites:@[]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kFAVORITES_CHANGED object:self];
        if (self.delegate && [self.delegate respondsToSelector:@selector(favoritesOperationFinishedSuccessfully:withData:)]) {
            [self.delegate favoritesOperationFinishedSuccessfully:req withData:result];
        }
    } else if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"fetchList"]) {
            NSMutableArray * arr = [NSMutableArray arrayWithCapacity:result.count];
            for (NSDictionary * d in [result objectForKey:@"data"]) {
                [arr addObject:@{
                                @"id": [d objectForKey:@"id"],
                                @"name": [d objectForKey:@"name"],
                                @"address": [d objectForKey:@"address"],
                                @"startDate": [NSDate date],
                                @"endDate": [NSDate date],
                                @"lat": [NSNumber numberWithDouble:[[d objectForKey:@"lattitude"] doubleValue]],
                                @"long": [NSNumber numberWithDouble:[[d objectForKey:@"longitude"] doubleValue]],
                                @"source": @"favorites",
                                @"subsource": [d objectForKey:@"sub_source"]
                 }];
            }
            [SMFavoritesUtil saveFavorites:arr];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFAVORITES_CHANGED object:self];
            if (self.delegate && [self.delegate respondsToSelector:@selector(favoritesOperationFinishedSuccessfully:withData:)]) {
                [self.delegate favoritesOperationFinishedSuccessfully:req withData:result];
            }
        } else {
            [self fetchFavoritesFromServer];
        }
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
}



@end
