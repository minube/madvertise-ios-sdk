// Copyright 2012 madvertise Mobile Advertising GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MadvertiseSDKSampleViewController.h"
#import "MadvertiseView.h"
#import "MadvertiseSDKSampleDelegate.h"
#import "MadvertiseTracker.h"
#import "MadvertiseUtilities.h"

@implementation MadvertiseSDKSampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    1. Create a new MadvertiseSDKSampleDelegate.
//    
//    Some possible delegate methods:
//                               - (NSString *) appId : should return your SiteToken
//                               - (BOOL) debugEnabled : return YES to enable debug-mode
//                               - (CLLocationCoordinate2D) location : should return the location of the user
//                               - (NSString*) age : should return the age of the user
//                               - (NSString *) gender : should return the gender of the user
//                               - (BOOL) mRaidDisabled : return YES to disable MRaid ads

    MadvertiseSDKSampleDelegate *madvertiseDemoDelegate = [[[MadvertiseSDKSampleDelegate alloc] init] autorelease];
    
//    2. Create a new MadvertiseView. You can create multiple of them, e. g. one fixed and another in a ListView. 
//
//    withClass: MadvertiseAdClassMMA : 320x53
//               MadvertiseAdClassMediumRectangle : 300x250
//               MadvertiseAdClassLeaderboard : 728x90
//               MadvertiseAdClassPortrait : 766x66
//               MadvertiseAdClassLandscape : 1024x66
//    
//    secondsToRefresh: the time after which a new ad will be loaded

    // custom banner format ad
//    MadvertiseView *customBanner = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:MadvertiseAdClassMMA secondsToRefresh:30];
//    [customBanner place_at_x:0 y:0];
//    [self.view addSubview:customBanner];
//    [self.view bringSubviewToFront:customBanner];

    // ad with standard banner format
    MadvertiseView *banner = [MadvertiseView loadBannerWithDelegate:madvertiseDemoDelegate secondsToRefresh:30];
    [banner place_at_x:0 y:0];
    [self.view addSubview:banner];
    [self.view bringSubviewToFront:banner];

    // richmedia ad (overlay)
//    MadvertiseView *richmedia = [MadvertiseView loadRichMediaAdWithDelegate:madvertiseDemoDelegate];
//    [self.view addSubview:richmedia];
//    [self.view bringSubviewToFront:richmedia];

    // preloader
//    MadvertiseView *preloader = [MadvertiseView loadPreloaderAdWithDelegate:madvertiseDemoDelegate];
//    [self.view addSubview:preloader];
//    [self.view bringSubviewToFront:preloader];
}

- (void) viewWillAppear:(BOOL)animated {
//  observing adLoaded and adLoadFailed Events
    [MadvertiseView handlerWithObserver:self AndSelector:@selector(onAdLoadedSuccessfully:) ForEvent:@"MadvertiseAdLoaded"];
    [MadvertiseView handlerWithObserver:self AndSelector:@selector(onAdLoadedFailed:) ForEvent:@"MadvertiseAdLoadFailed"];
}

- (void) viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 
#pragma mark Notifications

- (void) onAdLoadedSuccessfully:(NSNotification*)notify {
    MadLog(@"ad successfully loaded");
}

- (void) onAdLoadedFailed:(NSNotification*)notify {
    MadLog(@"ad load failed");
}

@end