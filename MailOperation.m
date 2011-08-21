//
//  MailOperation.m
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


#import "MailOperation.h"

@implementation MailOperation

NSString *EmailSentSuccess = @"EmailSentSuccess";
NSString *EmailSentFail = @"EmailSentFail";

- (id)initWithRootPath:(NSString *)pp queue:(NSOperationQueue *)qq 
						attachList:(NSArray *)aList 
						header:(NSDictionary *)hList
						auth:(NSDictionary *)aInfo
						ipAddr:(NSArray *)ipAddress
{
	self = [super init];
	appID = CFSTR("org.hellowala.sneakybastard");
	attachments = [aList retain];
	headers = [hList retain];
	authInfo = [aInfo retain];
	ipAddresses = [ipAddress retain];

	return self;
}

- (void)dealloc
{
    [attachments release];
	[headers release];
	[authInfo release];
    [super dealloc];
}

- (void)main
{

	if ([self isCancelled] ){
		NSLog(@"cancelled");	
	} 
	NSString *smtpURL = (NSString *)CFPreferencesCopyAppValue(CFSTR("smtpURL"), appID);
	NSLog(@"main email loop %@",smtpURL);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];


	NSString *text;	
	text = @"Sent from:\r\n";
	text = [text stringByAppendingString:[ipAddresses description]];	
	
	EDMailAgent	*mailAgent; //= [[EDMailAgent alloc] autorelease];
	mailAgent = [EDMailAgent mailAgentForRelayHostWithName:[[NSUserDefaults standardUserDefaults] stringForKey:@"smtpURL"] port:[[NSUserDefaults standardUserDefaults] integerForKey:@"smtpPort"]]; 
	
	[mailAgent setUsesSecureConnections:YES];
	[mailAgent setAuthInfo:authInfo];	
	if ([self isCancelled] ){
		NSLog(@"cancelled");	
	} 
	
	
	@try{
		[mailAgent sendMailWithHeaders:headers body:text andAttachments:attachments];		
	}
	@catch (NSException *edMailAgentException) {
		NSLog(@"NSMailAgentException: Authentication Failed %@",[edMailAgentException name]);
		[[NSNotificationCenter defaultCenter] postNotificationName:EmailSentFail object:nil userInfo:nil];
	}
	if ([self isCancelled] ){
		NSLog(@"cancelled");	
	} 
	

	NSLog(@"mail sent?: %@",mailAgent);	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EmailSentSuccess object:nil userInfo:nil];
	

	[pool release];
	
}

@end
