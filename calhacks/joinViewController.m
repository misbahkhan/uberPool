//
//  joinViewController.m
//  calhacks
//
//  Created by Misbah Khan on 10/4/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import "joinViewController.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>

@interface joinViewController (){
    NSMutableArray *triplist;
    CLLocationCoordinate2D startloc, endloc;
    MKPointAnnotation *startpoint, *endpoint, *request;
    MKMapItem *startitem, *enditem;
    MKPolyline *overlay;
    IBOutlet UIButton *dropper;
    NSString *objid;
}
@property (strong, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet UITableView *tripstable;

@end

@implementation joinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    _map.delegate = self;
    startpoint = [[MKPointAnnotation alloc] init];
    endpoint = [[MKPointAnnotation alloc] init];
    request = [[MKPointAnnotation alloc] init];
    // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated
{
    [self gettrips];
}

- (void) gettrips
{
    PFQuery *starter = [PFQuery queryWithClassName:@"Trips"];
    [starter whereKey:@"starter" notEqualTo:[PFUser currentUser]];
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[starter]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            triplist = [objects mutableCopy];
            [_tripstable reloadData];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (IBAction)dropped:(id)sender {
    [request setCoordinate:[_map centerCoordinate]];
    [request setTitle:@"Request"];
    [_map addAnnotation:request];
    [dropper setHidden:YES];
    [dropper setEnabled:NO];
    
    [PFCloud callFunctionInBackground:@"request"
                       withParameters:@{@"lat": [NSNumber numberWithDouble:request.coordinate.latitude], @"lon": [NSNumber numberWithDouble:request.coordinate.longitude], @"tripid": objid}
        block:^(NSString *ratings, NSError *error) {
            if (!error) {
                NSLog(@"%@", ratings);
            }
        }];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [triplist count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"triplist"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"triplist"];
    }
    
    float time = floor([[[triplist objectAtIndex:indexPath.row] objectForKey:@"time"] timeIntervalSince1970]);
    time += [[[triplist objectAtIndex:indexPath.row] objectForKey:@"traveltime"] integerValue];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:time];
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMM dd, yyyy HH:mm"];
    NSString *dateString = [format stringFromDate:date];
    NSDateFormatter *inFormat = [[NSDateFormatter alloc] init];
    [inFormat setDateFormat:@"MMM dd, yyyy"];
    NSDate *parsed = [inFormat dateFromString:dateString];
    
    NSDictionary *place = [[triplist objectAtIndex:indexPath.row] objectForKey:@"startplace"];
    cell.textLabel.text = [place objectForKey:@"City"];
    cell.detailTextLabel.text = dateString;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [dropper setHidden:NO];
    [dropper setEnabled:YES];
    NSLog(@"%@", [triplist objectAtIndex:indexPath.row]);
    PFObject *trip = [triplist objectAtIndex:indexPath.row];
    objid = trip.objectId;
    
    PFGeoPoint *start = [[triplist objectAtIndex:indexPath.row] objectForKey:@"start"];
    PFGeoPoint *end = [[triplist objectAtIndex:indexPath.row] objectForKey:@"end"];
    
    startloc = CLLocationCoordinate2DMake(start.latitude, start.longitude);
    endloc = CLLocationCoordinate2DMake(end.latitude, end.longitude);
    
    [startpoint setCoordinate:startloc];
    [startpoint setTitle:@"Pickup"];
    [_map addAnnotation:startpoint];
    
    [endpoint setCoordinate:endloc];
    [endpoint setTitle:@"Drop off"];
    [_map addAnnotation:endpoint];
    
    [_map showAnnotations:@[startpoint, endpoint] animated:YES];
    [self getplace];
}

- (void) getplace
{
    CLGeocoder *coder = [[CLGeocoder alloc] init];
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:startloc.latitude longitude:startloc.longitude];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:endloc.latitude longitude:endloc.longitude];
    
    [coder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *place = [placemarks objectAtIndex:0];
        startitem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:place]];
        [coder reverseGeocodeLocation:loc2 completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *place = [placemarks objectAtIndex:0];
            enditem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:place]];
            [self calcroute];
        }];
    }];
}

- (void) calcroute
{
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    [request setSource:startitem];
    [request setDestination:enditem];
    [request setTransportType:MKDirectionsTransportTypeAutomobile];
    [request setRequestsAlternateRoutes:NO];
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (!error) {
            for (MKRoute *route in [response routes]) {
                if (overlay) [_map removeOverlay:overlay];
                overlay = [route polyline];
                [_map addOverlay:overlay level:MKOverlayLevelAboveRoads];
                [dropper setHidden:NO];
            }
        }else{
            NSLog(@"%@", [error description]);
        }
    }];
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
