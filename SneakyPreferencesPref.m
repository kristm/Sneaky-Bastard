//
//  SneakyPreferencesPref.m
//  SneakyPreferences
//
//  Created by Krist Menina on 4/21/11.
//  Copyright (c) 2011 Hello Wala Studios. All rights reserved.
//

#import "SneakyPreferencesPref.h"
#import "FBEncryptorAES.h"


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
	
	NSFileManager *fm = [NSFileManager defaultManager];
	//int path_length = [[self getDefaultDir] length];
	BOOL isDir,tempExist;
	//tempExist = [fm fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",NSHomeDirectory(),@"temp"] isDirectory:&isDir];
	tempExist = [fm fileExistsAtPath:[self getDefaultDir] isDirectory:&isDir];
	NSLog(@"temp exist %d %d %@",tempExist,isDir,[self getDefaultDir]);
	if(!tempExist || (tempExist && !isDir)){
		NSLog(@"temp directory does not exists");
		NSString *username = NSUserName();
		NSMutableDictionary *attr = [NSMutableDictionary dictionary]; 
		[attr setObject:username forKey:NSFileOwnerAccountName]; 
		[attr setObject:@"staff" forKey:NSFileGroupOwnerAccountName]; 
		[attr setObject:[NSNumber numberWithInt:480] forKey:NSFilePosixPermissions];
		
		[fm createDirectoryAtPath:[self getDefaultDir] 
								withIntermediateDirectories:NO 
								attributes:attr error:NULL];
		
	}
	
    [[ NSDistributedNotificationCenter defaultCenter ] addObserver: self
														  selector: @selector(appNotification:)
															  name: nil
															object: @"Controller"
												suspensionBehavior: NSNotificationSuspensionBehaviorCoalesce
	 ];
		
	[self defaultPrefs];
	
	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &items};
    [authView setAuthorizationRights:&rights];
    authView.delegate = self;
    [authView updateStatus:nil];
	
	[fm release];
}

- (IBAction)toggleEnable:(id)sender
{
	[self updatePrefs];
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
	[self updatePrefs];
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

- (NSString *)getDefaultDir{
	NSString *sbDir = @"temp/";
	NSString *path = NSHomeDirectory();
	return [NSString stringWithFormat:@"%@/%@",path,sbDir];
}

- (IBAction)openDirectorySheet:(id)sender{
	NSString *defaultPath = [self getDefaultDir];
	NSString *snapshotDir = (NSString *)CFPreferencesCopyAppValue(CFSTR("snapshotDir"), appID);
	NSString *sheetDir;
	if([snapshotDir isEqualToString:defaultPath]){
		sheetDir = defaultPath;
	}else{
		sheetDir = snapshotDir;
	}
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setDelegate:self];
	NSLog(@"size %d",[openPanel contentMaxSize]);
    [openPanel beginSheetForDirectory: sheetDir
								  file: nil
								 types: nil
						modalForWindow: [[ self mainView ] window ]
						 modalDelegate: self
						didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
						   contextInfo: nil	];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [ NSApp endSheet: sheet ];
	NSLog(@"sheet selection %@",[sheet directory]);
    if (returnCode == NSOKButton) {
		CFPreferencesAppSynchronize(appID);
		CFPreferencesSetAppValue(CFSTR("snapshotDir"), [NSString stringWithFormat:@"%@%@",[sheet directory],@"/"], appID);		

    }
}
			
-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSLog(@"alert did end");
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

// NSOpenPanel delates
- (void)panel:(id)sender didChangeToDirectoryURL:(NSURL *)url {
	//NSString *selectedPath = [[url absoluteString] substringFromIndex:16];
	NSString *selectedPath = [url path];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSLog(@"path url %@",[url path]);
	NSLog(@"selected path %@",selectedPath);
	NSLog(@"is writable %d",[fm isWritableFileAtPath:selectedPath]);	
	if([fm isWritableFileAtPath:selectedPath] == NO){
		NSAlert *alert = [NSAlert alertWithMessageText: @"Write Permission Not Allowed"
										 defaultButton: @"OK"
									   alternateButton: nil
										   otherButton: nil
							 informativeTextWithFormat: @"You don't have permission to use this directory. Please choose a folder that you own."];
		//[alert runModal];
		[alert beginSheetModalForWindow:sender modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];		
		[sender setDirectory:NSHomeDirectory()];

	}
}


//
// SFAuthorization delegates
//

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
	
	BOOL unlock = [self isUnlocked];
    
	[btnEnable setEnabled:unlock];
	[btnShowinMenu setEnabled:unlock];
	[btnSetSnapshotDir setEnabled:unlock];
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
	[btnSetSnapshotDir setEnabled:unlock];
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

- (void)defaultPrefs
{	
	NSNumber *numSnapshots = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("overwriteSnapshot"), appID);
	NSNumber *snapshotDelay = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("snapshotDelay"), appID);
	NSNumber *isDelayOnWakeup = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("isDelayOnlyWakeup"), appID);
	NSNumber *alertMeter = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("alertLevel"), appID);
	NSNumber *showInMenubar = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("showInMenubar"), appID);
	NSNumber *enableSneaky = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("enableSneaky"), appID);
	NSString *snapshotDir = (NSString *)CFPreferencesCopyAppValue(CFSTR("snapshotDir"), appID);
	NSLog(@"snapshot dir %@",snapshotDir);
	
	if(snapshotDir == nil){
		NSLog(@"set to temp");
		CFPreferencesSetAppValue(CFSTR("snapshotDir"), [self getDefaultDir], appID);
		[snapshotDirLabel setStringValue:@"Default"];
	}else{
		NSLog(@"set to custom");
		[snapshotDirLabel setStringValue:@"Custom"];
	}
	if(numSnapshots){
		[snapshotNumber setState:YES atRow:[numSnapshots intValue] column:0];
		[snapshotNumber setState:NO atRow:![numSnapshots intValue] column:0];
	}
	if(snapshotDelay) [delaySeconds setIntValue:[snapshotDelay intValue]];
	if(isDelayOnWakeup) [delayOnWakeup setState:[isDelayOnWakeup boolValue]];
	if(alertMeter) [alertLevel setIntValue:[alertMeter intValue]];
	if(showInMenubar) [btnShowinMenu setState:[showInMenubar boolValue]];
	if(enableSneaky) [btnEnable setState:[enableSneaky boolValue]];
	
	NSString *smtpURL = (NSString *)CFPreferencesCopyAppValue(CFSTR("smtpURL"), appID);
	NSNumber *smtpPort = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("smtpPort"), appID);
	NSString *smtpUsername = (NSString *)CFPreferencesCopyAppValue(CFSTR("smtpUsername"), appID);
	NSString *smtpPassword = (NSString *)CFPreferencesCopyAppValue(CFSTR("smtpPassword"), appID);
	NSString *emailFrom = (NSString *)CFPreferencesCopyAppValue(CFSTR("emailFrom"), appID);
	NSString *emailAddress = (NSString *)CFPreferencesCopyAppValue(CFSTR("emailAddress"), appID);
	NSString *emailSubject = (NSString *)CFPreferencesCopyAppValue(CFSTR("emailSubject"), appID);
	NSNumber *includeNetwork = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("includeNetwork"), appID);

	if(smtpURL) [mailServerUrl setStringValue:smtpURL];
	if(smtpPort) [mailPort setIntValue:[smtpPort intValue]];
	if(smtpUsername) [mailUsername setStringValue:smtpUsername];
	if(smtpPassword) [mailPassword setStringValue:[FBEncryptorAES decryptBase64String:smtpPassword keyString:@"Cellophane flowers"]];
	if(emailFrom) [mailFrom setStringValue:emailFrom];
	if(emailAddress) [mailTo setStringValue:emailAddress];	
	if(emailSubject) [mailSubject setStringValue:emailSubject];
	if(includeNetwork) [mailIPAddress setState:[includeNetwork boolValue]];
																	 
	NSLog(@"num snaps %d",[numSnapshots intValue]);
	NSLog(@"snapshot delay %d",[snapshotDelay intValue]);
	NSLog(@"delay On wake %d",[isDelayOnWakeup boolValue]);
	NSLog(@"alert %@",alertMeter);
	NSLog(@"email subject %@",emailSubject);

}

- (void)updatePrefs
{
	NSLog(@"update prefs %d %d %d %d",[snapshotNumber selectedRow],[delaySeconds intValue],[delayOnWakeup state],[alertLevel integerValue]);
	CFPreferencesAppSynchronize( appID );
	CFPreferencesSetAppValue(CFSTR("overwriteSnapshot"), [NSNumber numberWithInt:[snapshotNumber selectedRow]], appID );
	CFPreferencesSetAppValue(CFSTR("snapshotDelay"), [NSNumber numberWithInt:[delaySeconds intValue]], appID );
	CFPreferencesSetAppValue(CFSTR("isDelayOnlyWakeup"), [NSNumber numberWithBool:[delayOnWakeup  state]], appID );
	CFPreferencesSetAppValue(CFSTR("alertLevel"), [NSNumber numberWithInt:[alertLevel integerValue]], appID);
	CFPreferencesSetAppValue(CFSTR("smtpUsername"), [mailUsername stringValue], appID);
	CFPreferencesSetAppValue(CFSTR("smtpPassword"), [FBEncryptorAES encryptBase64String:[mailPassword stringValue] keyString:@"Cellophane flowers" separateLines:NO], 
                                                    appID);	
	CFPreferencesSetAppValue(CFSTR("smtpURL"), [mailServerUrl stringValue], appID);
	CFPreferencesSetAppValue(CFSTR("smtpPort"), [mailPort stringValue], appID);
	CFPreferencesSetAppValue(CFSTR("emailFrom"), [mailFrom stringValue], appID);
	CFPreferencesSetAppValue(CFSTR("emailAddress"), [mailTo stringValue], appID);
	CFPreferencesSetAppValue(CFSTR("emailSubject"), [mailSubject stringValue], appID);
	CFPreferencesSetAppValue(CFSTR("includeNetwork"), [NSNumber numberWithInt:[mailIPAddress state]], appID);
	CFPreferencesAppSynchronize( appID );
}

- (void)didUnselect
{
	NSLog(@"quit prefpane");
	[self updatePrefs];

}

@end
