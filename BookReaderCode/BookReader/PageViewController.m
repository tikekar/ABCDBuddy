//
//  BookPageViewController.m
//  BookReader
//
//  Created by Gauri Tikekar on 11/15/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import "URLCache.h"
#import "PageViewController.h"
#import "BookViewController.h"
#import "Page.h"
#import "PageObject.h"
#import "Image.h"
#import "Text.h"
#import "Event.h"
#import "AnimationRunner.h"
#import "Consume.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "PaintView.h"
#import "Utility.h"
#import "GAIDictionaryBuilder.h"
#import "GAI.h"
#import "Condition.h"


@interface PageViewController ()

@end

@implementation PageViewController

@synthesize  modelPage, toyButtons, toyObjects, eventAnims, pageUIImages, occurredEvents, urlCache, book, timers, runningAnimations, runningChains, pageLoadTime;

bool attemptFiled = false;


float ORIGIN_Y_SHIFT = 0; //30;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) render {
    ORIGIN_Y_SHIFT = 0; //30;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeRight || orientation ==  UIInterfaceOrientationLandscapeLeft)
    {
        ORIGIN_Y_SHIFT = 0;
    }
    attemptFiled = false;
    self.timers = [[NSMutableArray alloc] init];
    self.runningAnimations = [[NSMutableDictionary alloc] init];

    urlCache = [[URLCache alloc] init];

    eventAnims = [[NSMutableDictionary alloc] init];
    pageUIImages = [[NSMutableDictionary alloc] init];
    toyButtons = [[NSMutableDictionary alloc] init];
    toyObjects = [[NSMutableDictionary alloc] init];
    occurredEvents = [[NSMutableDictionary alloc]init];
    self.runningChains = [[NSMutableDictionary alloc]init];

    int count = 0;
    for( int i=0; i < [modelPage.objects count]; i++) {
        PageObject *object = modelPage.objects[i];

        //Some newly added animations will work only in latest versions. Therefore we need to notify this somehow to users.
        //Threfore each page object can be shown only in certain version range eg 1.0:1.3 This can be used to generate textObjects
        // like 'This page requires version 1.3 or higher.'
        if( object.requiredVersion != nil ) {
            NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            NSString *versionRequired = object.requiredVersion;
            float minVersion = [Utility getMinNumber:versionRequired];
            float maxVersion = [Utility getMaxNumber:versionRequired];
            if( [currentVersion floatValue] < minVersion || [currentVersion floatValue] > maxVersion )
            {
                continue;
            }
        }

        Condition *condition = object.condition;
        if(condition != nil && ![condition isValid]) {
            continue;
        }

        if ([object.type isEqualToString:@"ImageType"]) {
            count++;
            [self renderToy: object: count];
        }
        else if ([object.type isEqualToString:@"CounterType"]) {
            count++;
            [self renderCounterText:object : count];
        }
        else  if ([object.type isEqualToString:@"TextType"])  {
            [self renderToy: object: count];
        }
        else  if ([object.type isEqualToString:@"VideoType"])  {
            [self renderVideo: object];
        }
        else  if ([object.type isEqualToString:@"PaintType"])  {
            
            count++;
            [self renderPaintPage: object : count];
        }
    }
    
    [self addEvents];


    self.pageLoadTime = [NSDate date];
    
    /*UISwipeGestureRecognizer *gestureRecognizer1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipeHandler:)];
    [gestureRecognizer1 setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:gestureRecognizer1];
    
    UISwipeGestureRecognizer *gestureRecognizer2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeHandler:)];
    [gestureRecognizer2 setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:gestureRecognizer2];*/
   
}

-(void) renderPaintPage : (PageObject *) paintObject : (int) i {
    CGRect screenFrame = [Utility getScreenBoundsForOrientation];

    CGFloat width = paintObject.relativeWidth;
    CGFloat height = paintObject.relativeHeight;
    width = screenFrame.size.width * width/100;
    height = screenFrame.size.height * height/100;
    CGFloat xpos = screenFrame.size.width * paintObject.relativeX / 100;
    CGFloat ypos = screenFrame.size.height * paintObject.relativeY / 100 ;
    NSString  *urlstr =   paintObject.url;
    UIButton *colorPicture;
    
    if( urlstr != nil) {
        colorPicture = [UIButton buttonWithType:UIButtonTypeCustom];

        UIImage *urlImage = [urlCache getImage:urlstr];
        [colorPicture setImage:urlImage forState:UIControlStateNormal];
        [colorPicture setImage:urlImage forState:UIControlStateSelected];
        [colorPicture setImage:urlImage forState:UIControlStateHighlighted];

        CGFloat bxpos = 0;
        CGFloat bypos = 0 + ORIGIN_Y_SHIFT;

        colorPicture.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        colorPicture.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

        [colorPicture setContentMode:UIViewContentModeScaleAspectFit];
        colorPicture.imageView.contentMode = UIViewContentModeScaleAspectFit;

        CGRect screenFrame = [Utility getScreenBoundsForOrientation];

        colorPicture.frame = CGRectMake(bxpos, bypos, screenFrame.size.width, screenFrame.size.height - 70 );
        // [self.view insertSubview:colorPicture atIndex:i];
        [self.view addSubview:colorPicture];
    }

    CGRect frame = CGRectMake(xpos, ypos, width, height);

    PaintView *paint = [[PaintView alloc]  initWithFrame:frame];

    [self.view addSubview: paint];
       
}

-(void) renderVideo : (PageObject*) videoObject{
    CGRect screenFrame = [Utility getScreenBoundsForOrientation];

    CGFloat width = videoObject.relativeWidth;
    CGFloat height = videoObject.relativeHeight;
    width = screenFrame.size.width * width/100;
    height = screenFrame.size.height * height/100;
    CGFloat xpos = screenFrame.size.width * videoObject.relativeX / 100;
    CGFloat ypos = screenFrame.size.height * videoObject.relativeY / 100 + ORIGIN_Y_SHIFT;

    UIWebView *myVideo = [[UIWebView alloc] initWithFrame:CGRectMake(xpos, ypos, width, height)];
    
    NSString *embed = nil;
    if( [videoObject.video hasPrefix:@"<iframe"]) {
        embed = videoObject.video;
    }
    else {
            NSString* part1 = @"<iframe width=\"";
            NSString* part2 =  [NSString stringWithFormat: @"%f", width - 20];
            NSString *part3 = @"\" height=\"";
            NSString* part4 = [NSString stringWithFormat: @"%f", height];
            NSString *part5 = @"\" src=\"";
            NSString *part6 = videoObject.video;
            NSString *part7 = @"\" frameborder=\"0\" allowfullscreen></iframe>";
            embed = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@", part1, part2, part3, part4, part5, part6, part7];
    }

    [myVideo loadHTMLString:embed baseURL:nil];
    [self.view addSubview:myVideo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayEnded:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

}

//reload the page again to hide the youtube video header area share and info buttons.
- (void)videoPlayEnded:(NSNotification *)notification
{
    //NSLog( @"playeritem ended reached");
    
    UIView *bookView =  self.view.superview;
    BookViewController *bookViewController;
    for (UIResponder * nextResponder = bookView.nextResponder;
         nextResponder;
         nextResponder = nextResponder.nextResponder)
    {
        if ([nextResponder isKindOfClass:[BookViewController class]])
            bookViewController = (BookViewController *)nextResponder;
        break;
    }
    if( bookViewController) {
        [bookViewController goToPage:self.pageNumber :@"none"];
    }
}


-(void) renderToy : (PageObject*) toyObj : (int) i {

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTag:i];

    NSString  *urlstr =   toyObj.url;

    //PlaySound animation adds an empty toy. With url="" and width=0 and height=0
    if( ![urlstr isEqualToString:@""]) {
        
        UIImage *urlImage = [urlCache getImage:urlstr];
        [button setImage:urlImage forState:UIControlStateNormal];
        [button setImage:urlImage forState:UIControlStateSelected];
        [button setImage:urlImage forState:UIControlStateHighlighted];
    }

    if (toyObj.image != nil) {
        if( toyObj.image.backgroundColor != nil) {
            [button setBackgroundColor:toyObj.image.backgroundColor];
        }
        if( toyObj.image.alpha != -1 ){
            [button setAlpha:toyObj.image.alpha];
        }
        if( toyObj.image.cornerRadius != -1 ){
            button.layer.cornerRadius = toyObj.image.cornerRadius; // this value vary as per your desire
            button.clipsToBounds = YES;
        }
    }
    
    CGFloat xpos = toyObj.relativeX;
    CGFloat ypos = toyObj.relativeY;

    CGFloat width = toyObj.relativeWidth;
    CGFloat height = toyObj.relativeHeight;

    if( width == 100 && height == 100 ) {
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

        [button setContentMode:UIViewContentModeScaleAspectFill];
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;

        CGRect screenFrame = [Utility getScreenBoundsForOrientation];
        button.frame = CGRectMake(xpos, ypos, screenFrame.size.width, screenFrame.size.height );

        // In all render methods it was insersubview. But in iOS7 it gave trouble in PaintView
        // In PaintView the home and previous page buttons went behind the paintView.
        // insertSubview caused that somehow. So change it to addSubView everywhere.
        // It automatically maintains the z index sequence as per the sequence given in json.
        // [self.view insertSubview:button atIndex:i];
        [self.view addSubview:button];

        //added to fix the animations on background image not running issue. Added on 08/02/2013
        //Rooster book has used it
        if( toyObj.objectid!= nil) {
            [toyButtons setObject:button forKey:toyObj.objectid];
            [toyObjects setObject:toyObj forKey:toyObj.objectid];
        }

        if( [@"yes" caseInsensitiveCompare:toyObj.hidden] == NSOrderedSame ) {
            [button setHidden:true];
        }
        return;
    }
    
    CGRect screenFrame = [Utility getScreenBoundsForOrientation];
    
    width = screenFrame.size.width * width/100;
    height = screenFrame.size.height * height/100;
    xpos = screenFrame.size.width * xpos/100;
    ypos = screenFrame.size.height * ypos/100 + ORIGIN_Y_SHIFT;
    
    
    button.frame = CGRectMake(xpos, ypos, width, height );
    [button setContentMode:UIViewContentModeScaleAspectFit];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;

    if( toyObj.text != nil && ![toyObj.text.text isEqualToString:@""]) {

        [button setTitle:toyObj.text.text forState:UIControlStateNormal];
        [button setTitle:toyObj.text.text forState:UIControlStateSelected];

        if( [@"yes" caseInsensitiveCompare:toyObj.text.bold] == NSOrderedSame ) {
            [button.titleLabel setFont:[UIFont boldSystemFontOfSize:[[toyObj.text getSize] floatValue]]];
        }
        else {
            [button.titleLabel setFont:[UIFont systemFontOfSize:[[toyObj.text getSize] floatValue]]];
        }

        UIColor *color = toyObj.text.color;
        if(color != nil) {
            [button setTitleColor:color forState:UIControlStateNormal];
            [button setTitleColor:color forState:UIControlStateSelected];
        }
        button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;

        if( [@"yes" caseInsensitiveCompare:toyObj.text.shadow] == NSOrderedSame ) {
            button.titleLabel.layer.shadowRadius = 2;
            button.titleLabel.layer.shadowOffset = CGSizeMake(1, 1);
            button.titleLabel.layer.shadowOpacity = 0.5;
        }
        if (toyObj.image == nil) {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            button.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        }
        if (toyObj.text.align != nil) {
            if( [@"center" caseInsensitiveCompare:toyObj.text.align] == NSOrderedSame ) {
                button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                [button.titleLabel setTextAlignment:NSTextAlignmentCenter];
            }
            else if( [@"left" caseInsensitiveCompare:toyObj.text.align] == NSOrderedSame ) {
                button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                [button.titleLabel setTextAlignment:NSTextAlignmentLeft];
            }
            else if( [@"right" caseInsensitiveCompare:toyObj.text.align] == NSOrderedSame ) {
                button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                [button.titleLabel setTextAlignment:NSTextAlignmentRight];
            }
        }
        
    }


    if( toyObj.objectid!= nil) {
        [toyButtons setObject:button forKey:toyObj.objectid];
        [toyObjects setObject:toyObj forKey:toyObj.objectid];
    }

    // [self.view insertSubview:button atIndex:i];
    [self.view addSubview:button];
    if( [@"yes" caseInsensitiveCompare:toyObj.hidden] == NSOrderedSame ) {
        [button setHidden:true];
    }
}

-(void) renderCounterText : (PageObject*) counterTextObj : (int) i {


    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTag:i];

//new
    NSString  *urlstr =   counterTextObj.url;

    //PlaySound animation adds an empty toy. With url="" and width=0 and height=0
    if( ![urlstr isEqualToString:@""]) {
        UIImage *urlImage = [urlCache getImage:urlstr];
        [button setBackgroundImage:urlImage forState:UIControlStateNormal];
        [button setBackgroundImage:urlImage forState:UIControlStateSelected];
        [button setBackgroundImage:urlImage forState:UIControlStateHighlighted];
    }
//new ends

    [button setTitle:counterTextObj.text.text forState:UIControlStateNormal];
    [button setTitle:counterTextObj.text.text forState:UIControlStateSelected];

    UIColor *color = counterTextObj.text.color;
    if(color != nil) {
        [button setTitleColor:color forState:UIControlStateNormal];
        [button setTitleColor:color forState:UIControlStateSelected];
    }

    [button.titleLabel setFont:[UIFont systemFontOfSize:[[counterTextObj.text getSize] floatValue]]];
    
     
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;

    button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

    [button setContentMode:UIViewContentModeScaleAspectFit];//new
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;//new

    
    CGFloat xpos = counterTextObj.relativeX;
    CGFloat ypos = counterTextObj.relativeY;

    CGFloat width = counterTextObj.relativeWidth;
    CGFloat height = counterTextObj.relativeHeight;


    CGRect screenFrame = [Utility getScreenBoundsForOrientation];

    width = screenFrame.size.width * width/100;
    height = screenFrame.size.height * height/100;
    xpos = screenFrame.size.width * xpos/100;
    ypos = screenFrame.size.height * ypos/100 + ORIGIN_Y_SHIFT;


    button.frame = CGRectMake(xpos, ypos, width, height );

    if( counterTextObj.objectid!= nil) {
        [toyButtons setObject:button forKey:counterTextObj.objectid];
        [toyObjects setObject:counterTextObj forKey:counterTextObj.objectid];
    }

    [self.view addSubview:button];
    if( [@"yes" caseInsensitiveCompare:counterTextObj.hidden] == NSOrderedSame ) {
        [button setHidden:true];
    }
    
}

-(void) addEvent : (Event *) myEvent {
    NSString *objId = [myEvent getObjectId];
    NSString *eventType = [myEvent getEventType];
    if( [eventType isEqualToString:@"touchdown"]) {
        UIButton *myButton = [toyButtons objectForKey:objId];
        
        [myButton addTarget:self
                     action:@selector(buttonTouchDown:forEvent:)
           forControlEvents:UIControlEventTouchDown];
        NSString *buttonTag = [NSString stringWithFormat:@"%d",myButton.tag];
        NSString *key = @"touchdown__";
        key = [key stringByAppendingString:buttonTag];
        NSArray *val = [myEvent getAnimationList];
        if( val != nil) {
            [eventAnims setObject:val forKey:key];
        }

    }
    else if( [eventType isEqualToString:@"drag"]) {
        UIButton *myButton = [toyButtons objectForKey:objId];

        [myButton addTarget:self
                     action:@selector(buttonTouchDragInside:forEvent:)
           forControlEvents:UIControlEventTouchDragInside];
        NSString *buttonTag = [NSString stringWithFormat:@"%d",myButton.tag];
        NSString *key = @"drag__";
        key = [key stringByAppendingString:buttonTag];
        NSArray *val = [myEvent getAnimationList];
        if( val != nil) {
            [eventAnims setObject:val forKey:key];
        }
    }
    else if( [eventType isEqualToString:@"drop"]) {
        UIButton *myButton = [toyButtons objectForKey:objId];

        [myButton addTarget:self
                     action:@selector(buttonTouchUpInside:forEvent:)
           forControlEvents:UIControlEventTouchUpInside];
        NSString *buttonTag = [NSString stringWithFormat:@"%d",myButton.tag];
        NSString *key = @"drop__";
        key = [key stringByAppendingString:buttonTag];
        NSArray *val = [myEvent getAnimationList];
        if( val != nil) {
            [eventAnims setObject:val forKey:key];
        }
    }
    else if( [eventType isEqualToString:@"timer"]) {
        NSArray *val = [myEvent getAnimationList];
        BOOL repeats = YES;
        if( [myEvent.isRepeating isEqualToString:@"NO"]) {
            repeats = NO;
        }
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:myEvent.timerInterval
                                         target:self
                                       selector:@selector(runTimedAnimations:)
                                       userInfo:val
                                        repeats:repeats];
        [self.timers addObject:timer];
        
    }
    else if( [eventType isEqualToString:@"pageload"]) {
        NSArray *val = [myEvent getAnimationList];

        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                         target:self
                                       selector:@selector(runTimedAnimations:)
                                       userInfo:val
                                        repeats:NO];
        [self.timers addObject:timer];
    }
    else if([eventType isEqualToString:@"swipeleft"]) {
        UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeHandler:)];
        [gestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
        NSString *key = @"swipeleft__";
        if( objId == nil || [objId isEqualToString:@""]) {
            [self.view addGestureRecognizer:gestureRecognizer];
            NSString *buttonTag = [NSString stringWithFormat:@"%d",self.view.tag];
            key = [key stringByAppendingString:buttonTag];
            NSArray *val = [myEvent getAnimationList];
            if( val != nil) {
                [eventAnims setObject:val forKey:key];
            }
        }
        else {
            UIButton *myButton = [toyButtons objectForKey:objId];
            [myButton addGestureRecognizer:gestureRecognizer];
            NSString *buttonTag = [NSString stringWithFormat:@"%d",myButton.tag];
            key = [key stringByAppendingString:buttonTag];
            NSArray *val = [myEvent getAnimationList];
            if( val != nil) {
                [eventAnims setObject:val forKey:key];
            }
        }
    }
    else if([eventType isEqualToString:@"swiperight"]) {
        UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipeHandler:)];
        [gestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
        NSString *key = @"swiperight__";
        if( objId == nil || [objId isEqualToString:@""]) {
            [self.view addGestureRecognizer:gestureRecognizer];
            NSString *buttonTag = [NSString stringWithFormat:@"%d",self.view.tag];
            key = [key stringByAppendingString:buttonTag];
            NSArray *val = [myEvent getAnimationList];
            if( val != nil) {
                [eventAnims setObject:val forKey:key];
            }
        }
        else {
            UIButton *myButton = [toyButtons objectForKey:objId];
            [myButton addGestureRecognizer:gestureRecognizer];
            NSString *buttonTag = [NSString stringWithFormat:@"%d",myButton.tag];
            key = [key stringByAppendingString:buttonTag];
            NSArray *val = [myEvent getAnimationList];
            if( val != nil) {
                [eventAnims setObject:val forKey:key];
            }
        }
    }
    else if([eventType isEqualToString:@"swipeup"]) {
        UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(upSwipeHandler:)];
        [gestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
        NSString *key = @"swipeup__";
        if( objId == nil || [objId isEqualToString:@""]) {
            [self.view addGestureRecognizer:gestureRecognizer];
            NSString *buttonTag = [NSString stringWithFormat:@"%d",self.view.tag];
            key = [key stringByAppendingString:buttonTag];
            NSArray *val = [myEvent getAnimationList];
            if( val != nil) {
                [eventAnims setObject:val forKey:key];
            }
        }
        else {
            UIButton *myButton = [toyButtons objectForKey:objId];
            [myButton addGestureRecognizer:gestureRecognizer];
            NSString *buttonTag = [NSString stringWithFormat:@"%d",myButton.tag];
            key = [key stringByAppendingString:buttonTag];
            NSArray *val = [myEvent getAnimationList];
            if( val != nil) {
                [eventAnims setObject:val forKey:key];
            }
        }
    }
    else if([eventType isEqualToString:@"swipedown"]) {
        UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(downSwipeHandler:)];
        [gestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
        NSString *key = @"swipedown__";
        if( objId == nil || [objId isEqualToString:@""]) {
            [self.view addGestureRecognizer:gestureRecognizer];
            NSString *buttonTag = [NSString stringWithFormat:@"%d",self.view.tag];
            key = [key stringByAppendingString:buttonTag];
            NSArray *val = [myEvent getAnimationList];
            if( val != nil) {
                [eventAnims setObject:val forKey:key];
            }
        }
        else {
            UIButton *myButton = [toyButtons objectForKey:objId];
            [myButton addGestureRecognizer:gestureRecognizer];
            NSString *buttonTag = [NSString stringWithFormat:@"%d",myButton.tag];
            key = [key stringByAppendingString:buttonTag];
            NSArray *val = [myEvent getAnimationList];
            if( val != nil) {
                [eventAnims setObject:val forKey:key];
            }
        }
    }

}

-(void) runTimedAnimations : (NSTimer *) timer {
    NSArray *animArray = [timer userInfo];

    for( int i=0; i<[animArray count]; i++) {
        Animation *anim = [modelPage getAnimationById:animArray[i]];
        PageObject *pageObj = anim.pageObject;

        UIButton *buttonToAnimate = [toyButtons objectForKey:pageObj.objectid];
        AnimationRunner *runner = [AnimationRunner alloc];
        [runner initialize:anim];
        [self.runningAnimations setObject:runner forKey:anim.animId];
        UIButton *byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"byobject"]];
        if( byButton == nil) {
            byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"byObject"]];
        }
        if( byButton == nil) {
            byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"toobject"]];
        }
        if( byButton == nil) {
            byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"toObject"]];
        }

        if( byButton != nil ) {
            [runner run:buttonToAnimate:byButton];
        }
        else {
            [runner run:buttonToAnimate];
        }
        //pageload and timer with more than one animations do not work. Remove this break. Not sure why it is there.
        //break;
    }

}

-(void) addEvents {
    NSMutableArray *events = [modelPage getEvents];
    for( int i=0; i<[events count]; i++) {
        Event *myEvent = events[i];
        Condition *condition = myEvent.condition;
        if(condition == nil){
            [self addEvent:myEvent];
        }
        else if( [condition isValid]) {
            [self addEvent:myEvent];
        }
    }
    
    //Remove old observer first to ensure that we addObserver only one time. Else runChainAnimation will be called multiple times
    //for one postNotification request
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"runChainAnimation" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runChainAnimation:) name:@"runChainAnimation" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"resetObjectPosition" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetObjectPosition:) name:@"resetObjectPosition" object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"recordPageScore" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordPageScore:) name:@"recordPageScore" object:nil];

}

-(void) recordPageScore : (NSNotification *) notification {

    if( modelPage.tags != nil) {
        for( int i=0; i<[modelPage.tags count]; i++) {
            if( ![modelPage.tags[i] isEqualToString:@""]) {
                //If attemptsFiled is true, then only store solved value.
                //Eg in easter egg hunt activity, if no eggs collected, then also
                //because counter becomes 0 from 10, recordPageScore is called.
                //In that case, actually user has not solved this activity. But still solved is incremented.
                if( attemptFiled == true) {
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                    [dic setObject:@"SOLVED" forKey:@"eventType"];
                    [dic setObject:modelPage.tags[i] forKey:@"tag"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"IncrementColumnForTag" object:nil userInfo:dic];
                }
            }

        }
        //attemptFiled = true;
    }

 }

- (void)resetObjectPosition:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    PageObject *pageObj = [dictionary objectForKey:@"pageObject"];
    UIButton *oldButton = [toyButtons objectForKey:pageObj.objectid];
    
    //Sometimes when page turned before reset gets fully executed,
    //the buttons from this page get added to next page. Therefore checkin the current parent page.
    if( [oldButton superview] != self.view ) {
        return;
    }
    //Recreate the button. Just modifying the button does not work properly with image layers.
    //If just modify the position, then the image still shows up at wrong place. Only button frame gets set.
    //TODO: Need to research on this???
    
    UIButton *dataObjButton =   [UIButton buttonWithType:UIButtonTypeCustom];
        
    urlCache = [[URLCache alloc] init];
    UIImage *urlImage = [urlCache getImage:pageObj.url];
    [dataObjButton setImage:urlImage forState:UIControlStateNormal];
    [dataObjButton setImage:urlImage forState:UIControlStateSelected];
    [dataObjButton setImage:urlImage forState:UIControlStateHighlighted];


    [dataObjButton setTag:oldButton.tag];
    
    CGFloat width = pageObj.relativeWidth;
    CGFloat height = pageObj.relativeHeight;

    // This needs to be a PageObject that needs to be reset which has relative X and Y.
    CGFloat xpos = pageObj.relativeX;
    CGFloat ypos = pageObj.relativeY;
    
    [dataObjButton setContentMode:UIViewContentModeScaleAspectFit];
    dataObjButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    CGRect screenFrame = [Utility getScreenBoundsForOrientation];
    
    width = screenFrame.size.width * width / 100;
    height = screenFrame.size.height * height / 100;
    xpos = screenFrame.size.width * xpos / 100;
    ypos = screenFrame.size.height * ypos / 100 + ORIGIN_Y_SHIFT;
    
    
    dataObjButton.frame = CGRectMake(xpos, ypos, width, height );
    
    
    if( pageObj.objectid != nil) {
        [toyButtons setObject:dataObjButton forKey:pageObj.objectid];
        [toyObjects setObject:pageObj forKey:pageObj.objectid];
        
    }
     //Could not find a way to copy the events to newly created button. Therefore need to do this.
    //Copy all the evetns for the newly created button again.
    NSMutableArray *events = [modelPage getEvents];
    for( int i=0; i<[events count]; i++) {
        Event *myEvent = events[i];
        NSString *objId = [myEvent getObjectId];
        if( ![objId isEqualToString:pageObj.objectid]) {
            continue;
        }
        [self addEvent:myEvent];
    }
    //Sometimes when page turned before reset gets fully executed,
    //the buttons from this page get added to next page. Therefore checkin the current parent page.
    if( [oldButton superview] != self.view ) {
        return;
    }

    // removed the insertSubView and replaced with addSubView.
    // This might add the issue with ant taking apple, that the apple will come on top.
    // But in such cases we can always use the move animation. Eg done in Vowels book, bird eating corn cob case.
    [self.view addSubview:dataObjButton];

    //Remove old button after inserting new button. Else dora comes on top of door.
    //This is because door's index is one more than dora. So when dora is removed, door's index becomes that of dora.
     [oldButton removeFromSuperview];
    if( [@"yes" caseInsensitiveCompare:pageObj.hidden] == NSOrderedSame ) {
        [dataObjButton setHidden:true];
    }
   
}

- (void)runChainAnimation:(NSNotification *)notification {
   
    NSDictionary *dictionary = [notification userInfo];
    
    NSString *completedAnimId = [[dictionary allKeys] objectAtIndex:0];

    if( completedAnimId == nil) {
        return;
    }
       
    NSMutableArray *events = [modelPage getEvents];
    bool chainEnded = true;
    
    for( int i=0; i<[events count]; i++) {
        Event *myEvent = events[i];
        NSString *objId = [myEvent getObjectId];
        NSString *eventType = [myEvent getEventType];
        if( [eventType isEqualToString:@"done"]) {
            Animation *anim = [modelPage getAnimationById:objId];
            if( [anim.animId isEqualToString:completedAnimId]) {
                NSArray *chainAnims = [myEvent getAnimationList];
                for( int i=0; i<[chainAnims count]; i++) {
                    chainEnded = false;
                    Animation *anim = [modelPage getAnimationById:chainAnims[i]];

                    if( anim == nil) {
                        continue;
                    }
                
                    PageObject *pageObj = anim.pageObject;

                    
                    UIButton *buttonToAnimate = [toyButtons objectForKey:pageObj.objectid];

                    NSString *key = completedAnimId;
                    // Using buttonTag to append caused the bug that in Feed honey, readOne, readTwo etc did not get called.
                    //NSString *buttonTag = [NSString stringWithFormat:@"%d", buttonToAnimate.tag];
                    //key = [ key stringByAppendingString:buttonTag];
                    //To fix that use animId instead.
                    if( completedAnimId != nil && anim != nil) {
                        key = [ key stringByAppendingString:anim.animId];
                    }
                    
                    //This if condition code has messed up the playOne, playTwo number sounds logic in Teddy Honey feed activity.
                    //Basically the readOne, readTwo, readThree do not get called because of this continue logic.
                    //TODO: Need to look into this.
                    if([anim.type isEqualToString:@"counter"] && buttonToAnimate != nil && key != nil) {
                        if( [self hasEventAlreadyOccurred:key]) {
                            continue;
                        }
                    }

                    AnimationRunner *runner = [AnimationRunner alloc];
                    [runner initialize:anim];
                    [self.runningAnimations setObject:runner forKey:anim.animId];
                    if( [anim.type isEqualToString:@"changePage"] || [anim.type isEqualToString:@"closeBook"] ) {
                        [self recordTime];
                    }
                    else {
                        //[self recordAttempt];
                    }
                    
                    UIButton *byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"byobject"]];
                    if( byButton == nil) {
                        byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"byObject"]];
                    }
                    if( byButton == nil) {
                        byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"toobject"]];
                    }
                    if( byButton == nil) {
                        byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"toObject"]];
                    }

                    if( byButton != nil ) {
                        [runner run:buttonToAnimate:byButton];
                    }
                    else {
                        [runner run:buttonToAnimate];
                    }
                    //break; //WHY was this there?? It caused the bug that if with done event there are more than one animations added, only first one worked. Need to do thorough testing of why this break was there. Was it a typo??

                    //Similar to touchdown event, sometimes completed animations also trigger counter. Eg after playSound animation, increment counter.
                    //For that we need to also store the completed animations associated with any button
                    if( buttonToAnimate != nil && key != nil) {
                        [occurredEvents setObject:buttonToAnimate forKey:key];
                    }

                }

            }
            
        }

    }

}

// Google Analytics dispatch event
- (void)dispatch : (int) buttonTag : (NSString*) eventName {
    //Get objectid passing buttonTag
    NSString *buttonName = [self getToyButtonId:buttonTag];
    if(buttonName != nil) {
        NSMutableDictionary *event =
        [[GAIDictionaryBuilder createEventWithCategory:@"PageObject"
                                            action:eventName
                                            label:buttonName
                                            value:nil] build];
        [[GAI sharedInstance].defaultTracker send:event];
        [[GAI sharedInstance] dispatch];
    }
}

// button tag is just a number. To get the actual button/object's id from json, pass that
// buttonTag and get the objectid from the toyButtons.
-(NSString*) getToyButtonId : (int) buttonTag {
    for(id key in toyButtons) {
        UIButton *btn = [toyButtons objectForKey:key];
        if(btn.tag == buttonTag) {
            return key;
        }
    }
    return nil;
}

-(void)rightSwipeHandler:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Right Swipe received.");
    //if ( recognizer.state == UIGestureRecognizerStateEnded ) {
        UIButton *control = (UIButton *)[recognizer view];
        NSString *buttonTag = [NSString stringWithFormat:@"%d", control.tag];
        
        NSString *key = @"swiperight__";
        key = [ key stringByAppendingString:buttonTag];
        
        NSArray *anims = [eventAnims objectForKey:key];
        
        [self runAnimations:anims:key];
        
        [occurredEvents setObject:control forKey:key];
        [self dispatch:control.tag:@"swiperight"];
    //}
 }

 -(void)leftSwipeHandler:(UISwipeGestureRecognizer *)recognizer {
     NSLog(@"Left Swipe received.");
     UIButton *control = (UIButton *)[recognizer view];
     NSString *buttonTag = [NSString stringWithFormat:@"%d", control.tag];
     
     NSString *key = @"swipeleft__";
     key = [ key stringByAppendingString:buttonTag];
     
     NSArray *anims = [eventAnims objectForKey:key];
     
     [self runAnimations:anims:key];
     
     [occurredEvents setObject:control forKey:key];
     [self dispatch:control.tag:@"swipeleft"];

 }

-(void)upSwipeHandler:(UISwipeGestureRecognizer *)recognizer {
    //NSLog(@"up Swipe received.");
    UIButton *control = (UIButton *)[recognizer view];
    NSString *buttonTag = [NSString stringWithFormat:@"%d", control.tag];
    
    NSString *key = @"swipeup__";
    key = [ key stringByAppendingString:buttonTag];
    
    NSArray *anims = [eventAnims objectForKey:key];
    
    [self runAnimations:anims:key];
    
    [occurredEvents setObject:control forKey:key];
    [self dispatch:control.tag:@"swipeup"];

}

-(void)downSwipeHandler:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"down Swipe received.");
    UIButton *control = (UIButton *)[recognizer view];
    NSString *buttonTag = [NSString stringWithFormat:@"%d", control.tag];
    
    NSString *key = @"swipedown__";
    key = [ key stringByAppendingString:buttonTag];
    
    NSArray *anims = [eventAnims objectForKey:key];
    
    [self runAnimations:anims:key];
    
    [occurredEvents setObject:control forKey:key];
    [self dispatch:control.tag:@"swipedown"];

}

-(IBAction)buttonTouchUpInside:(id)sender forEvent:(UIEvent*)event {
    
    UIButton *control = sender;
    [self.view bringSubviewToFront:control];
    NSString *buttonTag = [NSString stringWithFormat:@"%d", control.tag];

    NSString *key = @"drop__";
    key = [ key stringByAppendingString:buttonTag];

    NSArray *anims = [eventAnims objectForKey:key];
    
    [self runAnimations:anims:key];

    [occurredEvents setObject:control forKey:key];
    //buttonTag is a int. How to get the id??
    [self dispatch:control.tag: @"touchup"];

}

-(IBAction)buttonTouchDragInside:(id)sender forEvent:(UIEvent*)event {
    
    UIButton *control = sender;

    [self.view bringSubviewToFront:control];
   
    NSString *buttonTag = [NSString stringWithFormat:@"%d", control.tag];
    
    NSString *key = @"drag__";
    key = [ key stringByAppendingString:buttonTag];
    
    NSArray *anims = [eventAnims objectForKey:key];
    
    [self runAnimations:anims:key];
    
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.view];
    control.center = point;
    
    [occurredEvents setObject:control forKey:key];
   
}

-(IBAction)buttonTouchDown:(id)sender forEvent:(UIEvent*)event {
    
    UIButton *control = sender;
    NSString *buttonTag = [NSString stringWithFormat:@"%d", control.tag];
    
    NSString *key = @"touchdown__";
    key = [ key stringByAppendingString:buttonTag];
    
    NSArray *anims = [eventAnims objectForKey:key];
    
    [self runAnimations:anims:key];

    [occurredEvents setObject:control forKey:key];
    [self dispatch:control.tag:@"touchdown"];

}

-(void) recordAttempt {
    if( attemptFiled == false ) {
        if( modelPage.tags != nil) {
            for( int i=0; i<[modelPage.tags count]; i++) {
                if( ![modelPage.tags[i] isEqualToString:@""] ){
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                    [dic setObject:@"ATTEMPTS" forKey:@"eventType"];
                    [dic setObject:modelPage.tags[i] forKey:@"tag"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"IncrementColumnForTag" object:nil userInfo:dic];
                }
            }
            attemptFiled = true;
        }
    }
}

-(void) recordTime {
    //Do we need to record time when attempts are 0?
    if( modelPage.tags != nil) {
        for( int i=0; i<[modelPage.tags count]; i++) {
            if( ![modelPage.tags[i] isEqualToString:@""] ) {//&& attemptFiled == false) {
                NSDate *curDate = [NSDate date];

                NSTimeInterval diff = [curDate timeIntervalSinceDate:self.pageLoadTime];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                [dic setObject:modelPage.tags[i] forKey:@"tag"];
                [dic setObject:[NSString stringWithFormat:@"%ld", (long)diff]  forKey:@"timeMillis"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AddTimeForTag" object:nil userInfo:dic];
            }
        }
        //attemptFiled = true;
    }

}

-(void) runAnimations : (NSArray *) anims : (NSString *) controlTag {
    for( int i=0; i<[anims count]; i++) {
        Animation *anim = [modelPage getAnimationById:anims[i]];
        PageObject *pageObj = anim.pageObject;
        NSString *animType = anim.type;
        UIButton *buttonToAnimate = [toyButtons objectForKey:pageObj.objectid];

        
        if([animType isEqualToString:@"counter"]) {

            if( [self hasEventAlreadyOccurred:controlTag]) {
                continue;
            }
        }

        // introduce toObject in Move animation. Also objectForKey is case sensitive. Make byObject and toObject case insensitive.
        //Therefore from both toobject and toObject will work
        UIButton *byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"byobject"]];
        if( byButton == nil) {
            byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"byObject"]];
        }
        if( byButton == nil) {
            byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"toobject"]];
        }
        if( byButton == nil) {
            byButton = [toyButtons objectForKey:[anim.anim objectForKey:@"toObject"]];
        }

        AnimationRunner *runner = [AnimationRunner alloc];
        [runner initialize:anim];
        [self.runningAnimations setObject:runner forKey:anim.animId];
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        [arr addObject:anim.animId];
        if( [anim.type isEqualToString:@"changePage"] || [anim.type isEqualToString:@"closeBook"] ) {
            [self recordTime];
        }
        else {
            [self recordAttempt];
        }
        if( byButton != nil) {
            [runner run:buttonToAnimate:byButton];
        }
        else {
            [runner run:buttonToAnimate];
        }
       
    }

}

-(BOOL) hasEventAlreadyOccurred : (NSString*) buttonTag {
    
    if([occurredEvents objectForKey:buttonTag] != nil)
    {
        return true;
    }
    return false;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self render];

    // Fixed the xcode 5 iOS7 landscape issue.
    // In xcode 5 compiled app, in landscape mode, right most buttons on PageViewController were not clickable.
    // Reason is that the view's width in that case is 768. So beyond that the events were not getting reached.
    // In landscape mode, we need width=1024. Therefore fixed that by getting correct width and height according to the mode
    // and set it to the view's frame.
    CGRect frame = [Utility getScreenBoundsForOrientation];
    self.view.frame = frame;
    
    self.screenName = [NSString stringWithFormat:@"%@ %@", self.book.bookId, self.modelPage.pageId];
}

- (void)viewWillDisappear:(BOOL)animated {

     [[NSNotificationCenter defaultCenter] removeObserver:self name:@"recordPageScore" object:nil];
    
    //BEFORE DOING SO CHECK THAT TIMER MUST NOT BE ALREADY INVALIDATED
    //Always nil your timer after invalidating so that
    //it does not cause crash due to duplicate invalidate
    for( int i=0; i < [self.timers count]; i++) {
        NSTimer *timer = self.timers[i];
        if(timer)
        {
            [timer invalidate];
            timer = nil;
        }
    }

    for(id key in self.runningAnimations) {
        AnimationRunner *value = [self.runningAnimations objectForKey:key];
        [value stop];
    }
    [super viewWillDisappear:animated];
}


- (BOOL)shouldAutorotate {

    return NO;
}


@end
