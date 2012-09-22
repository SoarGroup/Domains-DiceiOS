//
//  iPadServerViewController.h
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Lair_s_DiceAppDelegate_iPad.h"

typedef struct {
    int dieNumber;
    int playerNumber;
    int die;
} Args;

@interface iPadServerViewController : UIViewController {
    UITextView *console;
    
    UIView *rootView;
    
    UIImage *question;
    
    IBOutlet UILabel     *areaOnePlayerName;
    IBOutlet UIImageView *dieOne_AreaOne;
    IBOutlet UIImageView *dieTwo_AreaOne;
    IBOutlet UIImageView *dieThree_AreaOne;
    IBOutlet UIImageView *dieFour_AreaOne;
    IBOutlet UIImageView *dieFive_AreaOne;
    
    IBOutlet UILabel     *areaTwoPlayerName;
    IBOutlet UIImageView *dieOne_AreaTwo;
    IBOutlet UIImageView *dieTwo_AreaTwo;
    IBOutlet UIImageView *dieThree_AreaTwo;
    IBOutlet UIImageView *dieFour_AreaTwo;
    IBOutlet UIImageView *dieFive_AreaTwo;
    
    IBOutlet UILabel     *areaThreePlayerName;
    IBOutlet UIImageView *dieOne_AreaThree;
    IBOutlet UIImageView *dieTwo_AreaThree;
    IBOutlet UIImageView *dieThree_AreaThree;
    IBOutlet UIImageView *dieFour_AreaThree;
    IBOutlet UIImageView *dieFive_AreaThree;
    
    IBOutlet UILabel     *areaFourPlayerName;
    IBOutlet UIImageView *dieOne_AreaFour;
    IBOutlet UIImageView *dieTwo_AreaFour;
    IBOutlet UIImageView *dieThree_AreaFour;
    IBOutlet UIImageView *dieFour_AreaFour;
    IBOutlet UIImageView *dieFive_AreaFour;
    
    IBOutlet UILabel     *areaFivePlayerName;
    IBOutlet UIImageView *dieOne_AreaFive;
    IBOutlet UIImageView *dieTwo_AreaFive;
    IBOutlet UIImageView *dieThree_AreaFive;
    IBOutlet UIImageView *dieFour_AreaFive;
    IBOutlet UIImageView *dieFive_AreaFive;
    
    IBOutlet UILabel     *areaSixPlayerName;
    IBOutlet UIImageView *dieOne_AreaSix;
    IBOutlet UIImageView *dieTwo_AreaSix;
    IBOutlet UIImageView *dieThree_AreaSix;
    IBOutlet UIImageView *dieFour_AreaSix;
    IBOutlet UIImageView *dieFive_AreaSix;
    
    IBOutlet UILabel     *areaSevenPlayerName;
    IBOutlet UIImageView *dieOne_AreaSeven;
    IBOutlet UIImageView *dieTwo_AreaSeven;
    IBOutlet UIImageView *dieThree_AreaSeven;
    IBOutlet UIImageView *dieFour_AreaSeven;
    IBOutlet UIImageView *dieFive_AreaSeven;
    
    IBOutlet UILabel     *areaEightPlayerName;
    IBOutlet UIImageView *dieOne_AreaEight;
    IBOutlet UIImageView *dieTwo_AreaEight;
    IBOutlet UIImageView *dieThree_AreaEight;
    IBOutlet UIImageView *dieFour_AreaEight;
    IBOutlet UIImageView *dieFive_AreaEight;
    
    NSArray *Players;
        
    Lair_s_DiceAppDelegate_iPad *appDelegate;
    
    int players;
}

@property (nonatomic, retain) IBOutlet UITextView *console;

@property (nonatomic, assign) Lair_s_DiceAppDelegate_iPad *appDelegate;

- (void)logToConsole:(NSString *)message;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withPlayers:(int)players;

- (void)dieWasPushed:(Arguments*)args;

- (void)clearPushedDice:(Arguments*)didWin;

- (IBAction)didEndGame:(UIButton *)sender;

- (void)setPlayerName:(NSString *)name forPlayer:(int)player;

@end
