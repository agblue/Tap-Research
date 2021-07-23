//
//  ViewController.m
//  Tap Research
//
//  Created by Danny Tsang on 7/22/21.
//

#import "ViewController.h"
#import "WebViewController.h"

#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

@interface ViewController ()
{
    @private
    bool trackingAuthorized;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
        switch (status) {
            case ATTrackingManagerAuthorizationStatusAuthorized:
                NSLog(@"Authorized");
                self->trackingAuthorized = true;
                break;
            case ATTrackingManagerAuthorizationStatusDenied:
                NSLog(@"Denied Authorization");
                self->trackingAuthorized = false;
                break;
            case ATTrackingManagerAuthorizationStatusRestricted:
                NSLog(@"Restricted Authorization");
                self->trackingAuthorized = false;
                break;
            case ATTrackingManagerAuthorizationStatusNotDetermined:
                NSLog(@"Not Determined Authorization");
                self->trackingAuthorized = false;
                break;
            default:
                NSLog(@"Unknown Authorization");
                self->trackingAuthorized = false;
                break;
        }
    }];
}

- (IBAction)getSurveysTapped:(UIButton *)sender {
    // Check to see if the user has authorized app tracking.
    if (self->trackingAuthorized == YES) {
        // Perform a call to the Survey Offers API to check for available offers.
        [self pollForAvailableSurveys];
    } else {
        // User did not allow for app tracking.
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Tracking Not Authorized" message:@"Please update your app settings to allow for survey tracking." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)pollForAvailableSurveys {
    // Check to see if there is a previous poll response.
    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
    NSDate* expirationDate = [defaults valueForKey:@"expirationDate"];
    if (expirationDate != NULL) {
        if ([expirationDate compare:NSDate.now] == NSOrderedDescending) {
            NSLog(@"Loading previous response.");
            NSDictionary* lastPollResponse = [defaults objectForKey:@"lastPollResponse"];
            NSString* urlString = (NSString*) [lastPollResponse objectForKey:@"offer_url"];
            [self displayOffersAtURLString:urlString];
            return;
        }
    }
        
    // Create a new polling request.
    // Define request parameters
    NSLog(@"Creation new polling request.");
    NSUUID* adID = ASIdentifierManager.sharedManager.advertisingIdentifier; // Coded to use Physical Device Identifier: A50A8F6E-92DA-4572-B1A5-9BB00145E77B
    NSString* apiToken = @"f47e5ce81688efee79df771e9f9e9994";
    NSString* userIdentifer = @"codetest123";
    NSString* parameterString = [NSString stringWithFormat:@"device_identifier=A50A8F6E-92DA-4572-B1A5-9BB00145E77B&api_token=%@&user_identifier=%@", apiToken, userIdentifer];
    NSData* parameterData = [parameterString dataUsingEncoding:NSASCIIStringEncoding];
    
    // Setup request URL
    NSURL* url = [NSURL URLWithString:@"https://www.tapresearch.com/supply_api/surveys/offer"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:parameterData];
    
    // Execute URL Request
    NSURLSessionDataTask* task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        id jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
        // Check to verify that we received a dictionary back.
        if ([jsonData isKindOfClass:[NSDictionary class]]) {
            NSDictionary* dictionary = (NSDictionary*) jsonData;
            NSLog(@"Dictionary: %@", dictionary);

            // Check if we have an offer.
            if ((bool)[dictionary objectForKey:@"has_offer"] == YES) {
                // Offer is available.
                // Save off the response only if we have a valid offer to begin with.
                NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
                [defaults setValue:[NSDate dateWithTimeIntervalSinceNow:30] forKey:@"expirationDate"];
                [defaults setValue:dictionary forKey:@"lastPollResponse"];
                [defaults synchronize];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Offer is available, display the offer URL.
                    NSString* urlString = (NSString*) [dictionary objectForKey:@"offer_url"];
                    [self displayOffersAtURLString:urlString];
                });
            } else {
                // No Offers Available at this time.
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"No Offers Available" message:@"Please try again later to see available offers." preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alertController animated:true completion:nil];
                });
            }
        } else {
            // Invalid data returned.
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Invalid Data Returned" message:@"Data was returned in an unexpected format." preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:true completion:nil];
            });
        }
    }];
    [task resume];
}

- (void) displayOffersAtURLString:(NSString*) urlString {
    WebViewController* webVC = [[WebViewController alloc] init];
    webVC->urlString = urlString;
    [self presentViewController:webVC animated:true completion:nil];
}

@end
