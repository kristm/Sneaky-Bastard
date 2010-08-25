//
//  SneakyCamera.h
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

#import <QTKit/QTKit.h>

int frameNum;

@interface SneakyCamera : NSObject {
    QTMovie                             *mMovie;    
    QTCaptureSession                    *mCaptureSession;
    QTCaptureDeviceInput                *mCaptureDeviceInput;
    QTCaptureDecompressedVideoOutput    *mCaptureDecompressedVideoOutput;
    
    CVImageBufferRef                    mCurrentImageBuffer;
	NSString							*imgName;
	NSString							*imgPath;
}

- (NSString *)imgName;
- (NSString *)imgPath;
- (void)setImgName:(NSString *)iName;
- (void)setImgPath:(NSString *)iPath;
- (void)closeDev;
- (BOOL)snapPhoto:(NSString *)iPath imgFileName:(NSString *)iName;

@end

