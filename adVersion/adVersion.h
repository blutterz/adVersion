//
//  adVersion.h
//  adVersion
//
//  Created by blutter on 16/4/13.
//  Copyright © 2016年 blutter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface adVersion : NSObject

@property(nonatomic, copy) NSString* remoteVersionsPlistURL;

+ (instancetype)sharedInstance;
- (void)checkVersion;
- (void)checkVersion:(BOOL)needTip;
@end
