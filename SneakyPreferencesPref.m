//
//  SneakyPreferencesPref.m
//  SneakyPreferences
//
//  Created by Krist Menina on 4/21/11.
//  Copyright (c) 2011 Hello Wala Studios. All rights reserved.
//

#import "SneakyPreferencesPref.h"


@implementation SneakyPreferencesPref

- (id)initWithBundle:(NSBundle *)bundle
{
    if (( self = [super initWithBundle:bundle]) != nil)
        appID = CFSTR("org.hellowala.sneakybastard");
    NSLog(@"sneaky init bundle");
    return self;
}

- (void) mainViewDidLoad
{
}

- (IBAction)toggleEnable:(id)sender
{
	//NSLog(@"toggle sneaky %@",[sender state]);
	
    NSMutableArray *loginItems = (NSMutableArray*) CFPreferencesCopyValue((CFStringRef)@"AutoLaunchedApplicationDictionary", (CFStringRef) @"loginwindow",
                                                                          kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    NSDictionary *myLoginItem = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: NO],
                                 @"Hide",
                                 [[self bundle] pathForResource:@"SneakyBastard" ofType: @"app"],@"Path",
                                 nil];
    loginItems = [[loginItems autorelease] mutableCopy];
    [loginItems removeObject: myLoginItem];
    
    if ([sender state] == NO)
    {
        /*CFPreferencesSetValue((CFStringRef) @"AutoLaunchedApplicationDictionary", loginItems,
                              (CFStringRef)@"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFPreferencesSynchronize((CFStringRef) @"loginwindow", kCFPreferencesCurrentUser,
                                 kCFPreferencesAnyHost);
        [loginItems release];
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"SBQuit"
                                                                       object: @"SneakyPreferences"
                                                                     userInfo: nil
                                                           deliverImmediately: YES];*/
    }
    else
    {
        /*[loginItems addObject: myLoginItem];
        CFPreferencesSetValue((CFStringRef) @"AutoLaunchedApplicationDictionary", loginItems,
                              (CFStringRef)@"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFPreferencesSynchronize((CFStringRef) @"loginwindow", kCFPreferencesCurrentUser,
                                 kCFPreferencesAnyHost);
        [loginItems release];

        NSString *myPath = [[[[[self bundle] pathForResource:@"SneakyBastard" ofType: @"app"]
                              stringByAppendingPathComponent: @"Contents"]
                             stringByAppendingPathComponent: @"MacOS"]
                            stringByAppendingPathComponent: @"SneakyBastard"];
        [NSTask launchedTaskWithLaunchPath: myPath arguments: [NSArray array]];*/
		//NSLog(@"mypath %@",myPath);
		NSLog(@"assign login items");
    }
    
}

@end
