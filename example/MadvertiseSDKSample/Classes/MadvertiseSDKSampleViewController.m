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

//  UIButton *btn= [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
//  btn.frame = CGRectMake(100, 100, 100, 25);
//  btn.backgroundColor = [UIColor clearColor];
//  [btn addTarget:self action:@selector(showAd:event:) forControlEvents:UIControlEventTouchUpInside];
//  [btn setTitle:@"Show ad" forState:UIControlStateNormal];
//  [self.view addSubview:btn]; 
//  [btn release];
//  
//  UIButton *btn2= [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
//  btn2.frame = CGRectMake(100, 200, 100, 25);
//  btn2.backgroundColor = [UIColor clearColor];
//  [btn2 addTarget:self action:@selector(removeAd:event:) forControlEvents:UIControlEventTouchUpInside];
//  [btn2 setTitle:@"Remove" forState:UIControlStateNormal];
//  [self.view addSubview:btn2]; 
//  [btn2 release];
  
//    Create a new MadvertiseSDKSampleDelegate
    
    madvertiseDemoDelegate = [[MadvertiseSDKSampleDelegate alloc] init];
    
//    Create a new MadvertiseView. You can create multiple of them, e. g. one fixed and another in a ListView. 
//    However, it is not recommended to use more than four of them. Futher more it is not recommended to use more than one RichMedia ad.
//
//    withClass: [MadvertiseAdClassMMA|MadvertiseAdClassMediumRectangle|MadvertiseAdClassLeaderboard|
//                  MadvertiseAdClassFullscreen|MadvertiseAdClassPortrait|MadvertiseAdClassLandscape|MadvertiseAdClassRichMedia], the ad type.
//    secondsToRefresh: [integer], the time after which a new ad will be loaded.
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        /* run something specific for the iPad */
        
        ad = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:MadvertiseAdClassPortrait placementType:MRAdViewPlacementTypeInline secondsToRefresh:30];
    } else {
        /* run something specific for the iPhone */
        
        ad = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:MadvertiseAdClassMMA placementType:MRAdViewPlacementTypeInline secondsToRefresh:30];
//        ad = [MadvertiseView loadRichMediaAdWithDelegate:madvertiseDemoDelegate];
    }
    
    [ad place_at_x:0 y:0];
    [self.view addSubview:ad];
    [self.view bringSubviewToFront:ad];
}

- (void) viewWillAppear:(BOOL)animated {
    //observing adLoaded, adLoadFailed and adRichMediaClose Events
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
    MadLog(@"successfully loaded with code: %@",[notify object]);
}

- (void) onAdLoadedFailed:(NSNotification*)notify {
    MadLog(@"ad load faild with code: %@",[notify object]);
}


//- (void)showAd:(id)sender event:(id)event
//{
//    if (ad) {
//        return;
//    }
//    
//    madvertiseDemoDelegate = [[MadvertiseSDKSampleDelegate alloc] init];
//    ad = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:MadvertiseAdClassMMA secondsToRefresh:30];
//    //ad = [MadvertiseView loadRichMediaAdWithDelegate:madvertiseDemoDelegate];
//    
//    [ad place_at_x:0 y:0];
//    [self.view addSubview:ad];
//    [self.view bringSubviewToFront:ad];
//}

//- (void)removeAd:(id)sender event:(id)event
//{
//    if(ad) {
//        [ad removeFromSuperview];
//    }
//    
//    ad = nil; 
//}

@end
