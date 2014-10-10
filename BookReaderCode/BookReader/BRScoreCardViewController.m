//
//  ScoreCardViewController.m
//  ABCD Buddy
//
//  Created by Abhijit on 10/8/13.
//
//

#import "BRScoreCardViewController.h"
#import "AppDelegate.h"
#import "BRActivityStatDB.h"
#import "BRCategoryScore.h"

@interface BRScoreCardViewController ()

@end

@implementation BRScoreCardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	BRActivityStatDB *statDB = ((AppDelegate *) [[UIApplication sharedApplication] delegate]).statDB;
    NSMutableArray *tempScores = [[NSMutableArray alloc] initWithArray:[statDB getScoreCard:@"abcdbuddy"]];

    _scores = [[NSMutableArray alloc] init];

    // bool found = false;
    for (int i=0; i<[tempScores count]; i++) {
        BRCategoryScore *iScore = [tempScores objectAtIndex:i];
        if([self hasCategory:iScore.category]) {
            [self updateScore:iScore.category :iScore];
        }
        else {
            [_scores addObject:iScore];
        }

    }
    //_scores = [[NSMutableArray alloc] initWithArray:[statDB getScoreCard:@"abcdbuddy"]];

    for( long i=[_scores count] -1; i >= 0; i--) {
        BRCategoryScore *score = _scores[i];
        if( [score.category isEqualToString:@"PageType"] ) {
            [_scores removeObjectAtIndex:i];
            continue;
        }
    }
    [self.scoreTable setDataSource:self];
    [self.scoreTable reloadData];
}

-(bool) hasCategory : (NSString *) category {
    for (int i=0; i<[_scores count]; i++) {
        BRCategoryScore *iScore = [_scores objectAtIndex:i];
        if([iScore.category isEqualToString:category]) {
            return true;
        }
    }
    return false;
}

-(void) updateScore : (NSString *) category : (BRCategoryScore *) withScore {
    for (int i=0; i<[_scores count]; i++) {
        BRCategoryScore *iScore = [_scores objectAtIndex:i];
        if([iScore.category isEqualToString:category]) {
            iScore.solved = withScore.solved + iScore.solved;
            iScore.attempts = withScore.attempts + iScore.attempts;
            iScore.time = withScore.time + iScore.time;
            [_scores replaceObjectAtIndex:i withObject:iScore];
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSUInteger)supportedInterfaceOrientations{
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType hasPrefix:@"iPad"]) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)onDeleteAll:(id)sender {
    BRActivityStatDB *statDB = ((AppDelegate *) [[UIApplication sharedApplication] delegate]).statDB;
    [statDB clearScoreData];
    _scores = [[NSMutableArray alloc] initWithArray:[statDB getScoreCard:@"abcdbuddy"]];

    [self.scoreTable reloadData];

}

- (IBAction)onDone:(id)sender {
    [self dismissViewControllerAnimated:TRUE completion:nil];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // NSLog(@"number of rows in score card = %d", self.scores.count);
    return [self.scores count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *row = [tableView dequeueReusableCellWithIdentifier:@"ScoreRow"];
    BRCategoryScore *score = [self.scores objectAtIndex:indexPath.row];
    ((UILabel*)[row viewWithTag:1]).text = score.category;
    ((UILabel*)[row viewWithTag:2]).text = [NSString stringWithFormat:@"%d", score.solved];
    ((UILabel*)[row viewWithTag:3]).text = [NSString stringWithFormat:@"%d", score.attempts];
    if( score.time > 59) {
        ((UILabel*)[row viewWithTag:4]).text = [NSString stringWithFormat:@"%ld mins", score.time/60];
    }
    else {
        ((UILabel*)[row viewWithTag:4]).text = [NSString stringWithFormat:@"%ld secs", score.time];
    }
    return row;
}


@end
