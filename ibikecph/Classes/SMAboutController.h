//
//  SMAboutController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
/**
 * \ingroup screens
 * About screen
 */
@interface SMAboutController : SMTranslatedViewController {
    __weak IBOutlet UIScrollView *scrlView;
    __weak IBOutlet UILabel *aboutText;
}

@end
