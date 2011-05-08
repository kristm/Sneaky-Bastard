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
	
    [[ NSDistributedNotificationCenter defaultCenter ] addObserver: self
														  selector: @selector(appNotification:)
															  name: nil
															object: @"Controller"
												suspensionBehavior: NSNotificationSuspensionBehaviorCoalesce
	 ];
	
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"includeNetwork",[NSNumber numberWithInt:120],@"snapshotDelay",[NSNumber numberWithBool:YES],@"isDelayOnlyWakeup",[NSNumber numberWithInt:0],@"alertLevel",[NSNumber numberWithBool:NO], @"showInMenubar",[NSNumber numberWithBool:NO],@"enableSneaky", nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];	
	
	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &items};
    [authView setAuthorizationRights:&rights];
    authView.delegate = self;
    [authView updateStatus:nil];
}

- (IBAction)toggleEnable:(id)sender
{
	//NSLog(@"toggle sneaky %@",[sender state]);
	NSLog(@"app path %@",appPath);
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
															kLSSharedFileListSessionLoginItems, NULL);
	
	CFPreferencesSetAppValue( CFSTR("enableSneaky"), [NSNumber numberWithBool:[sender state]], appID );
	
    if ([sender state] == NO)
    {
		if (loginItems) {
			UInt32 seedValue;
			//Retrieve the list of Login Items and cast them to
			// a NSArray so that it will be easier to iterate.
			NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
			int i = 0;
			for(i ; i< [loginItemsArray count]; i++){
				LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray
																			objectAtIndex:i];
				//Resolve the item with URL
				if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
					NSString * urlPath = [(NSURL*)url path];
					if ([urlPath compare:appPath] == NSOrderedSame){
						LSSharedFileListItemRemove(loginItems,itemRef);
					}
				}
			}
			[loginItemsArray release];
					
		}	
		[[ NSDistributedNotificationCenter defaultCenter ] postNotificationName: @"SBQuit"
																		 object: @"SneakyPreferencesPref"
																	   userInfo: nil
															 deliverImmediately: YES
		 ];
    }
    else
    {
		if (loginItems) {
			//Insert an item to the list.
			LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
																		 kLSSharedFileListItemLast, NULL, NULL,
																		 url, NULL, NULL);
			if (item){
				CFRelease(item);
			}

			//[NSTask launchedTaskWithLaunchPath:appPath arguments:[NSArray array]];
			[[NSWorkspace sharedWorkspace] openFile:appPath];

			NSLog(@"enable sb %@",appPath);
		}	
		
		NSLog(@"assign login items");
    }
    CFRelease(loginItems);	
}

- (IBAction)toggleShowInMenu:(id)sender{
	NSLog(@"toggle show menu %d",[sender state]);
	CFPreferencesSetAppValue( CFSTR("showInMenubar"), [NSNumber numberWithBool:[sender state]], appID );
	if([sender state] == 1){
		[[ NSDistributedNotificationCenter defaultCenter ] postNotificationName: @"SBShowMenubar"
																		 object: @"SneakyPreferencesPref"
																	   userInfo: nil
															 deliverImmediately: YES
		 ];	
	}else if([sender state] == 0){
		[[ NSDistributedNotificationCenter defaultCenter ] postNotificationName: @"SBHideMenubar"
																		 object: @"SneakyPreferencesPref"
																	   userInfo: nil
															 deliverImmediately: YES
		 ];			
	}
}


- (void)appNotification:(NSNotification*)aNotification
{
	NSLog(@"notification from main app %@",[aNotification name]);
	if([[ aNotification name] isEqualTo:@"SBQuit"]){
		[btnEnable setState:NO];
	}
}

- (BOOL)isUnlocked {
    return [authView authorizationState] == SFAuthorizationViewUnlockedState;
}

//
// SFAuthorization delegates
//

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
	
	BOOL unlock = [self isUnlocked];
    
	[btnEnable setEnabled:unlock];
	[btnShowinMenu setEnabled:unlock];
	[snapshotNumber setEnabled:unlock];
	[delaySeconds setEnabled:unlock];
	[delaySecondsStepper setEnabled:unlock];
	[delayOnWakeup setEnabled:unlock];
	[alertLevel setEnabled:unlock];
	[mailServerUrl setEnabled:unlock];
	[mailPort setEnabled:unlock];
	[mailUsername setEnabled:unlock];
	[mailPassword setEnabled:unlock];
	[mailFrom setEnabled:unlock];
	[mailTo	setEnabled:unlock];
	[mailSubject setEnabled:unlock];
	[mailIPAddress setEnabled:unlock];
	
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
    //[touchButton setEnabled:[self isUnlocked]];
	BOOL unlock = [self isUnlocked];
    
	[btnEnable setEnabled:unlock];
	[btnShowinMenu setEnabled:unlock];
	[snapshotNumber setEnabled:unlock];
	[delaySeconds setEnabled:unlock];
	[delaySecondsStepper setEnabled:unlock];
	[delayOnWakeup setEnabled:unlock];
	[alertLevel setEnabled:unlock];
	[mailServerUrl setEnabled:unlock];
	[mailPort setEnabled:unlock];
	[mailUsername setEnabled:unlock];
	[mailPassword setEnabled:unlock];
	[mailFrom setEnabled:unlock];
	[mailTo	setEnabled:unlock];
	[mailSubject setEnabled:unlock];
	[mailIPAddress setEnabled:unlock];
	
}

- (void)updatePrefs
{
	NSLog(@"update prefs %d %d %d",[snapshotNumber selectedRow],[delaySeconds intValue],[delayOnWakeup state]);
	CFPreferencesSetAppValue( CFSTR("overwriteSnapshot"), [NSNumber numberWithBool:[snapshotNumber selectedRow]], appID );
	CFPreferencesSetAppValue( CFSTR("snapshotDelay"), [NSNumber numberWithInt:[delaySeconds intValue]], appID );
	CFPreferencesSetAppValue( CFSTR("isDelayOnlyWakeup"), [NSNumber numberWithBool:[delayOnWakeup  state]], appID );
}

- (void)didUnselect
{
	NSLog(@"quit prefpane");
	[self updatePrefs];
}

@end
