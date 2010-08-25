//
//  SneakyCamera.m
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

#import "SneakyCamera.h"


@implementation SneakyCamera


- (void)dealloc
{
    [mMovie release];
    
    [mCaptureSession release];
    [mCaptureDeviceInput release];
    [mCaptureDecompressedVideoOutput release];
    
    [super dealloc];
}

- (id)init
{
	self = [super init];
	frameNum = 0;
	//[self setDelegate:self]; no delegate for nsobject
	NSError *error = nil;

    if (!mMovie) {
        // Create an empty movie that writes to mutable data in memory
        mMovie = [[QTMovie alloc] initToWritableData:[NSMutableData data] error:&error];
        if (!mMovie) {
            [[NSAlert alertWithError:error] runModal];
            //return self;
        }
    }
	
	
	if (!mCaptureSession) {
        // Set up a capture session that outputs raw frames
        BOOL success;
        
        mCaptureSession = [[QTCaptureSession alloc] init];
        
        // Find a video device
        QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
        success = [device open:&error];
        if (!success) {
			//NSLog(@"eeror capture device");			
            [[NSAlert alertWithError:error] runModal];
            //return 0;
        }
        
        // Add a device input for that device to the capture session
        mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
        success = [mCaptureSession addInput:mCaptureDeviceInput error:&error];
        if (!success) {
			//NSLog(@"eeror device input");			
            [[NSAlert alertWithError:error] runModal];
            //return 0;
        }
        
        // Add a decompressed video output that returns raw frames to the session
        mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
        [mCaptureDecompressedVideoOutput setDelegate:self];
        success = [mCaptureSession addOutput:mCaptureDecompressedVideoOutput error:&error];
        if (!success) {
			//NSLog(@"eeror device output");
            [[NSAlert alertWithError:error] runModal];
            //return 0;
        }
        
        // Preview the video from the session in the document window
        //[mCaptureView setCaptureSession:mCaptureSession];
        
        // Start the session
        [mCaptureSession startRunning];


		
		
    }
	return self;
}

- (void)closeDev
{
	NSLog(@"closing capture device");
    [mCaptureSession stopRunning];
    NSLog(@"capture device closed");
    QTCaptureDevice *device = [mCaptureDeviceInput device];
    if ([device isOpen])
        [device close];    
}

- (NSString *)imgName
{
	return imgName;
}

- (void)setImgName:(NSString *)iName
{

	if(imgName != iName){
		[imgName release];
		imgName = [iName copy];
	}
}

- (NSString *)imgPath
{
	return imgPath;
}

- (void)setImgPath:(NSString *)iPath
{
	if(imgPath != iPath){
		[imgPath release];
		imgPath = [iPath copy];
	}	
}

// delegate method gets called whenever QTCaptureDecompressedVideoOutput receives video frame
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
    // Store the latest frame
	// This must be done in a @synchronized block because this delegate method is not called on the main thread
    CVImageBufferRef imageBufferToRelease;
    
    CVBufferRetain(videoFrame);
    
    @synchronized (self) {

        imageBufferToRelease = mCurrentImageBuffer;
        mCurrentImageBuffer = videoFrame;

		frameNum++;
    }
	


	//NSLog(@"check img name before snap:%@",imgName);
	//NSLog(@"check path: %@",imgPath);	
	if(frameNum == 2){
		[self snapPhoto:imgPath imgFileName:imgName];    
	}
		
    CVBufferRelease(imageBufferToRelease); // i think snapphoto should be called before releasing buffer????

	//[self closeDev];
}



- (BOOL)snapPhoto:(NSString *)iPath imgFileName:(NSString *)iName
{
	

	// This must be done in a @synchronized block because the delegate method that sets the most recent frame is not called on the main thread
    CVImageBufferRef imageBuffer;
    
    @synchronized (self) {
		NSLog(@"syncronized: grabbing image buffer");
        imageBuffer = CVBufferRetain(mCurrentImageBuffer);
    }


	
		
    if (imageBuffer) {

		// 
        // Create an NSImage and add it to the movie
        NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer]];
        //NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(400, 307)] autorelease];
		NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(400, 307)];
        [image addRepresentation:imageRep];
        CVBufferRelease(imageBuffer);
        

		//write jpg file
		

		
		NSData *tiffData = [image TIFFRepresentation];
		
		NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:tiffData];
		NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9]
															   forKey:NSImageCompressionFactor];
		NSData *bitmapData = [bitmapRep representationUsingType:NSJPEGFileType properties:imageProps];
		NSString *outputPath = [NSString stringWithFormat:@"%@%@", iPath,iName];        
		BOOL ok = [bitmapData writeToFile:outputPath atomically:NO];
		if(ok){
			NSLog(@"snapped photo ok");
		}else{
			NSLog(@"write error");
		}
		
		[image release];
		[self closeDev];
		return YES;
    }else{
		NSLog(@"img buff is nuuuuuuuuuullllllllllllllllllll");
		//[self snapPhoto:imgName];
		return NO;
		
	}
	
	
	
	
}

@end
