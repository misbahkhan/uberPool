//
//  tripsViewController.m
//  calhacks
//
//  Created by Misbah Khan on 10/4/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import "tripsViewController.h"
#import <Parse/Parse.h>
#import "API.h"

@interface tripsViewController (){
    NSMutableArray *triplist;
    IBOutlet MKMapView *map;
    CLLocationCoordinate2D startloc, buddyloc, endloc;
    MKPointAnnotation *startpoint, *buddystartpoint, *endpoint;
    MKMapItem *startitem, *buddyitem, *enditem;
    MKPolyline *overlay;
    API *shared;
    BOOL isBuddy;
}
@property (strong, nonatomic) IBOutlet UITableView *tripstable;

@end

@implementation tripsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    map.delegate = self; 
    startpoint = [[MKPointAnnotation alloc] init];
    buddystartpoint = [[MKPointAnnotation alloc] init];
    endpoint = [[MKPointAnnotation alloc] init];
    
    // Do any additional setup after loading the view.
    [self gettrips];
    shared = [API sharedInstance];
    isBuddy = false;
}

- (void) gettrips
{
    PFQuery *starter = [PFQuery queryWithClassName:@"Trips"];
    [starter whereKey:@"starter" equalTo:[PFUser currentUser]];
    
    PFQuery *buddy = [PFQuery queryWithClassName:@"Trips"];
    [buddy whereKey:@"buddy" equalTo:[PFUser currentUser]];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[starter,buddy]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            triplist = [objects mutableCopy];
            [_tripstable reloadData];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocationCoordinate2D loc = [userLocation coordinate];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 250, 250);
    [mapView setRegion:region animated:YES];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"updated");
}

- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [triplist count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"triplist"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"triplist"];
    }
    
    float distance = [[[triplist objectAtIndex:indexPath.row] objectForKey:@"distance"] floatValue];
    distance = distance/1609.3;
    
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    NSDictionary *place = [[triplist objectAtIndex:indexPath.row] objectForKey:@"startplace"];
    cell.textLabel.text = [place objectForKey:@"City"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f mi", distance];
    return cell;
}

- (void) getplace
{
    CLGeocoder *coder = [[CLGeocoder alloc] init];
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:startloc.latitude longitude:startloc.longitude];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:endloc.latitude longitude:endloc.longitude];
    CLLocation *loc3;
    if (isBuddy) {
        loc3 = [[CLLocation alloc] initWithLatitude:buddyloc.latitude longitude:buddyloc.longitude];
    }
    
    [coder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *place = [placemarks objectAtIndex:0];
        startitem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:place]];
        [coder reverseGeocodeLocation:loc2 completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *place = [placemarks objectAtIndex:0];
            enditem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:place]];
            if (isBuddy) {
                [coder reverseGeocodeLocation:loc3 completionHandler:^(NSArray *placemarks, NSError *error) {
                    CLPlacemark *place = [placemarks objectAtIndex:0];
                    buddyitem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:place]];
                    [self calcroute];
                }];
            }else{
                [self calcroute];
            }
        }];
    }];
}

- (void) calcroute
{
    if (isBuddy) {
        MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
        [request setSource:startitem];
        [request setDestination:buddyitem];
        [request setTransportType:MKDirectionsTransportTypeAutomobile];
        [request setRequestsAlternateRoutes:NO];
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            if (!error) {
                for (MKRoute *route in [response routes]) {
                    [map removeOverlays:map.overlays];
                    [map addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
                }
            }else{
                NSLog(@"%@", [error description]);
            }
        }];
        MKDirectionsRequest *request2 = [[MKDirectionsRequest alloc] init];
        [request2 setSource:buddyitem];
        [request2 setDestination:enditem];
        [request2 setTransportType:MKDirectionsTransportTypeAutomobile];
        [request2 setRequestsAlternateRoutes:NO];
        MKDirections *directions2 = [[MKDirections alloc] initWithRequest:request2];
        [directions2 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            if (!error) {
                for (MKRoute *route in [response routes]) {
                    [map addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
                }
            }else{
                NSLog(@"%@", [error description]);
            }
        }];
    }else{
        MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
        [request setSource:startitem];
        [request setDestination:enditem];
        [request setTransportType:MKDirectionsTransportTypeAutomobile];
        [request setRequestsAlternateRoutes:NO];
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            if (!error) {
                for (MKRoute *route in [response routes]) {
                    [map removeOverlays:map.overlays];
                    [map addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
                }
            }else{
                NSLog(@"%@", [error description]);
            }
        }];
    }
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    isBuddy = false;
    
    NSLog(@"%@", [triplist objectAtIndex:indexPath.row]);
    PFGeoPoint *start = [[triplist objectAtIndex:indexPath.row] objectForKey:@"start"];
    PFGeoPoint *buddystart = [[triplist objectAtIndex:indexPath.row] objectForKey:@"buddystart"];
    PFGeoPoint *end = [[triplist objectAtIndex:indexPath.row] objectForKey:@"end"];
    
    startloc = CLLocationCoordinate2DMake(start.latitude, start.longitude);
    buddyloc = CLLocationCoordinate2DMake(buddystart.latitude, buddystart.longitude);
    endloc = CLLocationCoordinate2DMake(end.latitude, end.longitude);
    
    [startpoint setCoordinate:startloc];
    [startpoint setTitle:@"Pickup"];
    [map addAnnotation:startpoint];
    
    [buddystartpoint setCoordinate:buddyloc];
    [buddystartpoint setTitle:@"Buddy Pickup"];
    [map addAnnotation:buddystartpoint];
    

    [endpoint setCoordinate:endloc];
    [endpoint setTitle:@"Drop off"];
    [map addAnnotation:endpoint];
    
    [map showAnnotations:@[startpoint, endpoint] animated:YES];
    
    if ([[triplist objectAtIndex:indexPath.row] objectForKey:@"buddystart"]) {
        isBuddy = true;
    }
    
    [self getplace];
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    shared.trip = [triplist objectAtIndex:indexPath.row];
    shared.overlay = overlay;
    shared.startpoint = startpoint;
    shared.endpoint = endpoint;
    [self performSegueWithIdentifier:@"detail" sender:self]; 
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
