//
//  API.m
//  calhacks
//
//  Created by Misbah Khan on 10/5/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import "API.h"

@implementation API

+ (id)sharedInstance {
    static API *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {

    }
    return self;
}

@end
