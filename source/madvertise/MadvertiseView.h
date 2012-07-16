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

#import <UIKit/UIKit.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>

#import "MadvertiseUtilities.h"
#import "MadvertiseAd.h"
#import "MadvertiseTracker.h"
#import "MadvertiseDelegationProtocol.h"
#import "JSONKit.h"
#import "MRAdView.h"
#import "MPAdBrowserController.h"

// enum of available banner formats
typedef enum tagMadvertiseAdClass {
    MadvertiseAdClassMMA,
    MadvertiseAdClassMediumRectangle,
    MadvertiseAdClassLeaderboard,
    MadvertiseAdClassFullscreen,
    MadvertiseAdClassPortrait,
    MadvertiseAdClassLandscape,
    MadvertiseAdClassRichMedia,
    MadvertiseAdClassIphonePreloader,
    MadvertiseAdClassIpadPreloader,
    MadvertiseAdClassIphonePreloaderLandscape,
    MadvertiseAdClassIpadPreloaderPortrait
} MadvertiseAdClass;

@class MadvertiseAd;

@interface MadvertiseView : UIView<MRAdViewDelegate> {
    id<MadvertiseDelegationProtocol> madDelegate;
    NSMutableData* receivedData;
    NSMutableURLRequest* request;  
    NSURLConnection *conn;
    MadvertiseAdClass currentAdClass;
    MRAdViewPlacementType placementType;
    NSInteger responseCode;
    MRAdView* currentView;
    MRAdView* nextView;
    NSLock* lock;
    NSTimer* timer;
    double interval;
    Boolean reload;
    int x, y;
    double animationDuration;
    MadvertiseAnimationClass animationType;
    Boolean suspended;
    NSString *server_url;
}

@property (nonatomic, assign) id<MadvertiseDelegationProtocol> madDelegate;
@property MadvertiseAdClass currentAdClass;
@property (nonatomic, retain) NSMutableURLRequest *request;
@property (nonatomic, retain) MRAdView *currentView;
@property (nonatomic, retain) MRAdView *nextView;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSURLConnection *conn;
@property (nonatomic, retain) NSMutableData *receivedData;

- (MadvertiseView*)initWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue placementType:(MRAdViewPlacementType) type secondsToRefresh:(int)secondsToRefresh;
- (CGSize)getParentViewDimensions;

+ (MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue placementType:(MRAdViewPlacementType) type secondsToRefresh:(int)secondsToRefresh;
+ (MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh;
+ (MadvertiseView*)loadBannerWithDelegate:(id<MadvertiseDelegationProtocol>)delegate secondsToRefresh:(int)secondsToRefresh;
+ (MadvertiseView*)loadRichMediaAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate;
+ (MadvertiseView*)loadPreloaderAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate closeButton:(Boolean)close timeToClose:(int)time;
+ (MadvertiseView*)loadPreloaderAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate closeButton:(Boolean)close;
+ (MadvertiseView*)loadPreloaderAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate;

+ (void)handlerWithObserver:(id) observer AndSelector:(SEL) selector ForEvent:(NSString*) event;
- (void)place_at_x:(int)x_pos y:(int)y_pos;
- (UIViewController *)viewControllerForPresentingModalView;

@end
