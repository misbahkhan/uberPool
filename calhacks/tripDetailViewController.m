//
//  tripDetailViewController.m
//  calhacks
//
//  Created by Misbah Khan on 10/5/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import "tripDetailViewController.h"
#import "API.h"

@interface tripDetailViewController (){
    API *shared;
    IBOutlet MKMapView *map;
}
@end

@implementation tripDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    shared = [API sharedInstance];
    [map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    map.delegate = self;
    // Do any additional setup after loading the view.
}

- (IBAction)openInUber:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"uber://?action=setPickup&pickup[latitude]=37.775818&pickup[longitude]=-122.418028&pickup[nickname]=UberHQ&pickup[formatted_address]=1455%20Market%20St%2C%20San%20Francisco%2C%20CA%2094103&dropoff[latitude]=37.802374&dropoff[longitude]=-122.405818&dropoff[nickname]=Coit%20Tower&dropoff[formatted_address]=1%20Telegraph%20Hill%20Blvd%2C%20San%20Francisco%2C%20CA%2094133&product_id=a1111c8c-c720-46c3-8534-2fcdd730040d"]];
}

- (void) viewDidAppear:(BOOL)animated
{
    [self rmpins];
    [map removeOverlay:shared.overlay]; 
    [map addAnnotation:shared.startpoint];
    [map addAnnotation:shared.endpoint];
    
    [map showAnnotations:@[shared.startpoint, shared.endpoint] animated:YES];
//    [map addOverlay:shared.overlay level:MKOverlayLevelAboveRoads];
}
     
 - (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay2
{
    if ([overlay2 isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay2];
        [renderer setStrokeColor:[UIColor colorWithRed:0.09 green:0.49 blue:0.96 alpha:1]];
        [renderer setLineWidth:2.5];
        return renderer;
    }
    return nil;
}
     
- (void)rmpins
{
    id userLocation = [map userLocation];
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[map annotations]];
    if ( userLocation != nil ) {
        [pins removeObject:userLocation]; // avoid removing user location off the map
    }
    
    [map removeAnnotations:pins];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocationCoordinate2D loc = [userLocation coordinate];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 250, 250);
    [mapView setRegion:region animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
