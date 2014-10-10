//
//  MathViewController.m
//  ABCD Buddy
//
//  Created by Gauri Tikekar on 9/17/13.
//
//

#import "BRMathViewController.h"
#import "Utility.h"
#import "DPConstants.h"

@interface BRMathViewController ()

@end

@implementation BRMathViewController

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
    [self setQuestion];

	// Do any additional setup after loading the view.
}

-(void) setQuestion {
    int num1 = [Utility getRandomNumber:@"1:5"];
    int num2 = [Utility getRandomNumber:@"1:5"];
    self.numberLbl1.text = [NSString stringWithFormat:@"%d", num1];
    self.numberLbl2.text = [NSString stringWithFormat:@"%d", num2];
    self.operatorLbl.text = @"x";
    self.expectedAnswer = num1 * num2;
    [self.mathAnswerLbl setText:@""];
}

-(void) validate {

    if([self.mathAnswerLbl.text intValue] == self.expectedAnswer) {
        // requires to notify with object blank. Callback method will always rmoveobserver first
        // and then check the value of object to decide whether the math problem was solved or not.
        // And post has to be done on completion of dialog close. Else Facebook dialog will not open.
        [self dismissViewControllerAnimated:true completion:^(void){
            [[NSNotificationCenter defaultCenter] postNotificationName:MATH_SOLVED_NOTIFICATION object:MATH_SOLVED_FLAG userInfo:nil];
        }];
    }
    else if([self.mathAnswerLbl.text length] == 2) {
        [self shake:self.view];
    }
}

-(void) updateAnswerLabel : (NSString *) number {
    if([self.mathAnswerLbl.text length] == 2) {
        return;
    }
    NSString *answer = self.mathAnswerLbl.text;
    answer = [answer stringByAppendingString:number];
    [self.mathAnswerLbl setText:answer];
    [self validate];
}

- (IBAction)oneClick:(id)sender {
    [self updateAnswerLabel:@"1"];

}

- (IBAction)twoClick:(id)sender {
    [self updateAnswerLabel:@"2"];
}

- (IBAction)threeClick:(id)sender {
    [self updateAnswerLabel:@"3"];
}

- (IBAction)fourClick:(id)sender {
    [self updateAnswerLabel:@"4"];
}

- (IBAction)fiveClick:(id)sender {
   [self updateAnswerLabel:@"5"];
}

- (IBAction)sixClick:(id)sender {
    [self updateAnswerLabel:@"6"];
}

- (IBAction)sevenClick:(id)sender {
    [self updateAnswerLabel:@"7"];
}

- (IBAction)eightClick:(id)sender {
    [self updateAnswerLabel:@"8"];
}

- (IBAction)nineClick:(id)sender {
    [self updateAnswerLabel:@"9"];
}

- (IBAction)zeroClick:(id)sender {
    [self updateAnswerLabel:@"0"];}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)shake:(UIView*)itemView
{

    CGFloat t = 5.0;

    CGAffineTransform leftQuake  = CGAffineTransformTranslate(CGAffineTransformIdentity, t, -t);
    CGAffineTransform rightQuake = CGAffineTransformTranslate(CGAffineTransformIdentity, -t, t);

    itemView.transform = leftQuake;  // starting point

    [UIView beginAnimations:@"earthquake" context:nil]; //]itemView];
    [UIView setAnimationRepeatAutoreverses:YES]; // important
    [UIView setAnimationRepeatCount:3];
    [UIView setAnimationDuration:0.05];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(shakeEnded:finished:context:)];

    itemView.transform = rightQuake; // end here & auto-reverse

    [UIView commitAnimations];
}

- (void)shakeEnded:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    // requires to notify with object blank. Callback method will always rmoveobserver first
    // and then check the value of object to decide whether the math problem was solved or not.
    [self dismissViewControllerAnimated:true completion:^(void){
        [[NSNotificationCenter defaultCenter] postNotificationName:MATH_SOLVED_NOTIFICATION object:@"" userInfo:nil];
    }];
}

-(NSUInteger)supportedInterfaceOrientations{
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType hasPrefix:@"iPad"]) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
