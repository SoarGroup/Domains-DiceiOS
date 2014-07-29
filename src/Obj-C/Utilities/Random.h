//
//  Random.h
//  UM Liars Dice
//
//  Created by Alex Turner on 7/28/14.
//
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus

#include <random>

#endif

#define NO_SEED -99999999

@interface Random : NSObject <NSCoding>
{
	NSUInteger numbersGenerated;
#ifdef __cplusplus
	std::seed_seq* seed;

	std::minstd_rand0 random;
	std::random_device true_random;
#endif

@public
	NSUInteger integerSeed;
}

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

- (id)init:(NSUInteger)seed;

- (uint32_t)randomNumber;

@end
