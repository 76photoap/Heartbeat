//
//  ResultsViewController.m
//  Heartbeat
//
//  Created by michael leybovich on 10/8/13.
//  Copyright (c) 2013 michael leybovich. All rights reserved.
//

#import "ResultsViewController.h"
#import "ResultCollectionViewCell.h"
#import "Result.h"
#import <FacebookSDK/FacebookSDK.h>

@interface ResultsViewController () <UICollectionViewDataSource, UIActionSheetDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *resultCollectionView;
//@property (nonatomic, strong) NSNumber *numOfResults;
@property (nonatomic) int resultsNumOld;

@property (nonatomic, strong) NSIndexPath *deleteIndex;

@end

typedef void (^RPSBlock)(void);

@implementation ResultsViewController {
    RPSBlock _alertOkHandler;
}

- (IBAction)clickFacebookButton:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Facebook"
                                                       delegate:self
                                              cancelButtonTitle:@"Do Nothing"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Share on Facebook", @"Check settings",  nil];
    // Show the sheet
    [sheet showInView:sender];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0) { // ok
        if (_alertOkHandler) {
            _alertOkHandler();
            _alertOkHandler = nil;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: { // share
            BOOL didDialog = NO;
            didDialog = [self shareResult];
            
            if (!didDialog) {
                [self alertWithMessage:
                 @"Upgrade the Facebook application on your device and "
                 @"get cool new sharing features for this application. "
                 @"What do you want to do?"
                                    ok:@"Upgrade Now"
                                cancel:@"Decide Later"
                            completion:^{
                                // launch itunes to get the Facebook application installed/upgraded
                                [[UIApplication sharedApplication]
                                 openURL:[NSURL URLWithString:@"itms-apps://itunes.com/apps/Facebook"]];
                            }];
            }
            break;
        }
        case 1: // settings
            [self.navigationController pushViewController:[[FBUserSettingsViewController alloc] init] animated:YES];
            break;
    }
}

//

- (BOOL)shareResult {
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject openGraphActionForPost];
    
    return nil !=
    [FBDialogs presentShareDialogWithOpenGraphAction:action
                                          actionType:@"bpm:"
                                 previewPropertyName:@"bpm"
                                             handler:nil];
}

//

- (void)requestPermissionsWithCompletion:(RPSBlock)completion {
    [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                          defaultAudience:FBSessionDefaultAudienceEveryone
                                        completionHandler:^(FBSession *session, NSError *error) {
                                            if (!error) {
                                                // Now have the permission
                                                completion();
                                            } else {
                                                NSLog(@"Error: %@", error.description);
                                            }
                                        }];
}

- (void)alertWithMessage:(NSString *)message
                      ok:(NSString *)ok
                  cancel:(NSString *)cancel
              completion:(RPSBlock)completion {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Share with Facebook"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:cancel
                                              otherButtonTitles:ok, nil];
    _alertOkHandler = [completion copy];
    [alertView show];
}

- (void)publishResult {
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    NSMutableDictionary<FBOpenGraphObject> *result = [self createResultObject];
    FBRequest *objectRequest = [FBRequest requestForPostOpenGraphObject:result];
    [connection addRequest:objectRequest
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             if (error) {
                 NSLog(@"Error: %@", error.description);
             }
         }
            batchEntryName:@"objectCreate"];
    
    /*
     NSMutableDictionary<FBGraphObject> *action = [self createPlayActionWithGame:@"{result=objectCreate:$.id}"];
     FBRequest *actionRequest = [FBRequest requestForPostWithGraphPath:@"me/fb_sample_rps:play"
     graphObject:action];
     [connection addRequest:actionRequest
     completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
     if (error) {
     NSLog(@"Error: %@", error.description);
     } else {
     NSLog(@"Posted OG action with id: %@", result[@"id"]);
     }
     }];
     */
    
    [connection start];
}

- (NSMutableDictionary<FBOpenGraphObject> *)createResultObject {
    
    NSString *resultName = @"60";// should be the bpm result
    
    NSMutableDictionary<FBOpenGraphObject> *result = [FBGraphObject openGraphObjectForPost];
    result[@"type"] = @"Heartbeat:bpm";
    result[@"title"] = @"Heartbeat";
    result[@"data"][@"result"] = resultName;
    
    return result;
}

- (void)scrollToTop
{
    NSUInteger indexes[2];
    indexes[0] = 0;
    indexes[1] = 0;
    NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
    
    if ([self.resultCollectionView numberOfItemsInSection:0]) {
        [self.resultCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    }
}

- (NSArray *)resultsByDate
{
    return [[Result allResults] sortedArrayUsingSelector:@selector(compareByDate:)];
}

- (int)numOfResults
{
    return [[Result allResults] count];
}

/*- (NSNumber *)numOfResults
{
    if (!_numOfResults) _numOfResults = @(10);
    return _numOfResults;
}*/

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
#warning need to update this later
    return [self numOfResults];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Result" forIndexPath:indexPath];
    
    [self updateCell:cell usingResult:[self resultsByDate][indexPath.item] ];

    return cell;
}

- (void)updateCell:(UICollectionViewCell *)cell usingResult:(Result *)result
{
    if ([cell isKindOfClass:[ResultCollectionViewCell class]]) {
        ResultView *resultView = ((ResultCollectionViewCell *)cell).resultView;
        
        resultView.bpm = result.bpm;
        resultView.date = result.end;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.resultsNumOld == [self numOfResults] - 1) {
        NSUInteger indexes[2];
        indexes[0] = 0;
        indexes[1] = 0;
        NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];

        [self.resultCollectionView insertItemsAtIndexPaths:@[indexPath]];
        
        [self.resultCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    }
    self.resultsNumOld = [self numOfResults];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = @"תוצאות";
    
    //------------------DESIGN BLOCK-----------------

    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        // navigation bar configuration
        ///*
        // A slightly darker color - facebook like
        //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0 green:0.245 blue:0.67 alpha:1.0];
        
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.075 green:0.439 blue:0.753 alpha:1.0];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    }
    
    //-----------------------------------------------
    
    self.resultsNumOld = [self numOfResults];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// UIActionSheetDelegate methods

#define SWIPE_ACTION_SHEET_TAG 0
#define FACEBOOK_ACTION_SHEET_TAG 1

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == SWIPE_ACTION_SHEET_TAG) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [((Result *)[[self resultsByDate] objectAtIndex:self.deleteIndex.item]) deleteFromResults];
            
            self.resultsNumOld = [self numOfResults];
            [self.resultCollectionView deleteItemsAtIndexPaths:@[self.deleteIndex]];
        }
    }
    else if (actionSheet.tag == FACEBOOK_ACTION_SHEET_TAG) {
        // do nothing
    }
}

- (IBAction)swipeResult:(UISwipeGestureRecognizer *)gesture
{
    ///*
    CGPoint swipeLocation = [gesture locationInView:self.resultCollectionView];
    NSIndexPath *indexPath = [self.resultCollectionView indexPathForItemAtPoint:swipeLocation];
    
    if (indexPath) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"בטל"
                                                   destructiveButtonTitle:@"מחק תוצאה"
                                                        otherButtonTitles:nil];
        [actionSheet setTag:SWIPE_ACTION_SHEET_TAG];// used the distinguish between the actionSheets
        
        [self.resultCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
        
        self.deleteIndex = indexPath;
    }
    //*/
}

@end
