//
//  loginViewController.m
//  calhacks
//
//  Created by Misbah Khan on 10/4/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import "loginViewController.h"
#import <Parse/Parse.h>

@interface loginViewController ()
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *phone;
@property (strong, nonatomic) IBOutlet UITextField *password;

@end

@implementation loginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated
{
    if([PFUser currentUser]) [self performSegueWithIdentifier:@"in" sender:self]; 
}

- (IBAction)signup:(id)sender {
    PFUser *user = [PFUser user];
    user.username = [_username text];
    user.password = [_password text];
    
    // other fields can be set just like with PFObject
    user[@"phone"] = [_phone text];
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [self performSegueWithIdentifier:@"in" sender:self];
        } else {
            NSString *errorString = [error userInfo][@"error"];
            // Show the errorString somewhere and let the user try again.
        }
    }];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:[PFUser currentUser][@"username"] forKey:@"channels"];
    [currentInstallation saveInBackground];
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
