//
//  HistoryTableViewCell.m
//  UM Liars Dice
//
//  Created by Alex Turner on 3/2/15.
//
//

#import "HistoryTableViewCell.h"
#import "NSLayoutConstraint+ClassMethodPriority.h"
#import "NSDate+DateTools.h"
#import "PlayerState.h"
#import "DiceLocalPlayer.h"
#import "DiceRemotePlayer.h"
#import "SoarPlayer.h"
#import "UIImage+ImageEffects.h"

const CGFloat HistoryTableViewCellMessageFontSize = 15.0f;
const CGFloat HistoryTableViewCellUsernameFontSize = 15.0f;
const CGFloat HistoryTableViewCellTimestampFontSize = 12.0f;
const CGFloat HistoryTableViewCellPadding = 10.0f;
const CGFloat HistoryTableViewCellAvatarWidth = 40.0f;
const CGFloat HistoryTableViewCellAvatarHeight = 40.0f;
const CGFloat HistoryTableViewCellMediaIconWidth = 30.0f;
const CGFloat HistoryTableViewCellMediaIconHeight = 24.0f;

@interface HistoryTableViewCell()

@property(nonatomic,strong) NSMutableArray *rightGutterConstraints;

@end


@implementation HistoryTableViewCell

@synthesize message, avatarView, usernameLabel, messageTextLabel, timestampLabel, rightGutterConstraints, loadTime;

#pragma mark - Class methods

+ (CGFloat)minimumHeight
{
	return HistoryTableViewCellAvatarHeight + HistoryTableViewCellPadding*2;
}

#pragma mark - View lifecycle

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	
	self.loadTime = [NSDate date];
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];
	
	self.accessoryType = UITableViewCellAccessoryNone;
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
	self.avatarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar-placeholder"]];
	[self.contentView addSubview:self.avatarView];
	
	self.usernameLabel = [[UILabel alloc] init];
	self.usernameLabel.font = [UIFont boldSystemFontOfSize:HistoryTableViewCellUsernameFontSize];
	self.usernameLabel.textColor = [UIColor whiteColor];
	self.usernameLabel.backgroundColor = [UIColor clearColor];
	[self.contentView addSubview:self.usernameLabel];
	
	self.messageTextLabel = [[UILabel alloc] init];
	self.messageTextLabel.font = [UIFont systemFontOfSize:HistoryTableViewCellMessageFontSize];
	self.messageTextLabel.textColor = [UIColor whiteColor];
	self.messageTextLabel.numberOfLines = 0;
	self.messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
	
//	if ([device isEqualToString:@"iPhone"])
		self.messageTextLabel.backgroundColor = [UIColor umichBlueColor];
//	else
//		self.messageTextLabel.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
	
	[self.contentView addSubview:self.messageTextLabel];
	
	self.timestampLabel = [[UILabel alloc] init];
	self.timestampLabel.font = [UIFont systemFontOfSize:HistoryTableViewCellTimestampFontSize];
	
//	if ([device isEqualToString:@"iPhone"])
		self.timestampLabel.textColor = [UIColor lightGrayColor];
//	else
//		self.timestampLabel.textColor = [UIColor whiteColor];
	
	self.timestampLabel.textAlignment = NSTextAlignmentRight;
	self.timestampLabel.backgroundColor = [UIColor clearColor];
	[self.contentView addSubview:self.timestampLabel];
	
	self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
	self.usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.messageTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
	
//	if ([device isEqualToString:@"iPhone"])
		self.backgroundColor = [UIColor umichBlueColor];
//	else
//		self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
	
	self.rightGutterConstraints = [NSMutableArray array];
	[self applyConstraints];
	
	return self;
}


#pragma mark - State

- (void)setMessage:(HistoryItem *)item {
	message = item;
	PlayerState* state = message.player;
	id<Player> playerPtr = state.playerPtr;
	
	self.usernameLabel.text = [playerPtr getDisplayName];
	self.messageTextLabel.attributedText = [message asHistoryString];
	self.messageTextLabel.accessibilityLabel = [message accessibleText];
	
	self.timestampLabel.text = [message.timestamp timeAgoSinceDate:self.loadTime];
	
	__block UIImage* profileImage = [UIImage imageNamed:@"YouPlayer.png"];
	
	if ([playerPtr isKindOfClass:DiceLocalPlayer.class] || [playerPtr isKindOfClass:DiceRemotePlayer.class])
	{
		if ([playerPtr isKindOfClass:DiceRemotePlayer.class])
			profileImage = [UIImage imageNamed:@"HumanPlayer.png"];
		
		// Works for DiceRemotePlayer too
		DiceLocalPlayer* player = playerPtr;
		
		if (player.handler || ([playerPtr isKindOfClass:DiceLocalPlayer.class] && [GKLocalPlayer localPlayer].isAuthenticated))
		{
			dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
			
			GKPlayer* gkPlayer = player.participant.player;
			
			if ([playerPtr isKindOfClass:DiceLocalPlayer.class] && [GKLocalPlayer localPlayer].isAuthenticated)
				gkPlayer = [GKLocalPlayer localPlayer];
			
			[gkPlayer loadPhotoForSize:GKPhotoSizeSmall withCompletionHandler:^(UIImage* photo, NSError* error)
			 {
				 if (photo)
					 profileImage = photo;
				 
				 dispatch_semaphore_signal(semaphore);
			 }];
			
			while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
		}
	}
	else if ([playerPtr isKindOfClass:SoarPlayer.class])
		profileImage = [UIImage imageNamed:@"SoarPlayer.png"];
	
	self.avatarView.image = profileImage;
	CGRect frame = self.avatarView.frame;
	frame.size.width = HistoryTableViewCellAvatarWidth;
	frame.size.height = HistoryTableViewCellAvatarHeight;
	self.avatarView.frame = frame;
	
	[self setNeedsUpdateConstraints];
	[self setNeedsLayout];
}


#pragma mark - Layout

- (CGFloat)rightGutterWidth {
	return HistoryTableViewCellPadding;
}

- (void)updateConstraints {
	[super updateConstraints];
	
	// update the right gutter
	for (NSLayoutConstraint *c in self.rightGutterConstraints) {
		c.constant = [self rightGutterWidth];
	}
}

- (void)applyConstraints {
	[self.contentView removeConstraints:self.contentView.constraints];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarView
																 attribute:NSLayoutAttributeTop
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeTop
																multiplier:1
																  constant:HistoryTableViewCellPadding]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView
																 attribute:NSLayoutAttributeBottom
																 relatedBy:NSLayoutRelationGreaterThanOrEqual
																	toItem:self.avatarView
																 attribute:NSLayoutAttributeBottom
																multiplier:1
																  constant:HistoryTableViewCellPadding
																  priority:UILayoutPriorityDefaultLow]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarView
																 attribute:NSLayoutAttributeLeft
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeLeft
																multiplier:1
																  constant:HistoryTableViewCellPadding]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarView
																 attribute:NSLayoutAttributeHeight
																 relatedBy:NSLayoutRelationEqual
																	toItem:nil
																 attribute:NSLayoutAttributeNotAnAttribute
																multiplier:1
																  constant:HistoryTableViewCellAvatarHeight
																  priority:UILayoutPriorityRequired]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarView
																 attribute:NSLayoutAttributeWidth
																 relatedBy:NSLayoutRelationEqual
																	toItem:nil
																 attribute:NSLayoutAttributeNotAnAttribute
																multiplier:1
																  constant:HistoryTableViewCellAvatarWidth
																  priority:UILayoutPriorityRequired]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.usernameLabel
																 attribute:NSLayoutAttributeLeft
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.avatarView
																 attribute:NSLayoutAttributeRight
																multiplier:1
																  constant:HistoryTableViewCellPadding]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.usernameLabel
																 attribute:NSLayoutAttributeTop
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeTop
																multiplier:1
																  constant:HistoryTableViewCellPadding]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageTextLabel
																 attribute:NSLayoutAttributeLeft
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.avatarView
																 attribute:NSLayoutAttributeRight
																multiplier:1
																  constant:HistoryTableViewCellPadding]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageTextLabel
																 attribute:NSLayoutAttributeTop
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.usernameLabel
																 attribute:NSLayoutAttributeBottom
																multiplier:1
																  constant:0]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.timestampLabel
																 attribute:NSLayoutAttributeLeft
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.avatarView
																 attribute:NSLayoutAttributeRight
																multiplier:1
																  constant:HistoryTableViewCellPadding]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView
																 attribute:NSLayoutAttributeRight
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.timestampLabel
																 attribute:NSLayoutAttributeRight
																multiplier:1
																  constant:HistoryTableViewCellPadding]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.timestampLabel
																 attribute:NSLayoutAttributeTop
																 relatedBy:NSLayoutRelationGreaterThanOrEqual
																	toItem:self.messageTextLabel
																 attribute:NSLayoutAttributeBottom
																multiplier:1
																  constant:0
																  priority:UILayoutPriorityDefaultHigh]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView
																 attribute:NSLayoutAttributeBottom
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.timestampLabel
																 attribute:NSLayoutAttributeBottom
																multiplier:1
																  constant:HistoryTableViewCellPadding]];
	
	/*
	 * constraints that change constants in the presence of a media icon
	 */
	[self.rightGutterConstraints addObject:[NSLayoutConstraint constraintWithItem:self.contentView
																		attribute:NSLayoutAttributeRight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.usernameLabel
																		attribute:NSLayoutAttributeRight
																	   multiplier:1
																		 constant:[self rightGutterWidth]]];
	
	[self.rightGutterConstraints addObject:[NSLayoutConstraint constraintWithItem:self.contentView
																		attribute:NSLayoutAttributeRight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.messageTextLabel
																		attribute:NSLayoutAttributeRight
																	   multiplier:1
																		 constant:[self rightGutterWidth]]];
	
	[self.contentView addConstraints:self.rightGutterConstraints];
}

@end
