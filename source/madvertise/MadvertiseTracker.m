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

#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>
#import <netinet/in.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "MadvertiseUtilities.h"
#import "MadvertiseTracker.h"

// static variables
static BOOL madvertiseTrackerDebugMode = YES;
static BOOL trackerAlreadyEnabled = NO;
static NSString *productToken = @"TestTokn";
static NSString *madServer = @"http://ad.madvertise.de";

@implementation MadvertiseTracker

+ (void) enableWithToken:(NSString*)token {
    if (token) {
        productToken = token;
    }
    
    if (trackerAlreadyEnabled) {
        return;
    }
    
    trackerAlreadyEnabled = YES;
  
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                    object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                                                        [MadvertiseTracker reportActionToMadvertise:@"active"];
                                                    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                    object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                                                        [MadvertiseTracker reportActionToMadvertise:@"inactive"];
                                                    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                    object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                                                        [MadvertiseTracker reportActionToMadvertise:@"stop"];
                                                    }];
    
    [MadvertiseTracker synchronizeWithSafari];
    
    [MadvertiseTracker reportActionToMadvertise:@"launch"];
}

+ (void) reportDownload:(NSURL*) url {
    [MadvertiseTracker reportActionToMadvertise:@"download" withTrackingData:[url absoluteString]];
}

+ (void) reportActionToMadvertise:(NSString*) action_type {
    [MadvertiseTracker reportActionToMadvertise:action_type withTrackingData:nil];
}

+ (void) reportActionToMadvertise:(NSString*) action_type withTrackingData:(NSString*) tracking_data {
	NSMutableDictionary *context = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							 UserAgentString(),                                 MADVERTISE_USER_AGENT_KEY,
							 action_type,                                       MADVERTISE_ACTION_TYPE_KEY,
                             [MadvertiseUtilities getIP],                       MADVERTISE_IP_KEY,
                             [MadvertiseUtilities getMacMD5Hash],               MADVERTISE_MACMD5_KEY,
                             [MadvertiseUtilities getMacSHA1Hash],              MADVERTISE_MACSHA1_KEY,
                             [MadvertiseUtilities getIdentifierForAdvertiser],  MADVERTISE_ADVERTISER_IDENTIFIER_KEY,
                             [MadvertiseUtilities getTimestamp],                MADVERTISE_TIMESTAMP_KEY,
                             [MadvertiseUtilities getAppName],                  MADVERTISE_APP_NAME_KEY,
                             [MadvertiseUtilities getAppVersion],               MADVERTISE_APP_VERSION_KEY,
                             @"iPhone-SDK ",                                    MADVERTISE_REQUESTER_KEY,
                             MADVERTISE_SDK_VERION,                             MADVERTISE_SDK_VERION_KEY,
                             (madvertiseTrackerDebugMode ? @"true" : @"false"), MADVERTISE_DEBUG_KEY,
                             tracking_data,                                     MADVERTISE_TRACKING_KEY,
                             nil];
    
    [MadvertiseTracker performSelectorInBackground:@selector(report:) withObject:context];
}

+ (void) setDebugMode: (BOOL) debug {
	madvertiseTrackerDebugMode = debug;
}

+ (void) setProductToken: (NSString *) token {
	productToken = token;
}

+ (void) report: (NSMutableDictionary*) context {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    MadLog(@"%@", documentsDirectory);
    NSString *appOpenPath = [documentsDirectory stringByAppendingPathComponent:@"mad_launch_tracking"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    bool shouldCreateFirstLaunchFile = NO;
    if ([[context objectForKey:MADVERTISE_ACTION_TYPE_KEY] isEqualToString:@"download"]) {
        bool firstLaunch = ![fileManager fileExistsAtPath:appOpenPath];
        [context setValue:(firstLaunch ? @"1" : @"0") forKey:MADVERTISE_FIRST_LAUNCH_KEY];
        [context setValue:@"launch" forKey:MADVERTISE_ACTION_TYPE_KEY];
        shouldCreateFirstLaunchFile = YES;
    }
    
    MadLog(@"Sending tracking request to madvertise. token=%@",productToken);
	
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", madServer, @"/action/", productToken]];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
	NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];  
	[headers setValue:@"application/x-www-form-urlencoded; charset=utf-8" forKey:@"Content-Type"];
	
    NSString *body = @"";	
	unsigned int n = 0;
	for(NSString *key in context) {
		body = [body stringByAppendingString:[NSString stringWithFormat:@"%@=%@", key, [context objectForKey:key]]];
		if(++n != [context count]) {
            body = [body stringByAppendingString:@"&"];
        }
	}
	
    [request setHTTPMethod:@"POST"];  
	[request setAllHTTPHeaderFields:headers]; 
	[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLResponse *response = nil;
	NSError *error  = nil;
	
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
	if( (!error) && ([(NSHTTPURLResponse *)response statusCode] == 200) && shouldCreateFirstLaunchFile) {
		[fileManager createFileAtPath:appOpenPath contents:nil attributes:nil];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setBool:YES forKey:@"sync"];
        [prefs synchronize];
	}

#ifdef DEBUG
	NSString* debugMessage = [[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding];
    MadLog(@"Response from madvertise %@", debugMessage);
    [debugMessage release];
#endif 
  
    [headers release];
    [pool release];
}

+ (void) synchronizeWithSafari {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (![prefs boolForKey:@"sync"] && [MadvertiseUtilities isConnectionAvailable]) {
        NSArray* scheme_array = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
        for (NSDictionary *scheme_dict in scheme_array) {
            NSArray* scheme_dict_array = [scheme_dict objectForKey:@"CFBundleURLSchemes"];
            if (scheme_dict_array) {
                NSString *scheme = [scheme_dict_array lastObject];
                
                if ([scheme rangeOfString:@"mad-"].location == 0) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: [NSString stringWithFormat:@"%@%@?scheme=%@&m5=%@&m1=%@", madServer, @"/sync.html", scheme, [MadvertiseUtilities getMacMD5Hash], [MadvertiseUtilities getMacSHA1Hash]]]];
                    
                    break;
                }
            }
        }
    }
}

@end
