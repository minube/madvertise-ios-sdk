
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

#import "MadvertiseView.h"

@implementation MadvertiseView

@synthesize request;
@synthesize currentView;
@synthesize nextView;
@synthesize timer;
@synthesize conn;
@synthesize receivedData;
@synthesize madDelegate;
@synthesize currentAdClass;
@synthesize bannerLoaded=_bannerLoaded;
NSString *const MadvertiseAdClass_toString[] = {
    @"mma",
    @"medium_rectangle",
    @"leaderboard",
    @"fullscreen",
    @"portrait",
    @"landscape",
    @"rich_media",
    @"iphone_preloader",
    @"ipad_preloader",
    @"iphone_preloader_landscape",
    @"ipad_preloader_portrait"
};

int const MadvertiseAdClass_toWidth[] = {
    320,
    300,
    728,
    768,
    766,
    1024,
    320,
    320,
    1024,
    480,
    768
};

int const MadvertiseAdClass_toHeight[] = {
    53,
    250,
    90,
    768,
    66,
    66,
    480,
    460,
    748,
    300,
    1004
};

+ (MadvertiseView*)loadRichMediaAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate {
    return [MadvertiseView loadAdWithDelegate:delegate withClass:MadvertiseAdClassRichMedia placementType:MRAdViewPlacementTypeInterstitial secondsToRefresh:-1];
}

+ (MadvertiseView*)loadPreloaderAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate closeButton:(Boolean)close timeToClose:(int)time {
    // handle special case
    if (!close && time == -1) {
        close = YES;
    }

    MadvertiseAdClass class = MadvertiseAdClassIphonePreloader;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        class = MadvertiseAdClassIpadPreloader;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        class = MadvertiseAdClassIpadPreloaderPortrait;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        class = MadvertiseAdClassIphonePreloaderLandscape;
    }

    MRAdViewPlacementType placement = MRAdViewPlacementTypeInline;
    if (close) {
        placement = MRAdViewPlacementTypeInterstitial;
    }

    return [MadvertiseView loadAdWithDelegate:delegate withClass:class placementType:placement secondsToRefresh:time];
}

+ (MadvertiseView*)loadPreloaderAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate closeButton:(Boolean)close {
    return [MadvertiseView loadPreloaderAdWithDelegate:delegate closeButton:close timeToClose:5];
}

+ (MadvertiseView*)loadPreloaderAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate {
    return [MadvertiseView loadPreloaderAdWithDelegate:delegate closeButton:NO];
}

+ (MadvertiseView*)loadBannerWithDelegate:(id<MadvertiseDelegationProtocol>)delegate secondsToRefresh:(int)secondsToRefresh {
    MadvertiseAdClass class = MadvertiseAdClassMMA;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        class = MadvertiseAdClassLandscape;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        class = MadvertiseAdClassPortrait;
    }

    return [MadvertiseView loadAdWithDelegate:delegate withClass:class secondsToRefresh:secondsToRefresh];
}

+ (MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh {
    return [MadvertiseView loadAdWithDelegate:delegate withClass:adClassValue placementType:MRAdViewPlacementTypeInline secondsToRefresh:secondsToRefresh];
}

+ (MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue placementType:(MRAdViewPlacementType) type secondsToRefresh:(int)secondsToRefresh {
    return [[[MadvertiseView alloc] initWithDelegate:delegate withClass:adClassValue placementType:type secondsToRefresh:secondsToRefresh] autorelease];
}

+ (void) handlerWithObserver:(id) observer AndSelector:(SEL) selector ForEvent:(NSString*) event {
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:event object:nil];
}

- (void) dealloc {
    MadLog(@"Call dealloc in MadvertiseView");

    if (self.timer && [self.timer isValid]) {
        [self.timer invalidate];
    }

    [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationDidBecomeActiveNotification object:nil];

    [self.conn cancel];
    self.conn = nil;
    self.request = nil;
    self.receivedData = nil;

    if (currentView) {
        currentView.delegate = nil;
    }
    [currentView release]; currentView = nil;

    if (nextView) {
        nextView.delegate = nil;
    }
    [nextView release]; nextView = nil;

    [lock release]; lock = nil;
    madDelegate = nil;

    [super dealloc];
}

- (MadvertiseView*)initWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue placementType:(MRAdViewPlacementType) type secondsToRefresh:(int)secondsToRefresh {
    BOOL enableDebug = NO;

#ifdef DEBUG
    enableDebug = YES;
#endif

    madDelegate = delegate;

    // debugging
    if ([madDelegate respondsToSelector:@selector(debugEnabled)]) {
        enableDebug = [madDelegate debugEnabled];
    }

    // Download-Tracker
    if ([madDelegate respondsToSelector:@selector(downloadTrackerEnabled)] && [madDelegate respondsToSelector:@selector(appId)]) {
        if ([madDelegate downloadTrackerEnabled] == YES) {
            [MadvertiseTracker setDebugMode: enableDebug];
            [MadvertiseTracker enableWithToken:[madDelegate appId]];
        }
    }

    if ((self = [super init])) {        
        self.clipsToBounds = YES;

        currentView = [[MRAdView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) 
                                      allowsExpansion:YES
                                     closeButtonStyle:MRAdViewCloseButtonStyleAdControlled
                                        placementType:placementType];
        [self addSubview: currentView];
        [self setHidden:YES];

        currentAdClass      = adClassValue;
        interval            = secondsToRefresh;
        reload              = YES;
        suspended           = NO;
        request             = nil;
        receivedData        = nil;
        responseCode        = 200;
        placementType       = type;
        animationDuration   = 0.5;
        animationType       = MadvertiseAnimationClassCurlDown;
        server_url          = @"http://ad.madvertise.de";
        lock                = [[NSLock alloc] init];
        _bannerLoaded       = NO;

        if ([madDelegate respondsToSelector:@selector(durationOfBannerAnimation)]) {
            animationDuration = [madDelegate durationOfBannerAnimation];
        }

        if ([madDelegate respondsToSelector:@selector(bannerAnimationType)]) {
            animationType = [madDelegate bannerAnimationType];
        }

        if ([madDelegate respondsToSelector:@selector(adServer)]) {
            server_url = [madDelegate adServer];
        }

        // handle special cases
        if (currentAdClass == MadvertiseAdClassRichMedia) {
            interval = -1;
            animationType = MadvertiseAnimationClassNone;
            animationDuration = 0.0;
        } else if (currentAdClass == MadvertiseAdClassIphonePreloader ||
                   currentAdClass == MadvertiseAdClassIpadPreloader ||
                   currentAdClass == MadvertiseAdClassIpadPreloaderPortrait ||
                   currentAdClass == MadvertiseAdClassIphonePreloaderLandscape) {
            reload = NO;
        }

        // load first ad
        [self loadAd];
            
        // Notifications for reloadable ad classes
        if (reload) {
            [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(stopTimer) name:UIApplicationDidEnterBackgroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(createAdReloadTimer) name:UIApplicationDidBecomeActiveNotification object:nil];
        }
    }

    return self;
}

- (void)place_at_x:(int) x_pos y:(int) y_pos {
    x = x_pos;
    y = y_pos;

    if (currentAdClass == MadvertiseAdClassRichMedia) {
        x = 0;
        y = 0;
    }
}
- (BOOL)isBannerLoaded{
    return _bannerLoaded;
}
#pragma mark - server connection handling

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    MadLog(@"%@ %i", @"Received response code: ", [response statusCode]);
    responseCode = [response statusCode];
    [receivedData setLength:0];
    
    if ([madDelegate respondsToSelector:@selector(debugEnabled)] && [madDelegate debugEnabled]) {
        MadLog(@"%@",[[response allHeaderFields] objectForKey:@"X-Madvertise-Debug"]);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    MadLog(@"Received data from Ad Server");
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    MadLog(@"Failed to receive ad");
    MadLog(@"%@",[error description]);
    _bannerLoaded = NO;
    self.request = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoadFailed" object:self];

    [lock unlock];
    [self createAdReloadTimer];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (responseCode == 200) {
        _bannerLoaded = YES;
        MadLog(@"Deserializing json");

        NSDictionary *dictionary = [receivedData objectFromJSONData];
        
        if (madDelegate) {
            [madDelegate bannerViewWillLoadAd:self];
        }
        MadLog(@"Creating ad");
        MadvertiseAd *ad = [[MadvertiseAd alloc] initFromDictionary:dictionary];
        [ad autorelease];
        [self createNewViewWithAd:ad];
    } else {
        _bannerLoaded = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoadFailed" object:self];
    }

    self.request = nil;
    self.receivedData = nil;
    [lock unlock];
}

- (void)loadAd {
    if (![lock tryLock]) {
        return;
    }

    MadLog(@"Load ad");

    if (self.request || suspended) {
        MadLog(@"Load ad - returning because another request is running.");
        [lock unlock];
        return;
    }

    if (![madDelegate respondsToSelector:@selector(appId)]) {
        MadLog(@"Load ad - returning because delegate is missing.");
        [lock unlock];
        [self createAdReloadTimer];
        return;
    }

    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/site/%@", server_url, [madDelegate appId]]];

    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];

    NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];
    [headers setValue:@"application/x-www-form-urlencoded; charset=utf-8" forKey:@"Content-Type"];
    [headers setValue:@"application/vnd.madad+json; version=3" forKey:@"Accept"];

    MadLog(@"ua: %@", UserAgentString());

    NSMutableDictionary* post_params = [[NSMutableDictionary alloc] init];
    self.receivedData = [NSMutableData data];

    CGSize parent_size = [self getParentViewDimensions];
    CGSize screen_size = [MadvertiseUtilities getScreenResolution];

    [post_params setValue: @"true"                                       forKey:MADVERTISE_APP_KEY];
    [post_params setValue: [MadvertiseUtilities getMacMD5Hash]           forKey:MADVERTISE_MACMD5_KEY];
    [post_params setValue: [MadvertiseUtilities getMacSHA1Hash]          forKey:MADVERTISE_MACSHA1_KEY];
    [post_params setValue: [MadvertiseUtilities getIdentifierForAdvertiser] forKey:MADVERTISE_ADVERTISER_IDENTIFIER_KEY];
    [post_params setValue: [MadvertiseUtilities getIP]                   forKey:MADVERTISE_IP_KEY];
    [post_params setValue: @"json"                                       forKey:MADVERTISE_FORMAT_KEY];
    [post_params setValue: @"iPhone-SDK "                                forKey:MADVERTISE_REQUESTER_KEY];
    [post_params setValue: MADVERTISE_SDK_VERION                         forKey:MADVERTISE_SDK_VERION_KEY];
    [post_params setValue: [MadvertiseUtilities getTimestamp]            forKey:MADVERTISE_TIMESTAMP_KEY];
    [post_params setValue: MadvertiseAdClass_toString[currentAdClass]    forKey:MADVERTISE_BANNER_TYPE_KEY];
    [post_params setValue: [MadvertiseUtilities getAppName]              forKey:MADVERTISE_APP_NAME_KEY];
    [post_params setValue: [MadvertiseUtilities getAppVersion]           forKey:MADVERTISE_APP_VERSION_KEY];
    [post_params setValue: [NSNumber numberWithFloat:parent_size.width]  forKey:MADVERTISE_PARENT_WIDTH_KEY];
    [post_params setValue: [NSNumber numberWithFloat:parent_size.height] forKey:MADVERTISE_PARENT_HEIGHT_KEY];
    [post_params setValue: [NSNumber numberWithFloat:screen_size.width]  forKey:MADVERTISE_DEVICE_WIDTH_KEY];
    [post_params setValue: [NSNumber numberWithFloat:screen_size.height] forKey:MADVERTISE_DEVICE_HEIGHT_KEY];
    [post_params setValue: [MadvertiseUtilities getDeviceOrientation]    forKey:MADVERTISE_ORIENTATION_KEY];
    [post_params setValue: [MadvertiseUtilities urlEncodeUsingEncoding:NSUTF8StringEncoding withString:UserAgentString()] forKey:MADVERTISE_USER_AGENT_KEY];
    [post_params setValue: (([madDelegate respondsToSelector:@selector(debugEnabled)] && [madDelegate debugEnabled]) ? @"true" : @"false") forKey:MADVERTISE_DEBUG_KEY];

    if (!([madDelegate respondsToSelector:@selector(mRaidDisabled)] && [madDelegate mRaidDisabled])) {
        [post_params setValue: @"true"                                forKey:MADVERTISE_MRAID_KEY];
    }
    if ([madDelegate respondsToSelector:@selector(location)]) {
        CLLocationCoordinate2D location = [madDelegate location];
        [post_params setValue:[NSString stringWithFormat:@"%.6f", location.longitude] forKey:MADVERTISE_LNG_KEY];
        [post_params setValue:[NSString stringWithFormat:@"%.6f", location.latitude] forKey:MADVERTISE_LAT_KEY];
    }
    if ([madDelegate respondsToSelector:@selector(gender)]) {
        NSString *gender = [madDelegate gender];
        [post_params setValue:gender forKey:MADVERTISE_GENDER_KEY];
        MadLog(@"gender: %@", gender);
    }
    if ([madDelegate respondsToSelector:@selector(age)]) {
        NSString *age = [madDelegate age];
        [post_params setValue:age forKey:MADVERTISE_AGE_KEY];
        MadLog(@"%@", age);
    }

    NSString *body = @"";
    unsigned int n = 0;

    for (NSString* key in post_params) {
        body = [body stringByAppendingString:[NSString stringWithFormat:@"%@=%@", key, [post_params objectForKey:key]]];
        if (++n != [post_params count] ) {
            body = [body stringByAppendingString:@"&"];
        }
    }

    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    MadLog(@"Sending request");

    self.conn = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
    MadLog(@"Request send");

    [headers release];
    [post_params release];
}

- (void)stopTimer {
    if (self.timer && [self.timer isValid] && reload) {
        MadLog(@"Stop Ad reload timer");
        [self.timer invalidate];
    }
}

- (void)createAdReloadTimer {
    if (suspended) {
        return;
    }

    if (interval > 0 && (!self.timer || ![self.timer isValid])) {
        MadLog(@"Init Ad reload timer");
        self.timer = [NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(timerFired:) userInfo: nil repeats: NO];
    }

    if (!reload) {
        interval = -1;
    }
}

- (void)timerFired: (NSTimer *) theTimer {
    MadLog(@"Timer fired.");
    [self.timer invalidate];

    if (reload) {
        [self loadAd];
    } else {
        [self setHidden:YES];
    }
}

- (void) createNewViewWithAd: (MadvertiseAd *) ad {
    MadLog(@"Create new ad view");

    if (ad == nil || !ad.isValid || suspended) {
        MadLog(@"No ad to show or reloading suspended");
        return;
    }

    self.frame = CGRectMake(x, y , ([ad width] != 0) ? [ad width] : MadvertiseAdClass_toWidth[currentAdClass], ([ad height] != 0) ? [ad height] : MadvertiseAdClass_toHeight[currentAdClass]);

    CGRect frame = CGRectMake(0, 0, ([ad width] != 0) ? [ad width] : MadvertiseAdClass_toWidth[currentAdClass], ([ad height] != 0) ? [ad height] : MadvertiseAdClass_toHeight[currentAdClass]);

    nextView = [[MRAdView alloc] initWithFrame:frame 
                               allowsExpansion:YES
                              closeButtonStyle:MRAdViewCloseButtonStyleAdControlled
                                 placementType:placementType];
    nextView.delegate = self;

    if ([ad isLoadableViaUrl]) {
        [nextView loadCreativeFromURL:[ad url]];
    }
    else {
        [nextView loadCreativeWithHTMLString:[ad to_html] baseURL:nil];
    }
}

- (void)swapViews {
     MadLog(@"Swap ad views");

    if (suspended) {
        MadLog(@"Reload suspended");
        return;
    }

    UIViewAnimationTransition transition = UIViewAnimationTransitionNone;
    float newStartAlpha = 1;
    float newEndAlpha = 1;
    float oldEndAlpha = 1;
    CGRect newStart = [nextView frame];
    CGRect newEnd = [nextView frame];
    CGRect oldEnd = [currentView frame];

    switch (animationType) {
        case MadvertiseAnimationClassLeftToRight:
            newStart.origin = CGPointMake(-newStart.size.width, newStart.origin.y);
            oldEnd.origin = CGPointMake(oldEnd.origin.x + oldEnd.size.width, oldEnd.origin.y);
            break;
        case MadvertiseAnimationClassTopToBottom:
            newStart.origin = CGPointMake(newStart.origin.x, -newStart.size.height);
            oldEnd.origin = CGPointMake(oldEnd.origin.x, oldEnd.origin.y + oldEnd.size.height);
            break;
        case MadvertiseAnimationClassCurlDown:
            transition = UIViewAnimationTransitionCurlDown;
            break;
        case MadvertiseAnimationClassFade:
            newStartAlpha = 0;
            newEndAlpha = 1;
            oldEndAlpha = 0;
            break;
        default:
            break;
    }

    nextView.frame = newStart;
    nextView.alpha = newStartAlpha;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:animationDuration];

    if(transition) {
        [UIView setAnimationTransition:transition forView:self cache:YES];
    }

    nextView.alpha = newEndAlpha;
    currentView.alpha = oldEndAlpha;
    nextView.frame = newEnd;
    currentView.frame = oldEnd;
    [self addSubview:nextView];

    [UIView setAnimationDelegate:currentView];
    [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
    [UIView commitAnimations];

    currentView.delegate = nil;
    [currentView release]; currentView = nil;

    currentView = nextView;
    nextView = nil;
}

- (UIViewController *)viewControllerForPresentingModalView {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

#pragma mark -
#pragma mark MRAdViewControllerDelegate

- (void)closeButtonPressed {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdClosed" object:self];
}

- (void)adDidLoad:(MRAdView *)adView {    
    [self setHidden:NO];
    [self swapViews];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoaded" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdDidLoad" object:self];
    if (madDelegate) {
        [madDelegate bannerViewDidLoadAd:self];
    }
    [self createAdReloadTimer];
}

- (void)adDidFailToLoad:(MRAdView *)adView {
    [self setHidden:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoadFailed" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdDidFailToload" object:self];
    
    if (madDelegate) {
        [madDelegate bannerView:self didFailToReceiveAdWithError:nil];
    }
    [self createAdReloadTimer];
}

- (void)appShouldSuspendForAd:(MRAdView *)adView {
    suspended = YES;
    [self stopTimer];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAppShouldSuspend" object:self];
}

- (void)appShouldResumeFromAd:(MRAdView *)adView {
    suspended = NO;
    [self createAdReloadTimer];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAppShouldResume" object:self];
}

// Called just before the ad is displayed on-screen.
- (void)adWillShow:(MRAdView *)adView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdWillShow" object:self];
}

// Called just after the ad has been displayed on-screen.
- (void)adDidShow:(MRAdView *)adView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdDidShow" object:self];
}

// Called just before the ad is hidden.
- (void)adWillHide:(MRAdView *)adView {
    [self stopTimer];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdWillHide" object:self];
}

// Called just after the ad has been hidden.
- (void)adDidHide:(MRAdView *)adView {    
    self.frame = CGRectMake(x, y , 0, 0);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdDidHide" object:self];
}

// Called just before the ad expands.
- (void)willExpandAd:(MRAdView *)adView toFrame:(CGRect)frame {
    [self stopTimer];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdWillExpand" object:self];
}

// Called just after the ad has expanded.
- (void)didExpandAd:(MRAdView *)adView toFrame:(CGRect)frame {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdDidExpand" object:self];
}

// Called just before the ad closes.
- (void)adWillClose:(MRAdView *)adView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdWillClose" object:self];
}

// Called just after the ad has closed.
- (void)adDidClose:(MRAdView *)adView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdDidClose" object:self];
}

// Called if the requests a custom close
- (void)ad:(MRAdView *)adView didRequestCustomCloseEnabled:(BOOL)enabled {
    if (enabled) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdDidRequestCustomClose" object:self];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseMRaidAdDidNotRequestCustomClose" object:self];
    }
}

#pragma mark - private methods section

- (CGSize) getParentViewDimensions {
    if([self superview] != nil){
        UIView *parent = [self superview];
        return CGSizeMake(parent.frame.size.width, parent.frame.size.height);
    }
    return CGSizeMake(0, 0);
}

@end
