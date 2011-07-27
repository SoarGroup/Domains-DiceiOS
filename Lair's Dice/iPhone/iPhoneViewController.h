//
//  iPhoneViewController.h
//  Lair's Dice
//
//  Created by Alex on 7/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Lair_s_DiceAppDelegate_iPhone.h"
#import "DiceEngine.h"

typedef enum {
    None = 0,
    First = 1,
    Second = 2,
    Cancel = 3
} challengeWhichOne;

typedef struct {
    BOOL pushedDice1;
    BOOL pushedDice2;
    BOOL pushedDice3;
    BOOL pushedDice4;
    BOOL pushedDice5;
} previousDice;

@interface iPhoneViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIAlertViewDelegate> {
    UIImageView *die1;
    UIImageView *die2;
    UIImageView *die3;
    UIImageView *die4;
    UIImageView *die5;
    
    UIButton *pushDie1;
    UIButton *pushDie2;
    UIButton *pushDie3;
    UIButton *pushDie4;
    UIButton *pushDie5;
    
    BOOL pushedDie1;
    BOOL pushedDie2;
    BOOL pushedDie3;
    BOOL pushedDie4;
    BOOL pushedDie5;
    
    UIButton *pass;
    UIButton *exact;
    UIButton *challenge;
    UIButton *bid;
    
    UIPickerView *number;
    UIPickerView *dieValue;
    
    NSArray *maxNumberOfDice;
    NSArray *numberOfSidesOnADice;
    
    UIImage *dieOne;
    UIImage *dieTwo;
    UIImage *dieThree;
    UIImage *dieFour;
    UIImage *dieFive;
    UIImage *dieSix;
    
    UIImage *dieOnePushed;
    UIImage *dieTwoPushed;
    UIImage *dieThreePushed;
    UIImage *dieFourPushed;
    UIImage *dieFivePushed;
    UIImage *dieSixPushed;

    Lair_s_DiceAppDelegate_iPhone *delegate;
    
    UITextView *textView;
    
    previousDice previousPushed;
    
@public

    BOOL confirmed;
    BOOL continueWithAction;
    
    int numberOfDiceToBid;
    int rankOfDiceToBid;
    
    ActionsAbleToSend action;
    
    NSMutableArray *diceToPush;
    
    challengeWhichOne challengeWhich; // NO = first YES = second
    
    UIAlertView *confirmationAlert;
}

@property (nonatomic, retain) IBOutlet UIImageView *die1;
@property (nonatomic, retain) IBOutlet UIImageView *die2;
@property (nonatomic, retain) IBOutlet UIImageView *die3;
@property (nonatomic, retain) IBOutlet UIImageView *die4;
@property (nonatomic, retain) IBOutlet UIImageView *die5;

@property (nonatomic, retain) IBOutlet UIButton *pushDie1;
@property (nonatomic, retain) IBOutlet UIButton *pushDie2;
@property (nonatomic, retain) IBOutlet UIButton *pushDie3;
@property (nonatomic, retain) IBOutlet UIButton *pushDie4;
@property (nonatomic, retain) IBOutlet UIButton *pushDie5;

@property (nonatomic, retain) IBOutlet UIButton *pass;
@property (nonatomic, retain) IBOutlet UIButton *exact;
@property (nonatomic, retain) IBOutlet UIButton *challenge;
@property (nonatomic, retain) IBOutlet UIButton *bid;

@property (nonatomic, retain) IBOutlet UIPickerView *number;
@property (nonatomic, retain) IBOutlet UIPickerView *dieValue;

@property (nonatomic, retain) IBOutlet UITextView *textView;

- (IBAction)didClickButton:(UIButton *)sender;

- (BOOL)updateDice:(NSArray *)diceAsNumbers withNewRound:(BOOL)newRound;

@property (nonatomic, assign) Lair_s_DiceAppDelegate_iPhone *delegate;

- (void)disableAllButtons;

@end
