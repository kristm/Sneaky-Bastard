//---------------------------------------------------------------------------------------
//  EDFaceFieldCoder.h created by erik
//  @(#)$Id: EDFaceFieldCoder.h,v 2.1 2003/04/08 17:06:05 znek Exp $
//
//  Copyright (c) 1999-2000 by Erik Doernenburg. All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted, provided that both the copyright notice and this permission
//  notice appear in all copies of the software, derivative works or modified versions,
//  and any portions thereof, and that both notices appear in supporting documentation,
//  and that credit is given to Erik Doernenburg in all documents and publicity
//  pertaining to direct or indirect use of this code or its derivatives.
//
//  THIS IS EXPERIMENTAL SOFTWARE AND IT IS KNOWN TO HAVE BUGS, SOME OF WHICH MAY HAVE
//  SERIOUS CONSEQUENCES. THE COPYRIGHT HOLDER ALLOWS FREE USE OF THIS SOFTWARE IN ITS
//  "AS IS" CONDITION. THE COPYRIGHT HOLDER DISCLAIMS ANY LIABILITY OF ANY KIND FOR ANY
//  DAMAGES WHATSOEVER RESULTING DIRECTLY OR INDIRECTLY FROM THE USE OF THIS SOFTWARE
//  OR OF ANY DERIVATIVE WORK.
//---------------------------------------------------------------------------------------

#import "EDHeaderFieldCoder.h"
#import <AppKit/NSImage.h>

@interface EDFaceFieldCoder : EDHeaderFieldCoder
{
    NSImage	*image;
}

+ (id)encoderWithImage:(NSImage *)anImage;
- (id)initWithImage:(NSImage *)anImage;
- (NSImage *)image;

@end
