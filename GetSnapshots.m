//
//  GetSnapshots.m
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

#import "GetSnapshots.h"


@implementation GetSnapshots

NSString *LoadSnapshotsFinish = @"LoadSnapshotsFinish";
NSString *NoSnapshotsFound = @"NoSnapshotsFound";

- (id)initWithRootPath:(NSString *)pp operationClass:(Class)cc queue:(NSOperationQueue *)qq
{
    self = [super init];	
    // the operation class must have an -initWithPath: method.
    /*if (![cc instancesRespondToSelector:@selector(initWithPath:)])
	{
		[self release];
		return nil;
    }*/
	
    rootPath = [pp retain];
    //opClass = cc;
    //queue = [qq retain];
	
    return self;
}

- (void)dealloc
{
	NSLog(@"********** dealloc getsnaps");
    [rootPath release];
    //[queue release];
	//queue = nil;
    [super dealloc];
}

- (void)main
{

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString* sourceDirectoryFilePath = nil;
	NSDirectoryEnumerator* sourceDirectoryFilePathEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:rootPath];
	
	while (sourceDirectoryFilePath = [sourceDirectoryFilePathEnumerator nextObject])
	{
		/*if ([self isCancelled])
		 {
		 break;	// user cancelled this operation
		 }*/
		//NSLog(@"get path=============");
		[sourceDirectoryFilePathEnumerator skipDescendents];		
		NSDictionary *sourceDirectoryFileAttributes = [sourceDirectoryFilePathEnumerator fileAttributes];
		
		NSString *sourceDirectoryFileType = [sourceDirectoryFileAttributes objectForKey:NSFileType];
		
		if ([sourceDirectoryFileType isEqualToString:NSFileTypeRegular] == YES)
		{
			NSString *fullSourceDirectoryFilePath = [rootPath stringByAppendingPathComponent:sourceDirectoryFilePath];

			
			NSString* loadPath = fullSourceDirectoryFilePath;
			
			NSPredicate *bPredicate = [NSPredicate predicateWithFormat:@"SELF beginswith 'bbb'"];
			if([bPredicate evaluateWithObject:[loadPath lastPathComponent]]){
				
				FSRef ref;
				Boolean isDirectory;
				FSPathMakeRef((const UInt8 *)[loadPath fileSystemRepresentation], &ref, &isDirectory); // no error checking
				//NSLog(@"ref %@",[loadPath lastPathComponent]);
				FSCatalogInfo catInfo;
				FSGetCatalogInfo(&ref,  (kFSCatInfoContentMod | kFSCatInfoDataSizes), &catInfo, nil, nil, nil); // no error checking
				
				CFAbsoluteTime cfTime;
				UCConvertUTCDateTimeToCFAbsoluteTime(&catInfo.contentModDate, &cfTime); // no error checking
				CFDateRef dateRef = nil;
				dateRef = CFDateCreate(kCFAllocatorDefault, cfTime);	
				
				NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
				[formatter setTimeStyle:NSDateFormatterNoStyle];
				[formatter setDateStyle:NSDateFormatterShortStyle];
				NSString *modDateStr = [formatter stringFromDate:(NSDate*)dateRef];
				
				NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
									  [loadPath lastPathComponent], @"name",
									  modDateStr, @"created",nil];		
				NSLog(@"snapshot found");
				[[NSNotificationCenter defaultCenter] postNotificationName:LoadSnapshotsFinish object:nil userInfo:info];
			}
			
		}else{

			//[[NSNotificationCenter defaultCenter] postNotificationName:NoSnapshotsFound object:nil userInfo:nil];
		}
	}
	NSLog(@"thread finished");

	
    [pool release];	
	
}

@end
