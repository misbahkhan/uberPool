//
//  ViewController.h
//  calhacks
//
//  Created by Misbah Khan on 10/4/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate, UIGestureRecognizerDelegate, MKMapViewDelegate>
@property (strong, nonatomic) IBOutlet UIButton *dropbutton;


@end

