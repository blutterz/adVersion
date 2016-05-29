//
//  adVersion.m
//  adVersion
//
//  Created by blutter on 16/4/13.
//  Copyright © 2016年 blutter. All rights reserved.
//

#import "adVersion.h"
#if __has_include(<Alert/Alert.h>)
#import <Alert/Alert.h>
#endif
#define IS_VAILABLE_IOS8  ([[[UIDevice currentDevice] systemVersion] intValue] >= 8)

NSString * const VSERSION_MANAGER    = @"VersionManagerStroe";
NSString * const VSERSION_CHECKED    = @"VersionChecked";
NSString * const kAppHouseRootURL    = @"https://app.cnfreechat.com/%@/%@.plist";
NSString * const kAppItemServicesURL = @"itms-services://?action=download-manifest&url=%@";

@implementation NSString(adVersion)

- (NSComparisonResult)compareVersion:(NSString *)version
{
    return [self compare:version options:NSNumericSearch];
}

- (NSComparisonResult)compareVersionDescending:(NSString *)version
{
    return (NSComparisonResult)(0 - [self compareVersion:version]);
}

@end

@interface adVersion()

@property (nonatomic, copy) NSString* applicationBundleID;
@property (nonatomic, copy) NSString* applicationBundleScheme;
@property (nonatomic, copy) NSString* applicationVersion;
@property (nonatomic, copy) NSString* updateURL;

@end

@implementation adVersion

+ (instancetype)sharedInstance{
    static adVersion* adVersionInstanc_ = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        adVersionInstanc_ = [[self alloc] init];
    });
    return adVersionInstanc_;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        self.applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];
        self.applicationBundleScheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleScheme"];
        if (self.applicationBundleScheme.length == 0) {
            self.applicationBundleScheme = @"freechat";
        }
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        self.updateURL = [NSString stringWithFormat:kAppItemServicesURL, [NSString stringWithFormat:kAppHouseRootURL, self.applicationBundleScheme, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]]];
    }
    return self;
}

- (void)checkVersion {
    [self checkVersion:NO];
}

- (void)checkVersion:(BOOL)needTip {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary* dicts = [NSMutableDictionary dictionaryWithDictionary:[defs objectForKey:VSERSION_MANAGER]];
        if (dicts == nil) {
            dicts = [NSMutableDictionary dictionaryWithCapacity:0];
        }
        NSString* firstLanuchKey = [NSString stringWithFormat:@"VersionManage_%@" , self.applicationVersion];
        NSNumber* bFirstLanch = [dicts objectForKey:firstLanuchKey];
        if (![bFirstLanch boolValue]) {
            [dicts setValue:[NSNumber numberWithBool:YES] forKey:firstLanuchKey];
            [defs setObject:dicts forKey:VSERSION_MANAGER];
            [defs synchronize];
        }

        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kAppHouseRootURL, self.applicationBundleScheme, @"versions"]];
        NSURLRequest *urlrequest = [NSURLRequest requestWithURL:url];
        NSURLSessionDataTask* dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:urlrequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                return ;
            }
            else {
                NSPropertyListFormat format;
                NSError *error2 = nil;
                NSDictionary* pListVersion = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:&error2];

                if (error) {
                    return;
                }
                NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                if (data && statusCode == 200) {
                    NSString *details = [self versionDetailsSince:self.applicationVersion inDict:pListVersion];
                    NSString *mostRecentVersion = [self mostRecentVersionInDict:pListVersion];
                    if (details) {
                        [dicts setObject:mostRecentVersion forKey:VSERSION_CHECKED];
                        [defs setObject:dicts forKey:VSERSION_MANAGER];
                        [defs synchronize];

                        Alert* alert = [[Alert alloc] initWithTitle:@"有新版本更新" message:details delegate:nil cancelButtonTitle:@"就是不更新" otherButtonTitles:@"好吧,更一下", nil];
                        [alert setContentAlignment:NSTextAlignmentLeft];
                        [alert setLineSpacing:5];
                        __weak typeof(self) weakSelf = self;
                        [alert setClickBlock:^(Alert *alertView, NSInteger buttonIndex) {
                            if (buttonIndex == 1) {
                                [weakSelf openAppWithIdentifier];
                            }
                        }];
                        [alert show];
                    }
                    else{
                        if(needTip){
                            Alert* alert = [[Alert alloc] initWithTitle:@"当前没有新版本"
                                                                message:[NSString stringWithFormat:@"您当前使用的是最新版本\n 版本号为:%@",self.applicationVersion]
                                                               delegate:nil
                                                      cancelButtonTitle:@"我知道了"
                                                      otherButtonTitles:nil];
                            //[alert setContentAlignment:NSTextAlignmentLeft];
                            [alert setLineSpacing:5];
                            [alert show];
                        }
                    }
                }
                else{
                    if(needTip){
                        Alert* alert = [[Alert alloc] initWithTitle:@"错误"
                                                            message:[NSString stringWithFormat:@"与更新服务器连接失败!\n请稍后再试\n 当前版本号为:%@",self.applicationVersion]
                                                           delegate:nil
                                                  cancelButtonTitle:@"我知道了"
                                                  otherButtonTitles:nil];
                        //[alert setContentAlignment:NSTextAlignmentLeft];
                        [alert setLineSpacing:5];
                        [alert show];
                    }

                }

            }
        }];
        [dataTask resume];
    });
}


- (NSString *)versionDetailsSince:(NSString *)lastVersion inDict:(NSDictionary *)dict{
    BOOL newVersionFound = NO;
    NSMutableString *details = [NSMutableString string];
    NSArray *versions = [[dict allKeys] sortedArrayUsingSelector:@selector(compareVersionDescending:)];
    for (NSString* version in versions) {
        if ([version compareVersion:lastVersion] == NSOrderedDescending) {
            newVersionFound = YES;
            [details appendString:[self versionDetails:version inDict:dict]?:@""];
        }
    }
    return newVersionFound? [details stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] : nil;
}

- (NSString *)mostRecentVersionInDict:(NSDictionary *)dict
{
    return [[[dict allKeys] sortedArrayUsingSelector:@selector(compareVersion:)] lastObject];
}

- (NSString *)versionDetails:(NSString *)version inDict:(NSDictionary *)dict
{
    id versionData = dict[version];
    if ([versionData isKindOfClass:[NSString class]])
    {
        return versionData;
    }
    else if ([versionData isKindOfClass:[NSArray class]])
    {
        return [versionData componentsJoinedByString:@"\n"];
    }
    return nil;
}

- (void)openAppWithIdentifier{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.updateURL]];
    });
}

@end
