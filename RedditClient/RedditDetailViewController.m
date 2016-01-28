//
//  AwwDetailViewController.m
//

#import "RedditDetailViewController.h"
#import "MMProgressHUD.h"
#import "AFNetworking.h"

@interface RedditDetailViewController()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation RedditDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if(self.imageUrl) {
        [MMProgressHUD showWithTitle:@"Loading..."];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: self.imageUrl]
                                                      cachePolicy: NSURLRequestUseProtocolCachePolicy
                                                  timeoutInterval: 10];
        self.webView.delegate = self;
        [self.webView loadRequest: request];
    }

}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [MMProgressHUD dismiss];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"error %@", error);
    [MMProgressHUD dismissWithError:@"" title:@"Unable to Fetch Post" afterDelay:1.0];
}


@end
