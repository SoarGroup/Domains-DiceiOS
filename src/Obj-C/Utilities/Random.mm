//
//  Random.m
//  UM Liars Dice
//
//  Created by Alex Turner on 7/28/14.
//
//

#import "Random.h"

@implementation Random

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];

	if (self)
	{
		integerSeed = [aDecoder decodeIntegerForKey:@"Random:seed"];
		numbersGenerated = [aDecoder decodeIntegerForKey:@"Random:numbersGenerated"];

		DDLogDebug(@"Seed:%lu", (unsigned long)integerSeed);

		seed = new std::seed_seq{integerSeed};
		random = std::minstd_rand0(*seed);

		for (int i = 0;i < numbersGenerated;i++)
			random();
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeInteger:integerSeed forKey:@"Random:seed"];
	[aCoder encodeInteger:numbersGenerated forKey:@"Random:numbersGenerated"];
}

- (id)init:(NSUInteger)intSeed;
{
	self = [super init];

	if (self)
	{
		integerSeed = intSeed;

		DDLogDebug(@"Seed:%lu", (unsigned long)integerSeed);

		seed = new std::seed_seq{integerSeed};
		random = std::minstd_rand0(*seed);

		numbersGenerated = 0;
	}

	return self;
}

- (int)randomNumber
{
	numbersGenerated++;

	int result = 0;

	if (integerSeed == NO_SEED)
		result = true_random();
	else
		result = random();

	if (result < 0)
		result *= -1;

	return result;
}

@end
