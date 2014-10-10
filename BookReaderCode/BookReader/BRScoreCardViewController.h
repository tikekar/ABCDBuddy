//
//  ScoreCardViewController.h
//  ABCD Buddy
//
//  Created by Abhijit on 10/8/13.
//
//

#import <UIKit/UIKit.h>

@interface BRScoreCardViewController : UIViewController<UITableViewDataSource>

@property NSMutableArray *scores;

@property (weak, nonatomic) IBOutlet UITableView *scoreTable;

@end
