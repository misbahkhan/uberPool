//
//  API.h
//  calhacks
//
//  Created by Misbah Khan on 10/5/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface API : NSObject

@property (nonatomic, retain) NSDictionary *trip;
@property (nonatomic, retain) MKPolyline *overlay;
@property (nonatomic, retain) MKPointAnnotation *startpoint;
@property (nonatomic, retain) MKPointAnnotation *endpoint;

+ (id) sharedInstance; 

@end
