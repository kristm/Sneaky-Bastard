//
//  SneakyController.h
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

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SCNetwork.h>
#import <EDMessage/EDMessage.h> 
#import "GetSnapshots.h"
#import "MailOperation.h"
#import "SneakyCamera.h"


@interface Controller : NSObject {
@private
	CFStringRef appID;
	NSStatusItem		*_statusItem;
	//NSTimer				*ctimer;

	SneakyCamera		*sneakyCam;
//	NSString			*path;
//	NSString			*sbDir;
//	NSString			*fullPath;
	NSString			*prefsPath;
	NSNumber			*snapCount;
	NSOperationQueue	*queue;	
	NSMutableArray		*tableRecord;
	IBOutlet NSMenu		*menuItemMenu;
	IBOutlet NSWindow	*aboutWindow;
	IBOutlet NSWindow	*prefWindow;
	IBOutlet NSTextField *txtDelay;
	IBOutlet NSStepper  *stepDelay;
	IBOutlet NSButton	*checkOnlyonwakeup;
	int					secs;
	int					to;
@public
	NSTimer*			timer;	

}

- (NSString *)versionString;
- (NSString*)copyrightString;
- (float)appNameLabelFontSize;
- (id)statusItem;
- (NSApplication *)application;

- (void)actionQuit:(id)sender;
- (void)quickSnap:(id)sender;

- (void)prefsNotification:(NSNotification*)aNotification;

//- (IBAction) setOverwriteSnapshot:(id)sender;
- (IBAction) aboutWindowController: (id) sender;
- (IBAction) prefWindowController: (id) sender;
- (IBAction) prefTestEmail:(id)sender;
@end
