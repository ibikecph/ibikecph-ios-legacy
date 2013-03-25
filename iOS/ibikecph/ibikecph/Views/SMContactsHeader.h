//
//  SMContactsHeader.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

@protocol SMContactsHeaderDelegate <NSObject>
- (void)buttonPressed:(id) btn;
@end

@interface SMContactsHeader : UITableViewCell

@property (nonatomic, weak) id<SMContactsHeaderDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *headerImage;
@property (weak, nonatomic) IBOutlet UILabel *headerText;
@property (weak, nonatomic) IBOutlet UIButton *headerButton;

+ (CGFloat)getHeight;

@end
