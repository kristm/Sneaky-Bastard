//
//  SneakyController.m
//  SneakyBastard
//
//  This file is part of SneakyBastard

//	This program is free software; you can redistribute it and/or
//	modify it under the terms of the GNU General Public License
//	as published by the Free Software Foundation; either version 2
//	of the License, or (at your option) any later version.

//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.

//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

//  Created by Krist Menina on 02/06/10.
//  Copyright 2010 Hello Wala Studios. All rights reserved.
//

#import "Controller.h"

@interface Controller (Private)
- (void)refreshTable;
- (BOOL)isConnected;
- (BOOL)isAvailable:(NSString *)url;
- (NSTimer *)timer;
- (void)setTimer:(NSTimer *)value;
- (void)timerIncrement:(NSTimer *)aTimer;
- (void)loadSnapshotsStart:(NSString *)rpath;
- (void)sendMailStart:(id)sender;
- (void)startSneaky:(NSString *)fpath;
- (BOOL) useSmtpSettings;
- (void)alertTimeOut:(NSTimer *)mTimer;
- (NSString*)searchPrefsPath;

@end

#define	TIMEOUT 30
#define CANCELTIMEOUT 200

@implementation Controller

- (id) init
{
	NSLog(@"init");
	
	self = [super init];
	
	appID = CFSTR("org.hellowala.sneakybastard");
	
	NSFileManager *fm = [NSFileManager defaultManager];
	snapCount = 0;
	sbDir = @"temp/";
	path = NSHomeDirectory();
	fullPath =  [NSString stringWithFormat:@"%@/%@",path,sbDir];	
	[fm changeCurrentDirectoryPath:path]; 
	BOOL isDir,b;
	b = [fm fileExistsAtPath:sbDir isDirectory:&isDir];

	if(b){
		tableRecord = [[NSMutableArray alloc] init];
		queue = [[NSOperationQueue alloc] init];
	}else{
		BOOL dirOk;
		NSString *username = NSUserName();
		NSMutableDictionary *attr = [NSMutableDictionary dictionary]; 
		[attr setObject:username forKey:NSFileOwnerAccountName]; 
		[attr setObject:@"staff" forKey:NSFileGroupOwnerAccountName]; 
		[attr setObject:[NSNumber numberWithInt:480] forKey:NSFilePosixPermissions];
		
		dirOk = [fm createDirectoryAtPath:sbDir 
							   attributes:attr];

	}
	
	prefsPath = [[ self searchPrefsPath ] retain ];
	
	// retain or use getter/setter
	[sbDir retain];
	[path retain];
	[fullPath retain];
	
	NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
	[center addObserver:self 
			   selector:@selector(machineDidWake:)
				   name:NSWorkspaceDidWakeNotification 
				 object:NULL];
	[center addObserver:self 
			   selector:@selector(machineWillSleep:)
				   name:NSWorkspaceWillSleepNotification 
				 object:NULL];	
	
	// observe screensaver stop event
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
			selector:@selector(screenSaverDidStop:)
			name:@"com.apple.screensaver.didstop" object:nil];
	


	
	return self;
}

- (void)awakeFromNib
{

	NSLog(@"awake from nib");
	NSNumber *pref_delay = (NSNumber*)CFPreferencesCopyAppValue( CFSTR("snapshotDelay"), appID);
	NSNumber *pref_delayOnlyWakeup = (NSNumber*)CFPreferencesCopyAppValue( CFSTR("isDelayOnlyWakeup"), appID );
	NSNumber *alertLevel = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("alertLevel"), appID);
	
	NSLog(@"delay: %d",[pref_delay intValue] );
	NSLog(@"do i delay %d",[pref_delayOnlyWakeup boolValue] );
	NSLog(@"alert level %d",[alertLevel intValue]);
	NSLog(@"email server %@",(NSString *)CFPreferencesCopyAppValue(CFSTR("smtpURL"), appID));

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anyThread_handleLoadedSnapshots:) name:LoadSnapshotsFinish object:nil];
	
    [[ NSDistributedNotificationCenter defaultCenter ] addObserver: self
														  selector: @selector(prefsNotification:)
															  name: nil
															object: @"SneakyPreferencesPref"
												suspensionBehavior: NSNotificationSuspensionBehaviorCoalesce
	 ];
	
	if([pref_delayOnlyWakeup boolValue]){
		[self startSneaky:fullPath];		
	}else{
		[self performSelector: @selector(startSneaky:)
				   withObject:fullPath
				   afterDelay:[pref_delay intValue]];					
	}
}


- (NSApplication *)application
{
	

	return NSApp;
}

- (void) startSneaky:(NSString *)fpath
{
	NSLog(@"start sneaky");
	
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anyThread_handleNoSnapshots:) name:NoSnapshotsFound object:nil];		
	[self loadSnapshotsStart:fullPath];	
	[self setTimer: [NSTimer scheduledTimerWithTimeInterval: 1.0
													 target: self
												   selector: @selector(checkProgress:)
												   userInfo: nil
													repeats: YES]];	
	[self quickSnap:self];		
	
}

- (void) machineWillSleep:(NSNotification *)notification{
	NSLog(@"going to sleep %@",timer);
	[NSObject cancelPreviousPerformRequestsWithTarget: self
											 selector:@selector(startSneaky:)
											   object:fullPath];
	[queue cancelAllOperations];	
	[timer invalidate];
	[self setTimer:nil];	
}

- (void) machineDidWake:(NSNotification *)notification{
	NSNumber *pref_delay = (NSNumber*)CFPreferencesCopyAppValue( CFSTR("snapshotDelay"), appID);
	NSLog(@"sneaky wake up! %d seconds",[pref_delay intValue]);

	//[self startSneaky:fullPath];
	[self performSelector: @selector(startSneaky:)
				withObject:fullPath
				afterDelay:[pref_delay intValue]];
}

- (void) screenSaverDidStop:(NSNotification *)notification{
	NSNumber *pref_delay = (NSNumber*)CFPreferencesCopyAppValue( CFSTR("snapshotDelay"), appID);
	NSNumber *pref_delayOnlyWakeup = (NSNumber*)CFPreferencesCopyAppValue( CFSTR("isDelayOnlyWakeup"), appID );	
	NSNumber *alertLevel = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("alertLevel"), appID);
	NSLog(@"back from idle time %d",[alertLevel intValue]);
	if([alertLevel intValue] == 1){
		
		[self performSelector: @selector(startSneaky:)
				   withObject:fullPath
				   afterDelay:([pref_delayOnlyWakeup boolValue]) ? 0.5 : [pref_delay intValue]];		
	}
}

- (void)dealloc
{
	NSLog(@"dealloc");
	[[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
	[_statusItem release];
	[timer release];
	[queue release];
	queue = nil;
	[sneakyCam release];
	[super dealloc];
}

- (void)loadSnapshotsStart:(NSString *)rpath
{
	
	NSLog(@"load snap start");
	[tableRecord removeAllObjects];

	
	[queue cancelAllOperations];
	
	// start the GetPathsOperation with the root path to start the search
	GetSnapshots* getSnaps = [[GetSnapshots alloc] initWithRootPath:rpath operationClass:nil queue:queue];
	
	[queue addOperation: getSnaps];	// this will start the "GetPathsOperation"
	[getSnaps release];	

	
}

- (void)anyThread_handleLoadedSnapshots:(NSNotification *)note
{
	// update our table view on the main thread
	NSLog(@"Loaded snapshots");	
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:LoadSnapshotsFinish object:nil];	
	// apparently you don't need to remove observer
	[self performSelectorOnMainThread:@selector(updateSnapTable:) withObject:note waitUntilDone:NO];


}

- (void)anyThread_handleNoSnapshots:(NSNotification *)note
{
	NSLog(@"no snapshots");
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:NoSnapshotsFound object:nil];
	//[self performSelectorOnMainThread:@selector(updateSnapTable:) withObject:nil waitUntilDone:NO];
}

- (void)sendMailStart:(id)sender
{
	NSLog(@"attempting to send mail ");
	NSLog(@"%d",[self isConnected]);
	
	if([tableRecord count] <= 0){
		NSLog(@"Nothing to send");
	}else if(![self useSmtpSettings]){
		NSLog(@"incomplete smtp settings");

	}else if(![self isConnected]){
		NSLog(@"network is not connected");
	}else{
		NSLog(@"credentials complete");
		//NSString *smtpURL = (NSString *)CFPreferencesCopyAppValue(CFSTR("smtpURL"), appID);
		//NSNumber *smtpPort = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("smtpPort"), appID);
		NSString *smtpUsername = (NSString *)CFPreferencesCopyAppValue(CFSTR("smtpUsername"), appID);
		NSString *smtpPassword = (NSString *)CFPreferencesCopyAppValue(CFSTR("smtpPassword"), appID);
		NSString *emailFrom = (NSString *)CFPreferencesCopyAppValue(CFSTR("emailFrom"), appID);
		NSString *emailAddress = (NSString *)CFPreferencesCopyAppValue(CFSTR("emailAddress"), appID);
		NSString *emailSubject = (NSString *)CFPreferencesCopyAppValue(CFSTR("emailSubject"), appID);
		NSNumber *includeNetwork = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("includeNetwork"), appID);
				
		// setup smtp credentials
		NSMutableDictionary *authInfo = [NSMutableDictionary dictionary];
		[authInfo setObject:smtpUsername forKey:EDSMTPUserName];
		[authInfo setObject:smtpPassword forKey:EDSMTPPassword];
		
		// setup email header		
		NSMutableDictionary *headerFields = [NSMutableDictionary dictionary];
		[headerFields setObject:emailFrom forKey:@"From"]; 
		[headerFields setObject:emailAddress forKey:@"To"]; 	
		[headerFields setObject:emailSubject forKey:@"Subject"];
		
		// setup attachments
		id item = NULL;
		NSEnumerator* iterator = [tableRecord objectEnumerator]; 
		NSMutableArray* attachmentList = [NSMutableArray array];
		NSMutableString* imgPath;
		NSMutableArray* ipAddress = [NSMutableArray array];
		
		while (item=[iterator nextObject]) 
		{
			imgPath = [NSString stringWithFormat:@"%@/%@",fullPath,[item valueForKey:@"name"]];
			NSData *imgData = [[NSData alloc] initWithContentsOfFile:imgPath];
			[attachmentList addObject:[EDObjectPair pairWithObjects:imgData:[imgPath lastPathComponent]]];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anyThread_handleEmailSent:) name:EmailSentSuccess object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anyThread_handleEmailSentFail:) name:EmailSentFail object:nil];
		
		[queue cancelAllOperations];
		NSLog(@"sending mail");
		
		if([includeNetwork boolValue] == true){
			NSEnumerator *addresses = [[[NSHost currentHost] addresses] objectEnumerator];
			NSString *address;
			while (address = [addresses nextObject])
				[ipAddress addObject:address];
			

			NSError **outError;
			//url = [NSURL URLWithString:@"http://www.whatismyip.org"];
			NSURL *url = [NSURL URLWithString:@"http://sneakybastard.co.tv/getip.php"];
			
		
			//if([self isAvailable:@"http://sneakybastard.co.tv/getip.php"]){ 
			if(url != nil){
				NSString *wanIP = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:outError];		
				[ipAddress addObject:wanIP];
			}else{
				[ipAddress addObject:@"WAN IP NOT AVAILABLE"];
			}
			NSArray *hostnames = [[NSHost currentHost] names];
			[ipAddress addObject:[hostnames componentsJoinedByString:@","]];
			
			NSLog(@"machine id: %@",ipAddress);
		}else{
			[ipAddress addObject:@"Sneaky Bastard version 0.1.7"];
		}
		
		secs = to = 0;
		[timer invalidate];
		[self setTimer: [NSTimer scheduledTimerWithTimeInterval: 1.0
														 target: self
													   selector: @selector(timerIncrement:)
													   userInfo: nil
														repeats: YES]];			
		MailOperation* mailSnaps = [[MailOperation alloc] initWithRootPath:fullPath queue:queue attachList:attachmentList header:headerFields auth:authInfo ipAddr:ipAddress];
		
		[queue addOperation: mailSnaps];	


	}
}



- (void)anyThread_handleEmailSent:(NSNotification *)note
{
	NSLog(@"Email SentOK ");
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EmailSentSuccess object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EmailSentFail object:nil];
	[self performSelectorOnMainThread:@selector(deleteSnapshots) withObject:nil waitUntilDone:NO];
}

- (void)anyThread_handleEmailSentFail:(NSNotification *)note
{
	NSLog(@"Email Sent Failed");
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EmailSentSuccess object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EmailSentFail object:nil];
	NSLog(@"mail sending FAIL");
	[self performSelectorOnMainThread:@selector(alertSendFail) withObject:nil waitUntilDone:NO];
}

- (BOOL) useSmtpSettings
{
	return ((NSString *)CFPreferencesCopyAppValue(CFSTR("smtpURL"), appID) != nil && 
			(NSNumber *)CFPreferencesCopyAppValue(CFSTR("smtpPort"), appID) != nil &&
			(NSString *)CFPreferencesCopyAppValue(CFSTR("smtpUsername"), appID) != nil &&
			(NSString *)CFPreferencesCopyAppValue(CFSTR("smtpPassword"), appID) != nil &&
			(NSString *)CFPreferencesCopyAppValue(CFSTR("emailFrom"), appID) != nil &&
			(NSString *)CFPreferencesCopyAppValue(CFSTR("emailAddress"), appID) != nil &&
			(NSString *)CFPreferencesCopyAppValue(CFSTR("emailSubject"), appID) != nil &&
			(NSNumber *)CFPreferencesCopyAppValue(CFSTR("includeNetwork"), appID) != nil);
}


- (void)updateSnapTable:(NSNotification *)note
{
	NSLog(@"update table %@",note);
	NSLog(@"operations: %d",[[queue operations] count]);	
	if(note != nil){
		NSLog(@"update table add");
		[tableRecord addObject:[note userInfo]];
		//[self performSelectorOnMainThread:@selector(sendMailStart:) withObject:nil waitUntilDone:NO];
	}
	/*[self setTimer: [NSTimer scheduledTimerWithTimeInterval: 1.0
	 target: self
	 selector: @selector(checkProgress:)
	 userInfo: nil
	 repeats: YES]];	*/
	//[self refreshTable];
}

- (void)refreshTable
{
	NSLog(@"refresh Table");
	int total = [tableRecord count];
	if(total){
		NSLog(@"%d snapshots found",[tableRecord count]);
	}else{
		NSLog(@"No snapshots found");
	}
	
	//[self stopTimer];
	
}


- (NSTimer *)timer
{
    return [[timer retain] autorelease];
}


- (void)setTimer:(NSTimer *)value
{
    if (timer != value)
	{
        [timer release];
        timer = [value retain];
    }
}


-(void)checkProgress:(NSTimer *)t
{
	NSLog(@"check progress %d",[[queue operations] count]);
	if([[queue operations] count] == 0)
	{
		NSLog(@"send mail nowwwwww--------------> %d",[tableRecord count]);
		[t invalidate];
		[self setTimer:nil];
		[self performSelectorOnMainThread:@selector(sendMailStart:) withObject:nil waitUntilDone:NO];
		//[self sendMailStart:nil];
	}
}

- (void)timerIncrement:(NSTimer *)aTimer
{

	NSLog(@"secs: %d %d",secs,[self isConnected]);
	secs++;
	if(![self isConnected]){
		to++;
		if(to >= TIMEOUT){
			[self alertTimeOut:aTimer];
		}
	}else{
		to = 0;
		if(secs >= CANCELTIMEOUT){
			[self alertTimeOut:aTimer];
		}
	}

}

- (void)alertSendFail
{
	[timer invalidate];
	[self setTimer:nil];
	//[self stopTimer];	
}

- (void)alertTimeOut:(NSTimer *)mTimer
{

	
	[mTimer invalidate];
	[self setTimer:nil];
	/*NSAlert *alert = [NSAlert alertWithMessageText: @"Connection Timeout"
									 defaultButton: @"OK"
								   alternateButton: nil
									   otherButton: nil
						 informativeTextWithFormat: @"Network Connection timed out"];
	[alert beginSheetModalForWindow: [self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];	*/

	NSLog(@"operations running: %d",[[queue operations] count]);
	[queue cancelAllOperations];	// find a way to cancel running operation here!!!
	//[queue waitUntilAllOperationsAreFinished]; //indefinitely hangs
	NSLog(@"Connection Timeout");
	
}

- (void)deleteSnapshots
{
	//[self stopTimer];
	[timer invalidate];
	[self setTimer:nil];
	
	id item = NULL;
	NSEnumerator* iterator = [tableRecord objectEnumerator]; 	
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSMutableString* imgPath;
	//int total = [self numberOfRowsInTableView:tableView];

	while (item=[iterator nextObject]) 
	{
		imgPath = [NSString stringWithFormat:@"%@%@",fullPath,[item valueForKey:@"name"]];
		[fileManager removeItemAtPath:imgPath error:NULL];
		
		NSLog(@"delete --> %@",imgPath);
	}
	[tableRecord removeAllObjects];

	
}


- (void) actionQuit:(id)sender {
	[[ NSDistributedNotificationCenter defaultCenter ] postNotificationName: @"SBQuit"
																	 object: @"Controller"
																   userInfo: nil
														 deliverImmediately: YES
	 ];	
	[NSApp terminate:sender];
}


- (void) quickSnap:(id)sender{
	
	NSString *fn;
	NSNumber *overwriteSnapshots = (NSNumber *)CFPreferencesCopyAppValue(CFSTR("overwriteSnapshot"), appID);
	if([overwriteSnapshots boolValue] == 1){
		NSDate *now = [NSDate date];
	
		NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateFormat:@"MMddYY_HHmmss"];
		NSString* formattedDateString;
		formattedDateString = [formatter stringFromDate:now];		
		
		fn = [NSString stringWithFormat:@"bbb_%@.jpg",formattedDateString];
	} else {
		fn = @"bbb.jpg";
		
	}
	sneakyCam = [[SneakyCamera alloc] init] ;
	[sneakyCam setImgPath:[path stringByAppendingFormat:@"/%@",sbDir]];
	[sneakyCam setImgName:fn];
	
}


- (BOOL)isConnected
{
    Boolean success;
    BOOL okay;
    SCNetworkConnectionFlags status;
	
    success = SCNetworkCheckReachabilityByName("www.apple.com", 
											   &status);
	
    okay = success && (status & kSCNetworkFlagsReachable) && !(status & 
															   kSCNetworkFlagsConnectionRequired);
	
    if (!okay)
    {
        /*success = SCNetworkCheckReachabilityByName("www.w3.org", 
												   &status);
		
        okay = success && (status & kSCNetworkFlagsReachable) && 
		!(status & kSCNetworkFlagsConnectionRequired);*/
		NSLog(@"No net");
    }else{
		NSLog(@"Net OK");
	}
	
	
    return okay;
}

// need a c string datatype
- (BOOL)isAvailable:(NSString *)url
{
	Boolean success;
    BOOL okay;
    SCNetworkConnectionFlags status;
	
    success = SCNetworkCheckReachabilityByName([url UTF8String], 
											   &status);
	
    okay = success && (status & kSCNetworkFlagsReachable) && !(status & 
															   kSCNetworkFlagsConnectionRequired);
	
	
    return okay;
}

- (id)statusItem
{
	NSLog(@"status item");
	NSNumber *showMenu = (NSNumber*)CFPreferencesCopyAppValue( CFSTR("showInMenubar"), appID );
	if (_statusItem == nil)
	{
		if([showMenu boolValue]){
			NSLog(@"showing menubar icon");
			NSImage *img;
			
			img = [NSImage imageNamed:@"smile"];
			_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
			[_statusItem setImage:img];
			[_statusItem setHighlightMode:YES];
			[_statusItem setEnabled:YES];
			

			[_statusItem setMenu:menuItemMenu];
			
			[img release];
			//[menu release];		
		}
		
	}
	return _statusItem;
}


- (NSString*)searchPrefsPath
{
    NSString *home = [[ NSString stringWithString: @"~/Library/PreferencePanes/" ] stringByExpandingTildeInPath ];
	
    NSArray *testArray = [ NSArray arrayWithObjects:
						  [ home stringByAppendingPathComponent: @"SneakyBastard.prefPane/" ],
						  @"/Library/PreferencePanes/SneakyBastard.prefPane/",
						  @"/System/Library/PreferencePanes/SneakyBastard.prefPane/",
						  nil ];
    NSEnumerator *e = [ testArray objectEnumerator ];
    NSString *path;
    BOOL isDir;
    while (path = [ e nextObject ])
        if ([[ NSFileManager defaultManager ] fileExistsAtPath: path isDirectory: &isDir ])
            if (isDir)
                return path;
    return nil;
}

//- (IBAction) setOverwriteSnapshot:(id)sender{
//	
//	NSLog(@"overwrite snapshot %d",[[NSUserDefaults standardUserDefaults] boolForKey:@"overwriteSnapshot"]);
//	
//}

- (NSString *)versionString
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSDictionary *infoDict = [mainBundle infoDictionary];
	
    //NSString *mainString = [infoDict valueForKey:@"CFBundleShortVersionString"];
    NSString *subString = [infoDict valueForKey:@"CFBundleVersion"];
    //return [NSString stringWithFormat:@"Version %@ (%@)", mainString, subString];
	return [NSString stringWithFormat:@"Version %@", subString];
}

- (NSString*)copyrightString
{
    return @"Copyright © 2011 \nKrist Menina\nkrist@hellowala.org";
}
- (float)appNameLabelFontSize
{
    return 16.0;
}

- (float)prefLevelsFontSize
{
	return 10.0;
}


- (IBAction) aboutWindowController: (id) sender
{
	[aboutWindow setLevel:NSStatusWindowLevel];
	[aboutWindow makeKeyAndOrderFront:nil];
	[aboutWindow center];
	//[versionText setStringValue:[self printVersion]];	
}

- (IBAction) prefWindowController: (id) sender
{
	NSLog(@"open prefs %@",prefsPath);
	//[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObject: prefsPath ]];
	[[NSWorkspace sharedWorkspace] openFile:prefsPath];

}

// This method handles all notifications sent by the preferencePane
-(void)prefsNotification:(NSNotification*)aNotification
{
	NSLog(@"notification from prefpane %@",[aNotification name]);
	if ([[ aNotification name ] isEqualTo: @"SBShowMenubar" ]) {
		NSLog(@"show in menu bar notify");
		[self statusItem];
	}else if([[ aNotification name] isEqualTo: @"SBHideMenubar" ]){
		NSLog(@"hide menubar notify");
		if(_statusItem != nil){
			[[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
			[_statusItem release];
			_statusItem = nil;
		}
	}else if([[aNotification name] isEqualTo:@"SBQuit" ]){
		NSLog(@"sb quit notification received");
		//[[NSApplication sharedApplication] terminate:self];
		[NSApp terminate:self];
	}
		
}


- (IBAction) prefTestEmail:(id)sender
{
	//NSLog(@"snapshots %@",[tableRecord count]);
	//NSWindow *prefWindow;
	NSAlert *alert = [NSAlert alertWithMessageText: @"Sorry, not yet implemented"
									 defaultButton: @"OK"
								   alternateButton: nil
									   otherButton: nil
						 informativeTextWithFormat: @""];
	[alert beginSheetModalForWindow: prefWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];		
}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSLog(@"alert did end");
}
@end
