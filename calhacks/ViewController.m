//
//  ViewController.m
//  calhacks
//
//  Created by Misbah Khan on 10/4/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>

@interface ViewController (){
    CLLocationManager *locationManager;
    __weak IBOutlet MKMapView *map;
    BOOL pickup, dropoff;
    CLLocationCoordinate2D pick, drop;
    NSString *pickaddress, *dropaddress, *pickname, *dropname;
    MKPointAnnotation *pickpoint, *droppoint;
    IBOutlet UIDatePicker *datepicker;
    MKMapItem *pickitem, *dropitem;
    IBOutlet UIButton *requestbutton;
    MKPolyline *overlay;
    NSDictionary *startplace, *endplace;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [datepicker setMinimumDate:[NSDate date]];

    [map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    map.delegate = self;
    pickup = FALSE;
    dropoff = FALSE;
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)dropped:(id)sender {
    NSString *title;
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    
    
    
    if(!pickup){
        title = @"Pickup";
        pickup = TRUE;
        [_dropbutton setImage:[UIImage imageNamed:@"dropoff.png"] forState:UIControlStateNormal];
        pick = [map centerCoordinate];
        pickpoint = annotation;
    }else{
        title = @"Dropoff";
        dropoff = TRUE;
        [_dropbutton setEnabled:NO];
        [_dropbutton setHidden:YES];
        drop = [map centerCoordinate];
        droppoint = annotation;
        [requestbutton setEnabled:YES];
    }

    [annotation setCoordinate:[map centerCoordinate]];
    [annotation setTitle:title];
    [map addAnnotation:annotation];
    
}

- (void) getplace
{
        CLGeocoder *coder = [[CLGeocoder alloc] init];
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:pick.latitude longitude:pick.longitude];
        CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:drop.latitude longitude:drop.longitude];
        [coder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *place = [placemarks objectAtIndex:0];
            pickitem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:place]];
            NSString *line1 = [[[place addressDictionary] objectForKey:@"FormattedAddressLines"] objectAtIndex:0];
            NSString *line2 = [[[place addressDictionary] objectForKey:@"FormattedAddressLines"] objectAtIndex:1];
            NSString *address = [line1 stringByAppendingString:@", "];
            address = [address stringByAppendingString:line2];
            pickaddress = encode(address);
            pickname = encode([place name]);
            startplace = [place addressDictionary];
            [coder reverseGeocodeLocation:loc2 completionHandler:^(NSArray *placemarks, NSError *error) {
                CLPlacemark *place = [placemarks objectAtIndex:0];
                dropitem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:place]];
                NSString *line1 = [[[place addressDictionary] objectForKey:@"FormattedAddressLines"] objectAtIndex:0];
                NSString *line2 = [[[place addressDictionary] objectForKey:@"FormattedAddressLines"] objectAtIndex:1];
                NSString *address = [line1 stringByAppendingString:@", "];
                address = [address stringByAppendingString:line2];
                dropaddress = encode(address);
                dropname = encode([place name]);
                endplace = [place addressDictionary];
                [self calcroute];
            }];
        }];
}

- (void) calcroute
{
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    [request setSource:pickitem];
    [request setDestination:dropitem];
    [request setTransportType:MKDirectionsTransportTypeAutomobile];
    [request setRequestsAlternateRoutes:NO];
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (!error) {
            for (MKRoute *route in [response routes]) {
//                NSLog(@"route: %@", [route steps]);
                
                NSUInteger pointCount = route.polyline.pointCount;
                
                //allocate a C array to hold this many points/coordinates...
                CLLocationCoordinate2D *routeCoordinates
                = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                
                //get the coordinates (all of them)...
                [route.polyline getCoordinates:routeCoordinates
                                         range:NSMakeRange(0, pointCount)];
                
                //this part just shows how to use the results...
//                NSLog(@"route pointCount = %d", pointCount);
                
                
                
//                for (int c=0; c < pointCount; c++){
//                    NSLog(@"routeCoordinates[%d] = %f, %f", 
//                          c, routeCoordinates[c].latitude, routeCoordinates[c].longitude);
//                }

                
                if (overlay) [map removeOverlay:overlay];
                
                overlay = [route polyline];
                
                [map addOverlay:overlay level:MKOverlayLevelAboveRoads];
                
                PFObject *trip = [PFObject objectWithClassName:@"Trips"];
                PFGeoPoint *start = [PFGeoPoint geoPointWithLatitude:routeCoordinates[0].latitude longitude:routeCoordinates[0].longitude];
                PFGeoPoint *end = [PFGeoPoint geoPointWithLatitude:routeCoordinates[pointCount-1].latitude longitude:routeCoordinates[pointCount-1].longitude];
                PFGeoPoint *mid = [PFGeoPoint geoPointWithLatitude:routeCoordinates[(int)ceil(pointCount/2)].latitude longitude:routeCoordinates[(int)ceil(pointCount/2)].longitude];
                trip[@"start"] = start;
                trip[@"mid"] = mid;
                trip[@"end"] = end;
                trip[@"starter"] = [PFUser currentUser];
                trip[@"distance"] = [NSNumber numberWithFloat:[route distance]];
                trip[@"traveltime"] = [NSNumber numberWithFloat:[route expectedTravelTime]];
                trip[@"startplace"] = startplace;
                trip[@"endplace"] = endplace;
                trip[@"time"] = [datepicker date]; 
                [trip saveInBackground];
                free(routeCoordinates);
                // You can also get turn-by-turn steps, distance, advisory notices, ETA, etc by accessing various route properties.
            }
        }else{
            NSLog(@"%@", [error description]);
        }
    }];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        [renderer setStrokeColor:[UIColor colorWithRed:0.09 green:0.49 blue:0.96 alpha:1]];
        [renderer setLineWidth:2.5];
        return renderer;
    }
    return nil;
}

- (IBAction)reset:(id)sender {
    [map removeOverlay:overlay];
    [map removeAnnotation:pickpoint];
    [map removeAnnotation:droppoint];
    pickup = dropoff = FALSE;
    [_dropbutton setImage:[UIImage imageNamed:@"Pin Drop Scaled.png"] forState:UIControlStateNormal];
    [_dropbutton setEnabled:YES];
    [_dropbutton setHidden:NO];
    [requestbutton setEnabled:NO];
}

- (IBAction)request:(id)sender {
    [self getplace];
//    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
//    if (localNotif == nil)
//        return;
//    localNotif.fireDate = datepicker.date;
//    localNotif.timeZone = [NSTimeZone defaultTimeZone];
//    
//    localNotif.alertBody = @"Time to take your Uber";
//    localNotif.alertAction = @"View";
//    
//    localNotif.soundName = UILocalNotificationDefaultSoundName;
//    localNotif.applicationIconBadgeNumber = 1;
//    
//    // Specify custom data for the notification
//    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"someValue" forKey:@"someKey"];
//    localNotif.userInfo = infoDict;
//    
//    // Schedule the notification
//    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
//    
//    [self callurl];
}

- (void) callurl
{
    NSString *url = [NSString stringWithFormat:@"uber://?action=setPickup&pickup[latitude]=%f&pickup[longitude]=%f&pickup[nickname]=%@&pickup[formatted_address]=%@&dropoff[latitude]=%f&dropoff[longitude]=%f&dropoff[nickname]=%@&dropoff[formatted_address]=%@&product_id=a1111c8c-c720-46c3-8534-2fcdd730040d", pick.latitude, pick.longitude, pickname, pickaddress, drop.latitude, drop.longitude, dropname, dropaddress];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

NSString* encode(NSString *string) {
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                            (CFStringRef) string,
                                            NULL,
                                            (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
