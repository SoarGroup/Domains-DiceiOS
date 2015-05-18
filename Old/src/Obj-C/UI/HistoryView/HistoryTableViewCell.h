//
//  HistoryTableViewCell.h
//  UM Liars Dice
//
//  Created by Alex Turner on 3/2/15.
//
//

#import <UIKit/UIKit.h>

#import "HistoryItem.h"

@interface HistoryTableViewCell : UITableViewCell

+ (CGFloat)minimumHeight;

- (instancetype)initWithReuseIdentifier:(NSString*)reuseIdentifier;

@property(nonatomic,strong) HistoryItem *message;
@property(nonatomic,strong) UIImageView *avatarView;
@property(nonatomic,strong) UILabel *usernameLabel;
@property(nonatomic,strong) UILabel *messageTextLabel;
@property(nonatomic,strong) UILabel *timestampLabel;
@property(nonatomic,strong) NSDate* loadTime;

@end
