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

#import <CoreLocation/CoreLocation.h>

typedef enum tagMadvertiseAnimationClass {
    MadvertiseAnimationClassLeftToRight,
    MadvertiseAnimationClassTopToBottom,
    MadvertiseAnimationClassCurlDown,
    MadvertiseAnimationClassFade,
    MadvertiseAnimationClassNone
} MadvertiseAnimationClass;

@class MadvertiseView;

@protocol MadvertiseDelegationProtocol<NSObject>

// The appId is your token which associates this application with your site in the
// madvertise plattform. Log in under http://www.madvertise.de to get your appId.
@required
- (NSString *) appId;

@optional

- (double) durationOfBannerAnimation;               // 1.5 for example
- (MadvertiseAnimationClass) bannerAnimationType;   // curlDown, topToBottom, leftToRight, fade, none
- (void) inAppBrowserWillOpen;                      // YES | NO
- (void) inAppBrowserClosed;                        // YES | NO
- (BOOL) debugEnabled;                              // YES | NO
- (BOOL) mRaidDisabled;                             // YES | NO
- (BOOL) downloadTrackerEnabled;                    // YES | NO
- (NSString *) adServer;                            // default server is ad.madvertise.de.
- (CLLocationCoordinate2D) location;
- (NSString *) gender;                              // F | M 
- (NSString *) age;                                 // single number 1,2,.. || range 0-120


// This method is invoked when the banner has confirmation that an ad will be presented, but before the ad
// has loaded resources necessary for presentation.
-(void)bannerViewWillLoadAd:(UIView *)banner;

// This method is invoked each time a banner loads a new advertisement. Once a banner has loaded an ad,
// it will display that ad until another ad is available. The delegate might implement this method if
// it wished to defer placing the banner in a view hierarchy until the banner has content to display.
- (void)bannerViewDidLoadAd:(UIView *)banner;

// This method will be invoked when an error has occurred attempting to get advertisement content.
// The ADError enum lists the possible error codes.
- (void)bannerView:(UIView *)banner didFailToReceiveAdWithError:(NSError *)error;

// This message will be sent when the user taps on the banner and some action is to be taken.
// Actions either display full screen content in a modal session or take the user to a different
// application. The delegate may return NO to block the action from taking place, but this
// should be avoided if possible because most advertisements pay significantly more when
// the action takes place and, over the longer term, repeatedly blocking actions will
// decrease the ad inventory available to the application. Applications may wish to pause video,
// audio, or other animated content while the advertisement's action executes.
- (BOOL)bannerViewActionShouldBegin:(UIView *)banner willLeaveApplication:(BOOL)willLeave;

// This message is sent when a modal action has completed and control is returned to the application.
// Games, media playback, and other activities that were paused in response to the beginning
// of the action should resume at this point.
- (void)bannerViewActionDidFinish:(UIView *)banner;
@end
