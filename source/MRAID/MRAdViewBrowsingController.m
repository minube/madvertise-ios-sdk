//
//  MRAdViewBrowsingController.m
//  MoPub
//
//  Created by Andrew He on 12/22/11.
//  Copyright (c) 2011 MoPub, Inc. All rights reserved.
//

#import "MRAdViewBrowsingController.h"
#import "MRAdView.h"
#import "MRAdView+Controllers.h"

@implementation MRAdViewBrowsingController
@synthesize viewControllerForPresentingModalView = _viewControllerForPresentingModalView;

- (id)initWithAdView:(MRAdView *)adView {
    self = [super init];
    if (self) {
        _view = adView;
    }
    return self;
}

- (void)openBrowserWithUrlString:(NSString *)urlString enableBack:(BOOL)back
                   enableForward:(BOOL)forward enableRefresh:(BOOL)refresh {
    NSURL *url = [NSURL URLWithString:urlString];
    MPAdBrowserController *controller = [[[MPAdBrowserController alloc] initWithURL:url
                                                                          delegate:self]autorelease];
    
    [_view adWillPresentModalView];
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000 // iOS 5.0+
    [self.viewControllerForPresentingModalView presentViewController:controller animated:YES completion:^{
        
    }];
    #else
    [self.viewControllerForPresentingModalView presentModalViewController:controller animated:YES];
    #endif
}

#pragma mark -
#pragma mark MPAdBrowserControllerDelegate

- (void)dismissBrowserController:(MPAdBrowserController *)browserController {
    [self dismissBrowserController:browserController animated:YES];
}

- (void)dismissBrowserController:(MPAdBrowserController *)browserController
                        animated:(BOOL)animated {
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000 // iOS 5.0+
    [self.viewControllerForPresentingModalView dismissViewControllerAnimated:animated completion:^{
        
    }];
    #else
    [self.viewControllerForPresentingModalView dismissModalViewControllerAnimated:animated];
    #endif
    //[_view adWillShow];
    [_view adDidDismissModalView];
    //[_view adDidShow];
}

@end
