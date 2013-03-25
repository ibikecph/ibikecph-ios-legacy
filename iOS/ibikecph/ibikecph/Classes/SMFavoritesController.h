//
//  SMRegisterController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 18/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMSearchController.h"

@interface SMFavoritesController : SMTranslatedViewController <UITextFieldDelegate, SMSearchDelegate> {
    
    __weak IBOutlet UITextField *favoriteHome;
    __weak IBOutlet UITextField *favoriteWork;
    __weak IBOutlet UIScrollView *scrlView;
    __weak IBOutlet UIView *favoritesView;
}

@end
