//
//  SneakyPreferencesPref.h
//  SneakyPreferences
//
//  Created by Krist Menina on 4/21/11.
//  Copyright (c) 2011 Hello Wala Studios. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface SneakyPreferencesPref : NSPreferencePane 
{
	CFStringRef appID;
	IBOutlet NSButton *btnEnable;
	IBOutlet NSButton *btnShowinMenu;
	NSString *appPath;
	NSString *bundlePath;
}

- (id)initWithBundle:(NSBundle *)bundle;
- (void) mainViewDidLoad;

- (IBAction)toggleEnable:(id)sender;

@end
