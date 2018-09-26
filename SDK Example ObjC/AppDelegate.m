//
//  AppDelegate.m
//  SDK Example ObjC
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

#import "AppDelegate.h"
#import <IFTTT_SDK/IFTTT_SDK.h>

@interface AppDelegate () <IFTTTUserTokenProviding>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 
    IFTTTAppletSession.shared.serviceID = @"google_calendar";
    IFTTTAppletSession.shared.userTokenProvider = self;
    
    return YES;
}

- (NSString *)iftttUserToken {
    return nil; // FIXME: Set up ObjC keychain
}

@end


