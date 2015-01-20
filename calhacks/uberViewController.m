//
//  uberViewController.m
//  calhacks
//
//  Created by Misbah Khan on 10/4/14.
//  Copyright (c) 2014 Khanster. All rights reserved.
//

#import "uberViewController.h"

@interface uberViewController ()
@property (strong, nonatomic) IBOutlet UIWebView *web;

@end

@implementation uberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_web setDelegate:self];
    [_web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://login.uber.com/oauth/authorize?response_type=code&client_id=N9g5Fz_egd3CrgXHOjji3mIkWKuKLml0&scope=history"]]];
    // Do any additional setup after loading the view.
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *html = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSLog(@"%@", json);
    if ([json objectForKey:@"access_token"]) {
        [webView setHidden:YES];
    }
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
