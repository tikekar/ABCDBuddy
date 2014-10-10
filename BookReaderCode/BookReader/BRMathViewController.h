//
//  MathViewController.h
//  ABCD Buddy
//
//  Created by Gauri Tikekar on 9/17/13.
//
//

#import <UIKit/UIKit.h>

@interface BRMathViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *mathAnswerLbl;
@property (weak, nonatomic) IBOutlet UILabel *operatorLbl;
@property (weak, nonatomic) IBOutlet UILabel *numberLbl2;

@property (weak, nonatomic) IBOutlet UILabel *numberLbl1;
@property int expectedAnswer;

-(void) setQuestion;

@end
