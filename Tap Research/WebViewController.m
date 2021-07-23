//
//  WebViewController.m
//  Tap Research
//
//  Created by Danny Tsang on 7/22/21.
//

#import "WebViewController.h"

@interface WebViewController ()
{
    WKWebView* webview;
}
@end

@implementation WebViewController

- (void)loadView {
    self->webview = [[WKWebView alloc] init];
    self.view = webview;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL* url = [NSURL URLWithString:self->urlString];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
    [self->webview loadRequest:request];
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
