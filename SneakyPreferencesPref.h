//
//  SneakyPreferencesPref.h
//  SneakyPreferences
//
//  Created by Krist Menina on 4/21/11.
//  Copyright (c) 2011 Hello Wala Studios. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>


@interface SneakyPreferencesPref : NSPreferencePane 
{
	CFStringRef appID;
	IBOutlet NSButton *btnEnable;
	IBOutlet NSButton *btnShowinMenu;
	IBOutlet NSButton *btnSetSnapshotDir;
	IBOutlet SFAuthorizationView *authView;

    IBOutlet NSMatrix *snapshotNumber;
	IBOutlet NSTextField *snapshotDirLabel;
    IBOutlet NSTextField *delaySeconds;
    IBOutlet NSStepper *delaySecondsStepper;
    IBOutlet NSButton *delayOnWakeup;
    IBOutlet NSSlider *alertLevel;
    IBOutlet NSTextField *mailServerUrl;
    IBOutlet NSTextField *mailPort;
    IBOutlet NSTextField *mailUsername;
    IBOutlet NSTextField *mailPassword;
    IBOutlet NSTextField *mailFrom;
    IBOutlet NSTextField *mailTo;
    IBOutlet NSTextField *mailSubject;
    IBOutlet NSButton *mailIPAddress;
	
	NSString *appPath;
	NSString *bundlePath;
}

- (id)initWithBundle:(NSBundle *)bundle;
- (void) mainViewDidLoad;
- (void)appNotification:(NSNotification*)aNotification;
- (void)defaultPrefs;
- (void)updatePrefs;
- (NSString *)getDefaultDir;

- (IBAction)toggleEnable:(id)sender;
- (IBAction)toggleShowInMenu:(id)sender;
- (IBAction)openDirectorySheet:(id)sender;

- (void)didUnselect;

@end
