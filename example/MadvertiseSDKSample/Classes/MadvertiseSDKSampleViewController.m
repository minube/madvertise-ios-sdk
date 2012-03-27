// Copyright 2011 madvertise Mobile Advertising GmbH
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

MadvertiseView *ad;

- (void)dealloc {
    if (madvertiseDemoDelegate) {
        [madvertiseDemoDelegate release];
    }
    
    [super dealloc];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
//    Create a new MadvertiseSDKSampleDelegate.
//    
//    Some possible delegate methods:
//                               - (NSString *) appId : should return your SiteToken
//                               - (BOOL) debugEnabled : return YES to enable debug-mode
//                               - (CLLocationCoordinate2D) location : should return the location of the user
//                               - (NSString*) age : should return the age of the user
//                               - (NSString *) gender : should return the gender of the user
//                               - (BOOL) mRaidDisabled : return YES to disable MRaid ads
    
    madvertiseDemoDelegate = [[MadvertiseSDKSampleDelegate alloc] init];
    
//    Create a new MadvertiseView. You can create multiple of them, e. g. one fixed and another in a ListView. 
//
//    withClass: MadvertiseAdClassMMA : 320x53
//               MadvertiseAdClassMediumRectangle : 300x250
//               MadvertiseAdClassLeaderboard : 728x90
//               MadvertiseAdClassPortrait : 766x66
//               MadvertiseAdClassLandscape : 1024x66
//               MadvertiseAdClassFullscreen : 768x768
//    
//    secondsToRefresh: the time after which a new ad will be loaded
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        /* run something specific for the iPad */
        
//        ad = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:MadvertiseAdClassPortrait placementType:MRAdViewPlacementTypeInline secondsToRefresh:30];
    } else {
        /* run something specific for the iPhone */
        
        ad = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:MadvertiseAdClassMMA placementType:MRAdViewPlacementTypeInterstitial secondsToRefresh:30];
//        ad = [MadvertiseView loadRichMediaAdWithDelegate:madvertiseDemoDelegate]; // fullscreen richmedia ad (overlay)
        
        [ad place_at_x:0 y:0];
        [self.view addSubview:ad];
        [self.view bringSubviewToFront:ad];
    }
}

- (void) viewWillAppear:(BOOL)animated {
//  observing adLoaded and adLoadFailed Events
    [MadvertiseView handlerWithObserver:self AndSelector:@selector(onAdLoadedSuccessfully:) ForEvent:@"MadvertiseAdLoaded"];
    [MadvertiseView handlerWithObserver:self AndSelector:@selector(onAdLoadedFailed:) ForEvent:@"MadvertiseAdLoadFailed"];
    
//  furthermore it is possible to observe the following MRaid events:
//            MadvertiseMRaidAppShouldSuspend : app should suspend (there will be an ad event)
//            MadvertiseMRaidAppShouldResume : app should resume
//    
//  Please see MadvertiseView.m for more events.  
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
    MadLog(@"successfully loaded with code: %@",[notify object]);
}

- (void) onAdLoadedFailed:(NSNotification*)notify {
    MadLog(@"ad load faild with code: %@",[notify object]);
}

@end
