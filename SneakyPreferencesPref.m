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
	appPath = [[self bundle] pathForResource:@"SneakyBastard" ofType:@"app"];	
	NSLog(@"main load %@",appPath);
	[appPath retain];
}

- (IBAction)toggleEnable:(id)sender
{
	//NSLog(@"toggle sneaky %@",[sender state]);
	NSLog(@"app path %@ %@",appPath, appID);
	NSMutableDictionary * myDict=[[NSMutableDictionary alloc]init];
    NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
    NSMutableArray * loginItems;
	
	loginItems=[[NSMutableArray arrayWithArray:[[defaults
												 persistentDomainForName:@"loginwindow"]
												objectForKey:@"AutoLaunchedApplicationDictionary"]]
				retain];
    [myDict setObject:[NSNumber numberWithBool:NO] forKey:@"Hide"];
    [myDict setObject:appPath forKey:@"Path"];  

	
	//[loginItems removeObject:myDict];
	//[loginItems addObject:myDict];

	[loginItems autorelease];


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
