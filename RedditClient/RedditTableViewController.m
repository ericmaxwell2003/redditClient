
#import "RedditTableViewController.h"

#import "RedditDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+SVPullToRefresh.h"
#import "UIScrollView+SVInfiniteScrolling.h"
#import "AsyncImageView.h"
#import "RedditService.h"
#import "Post.h"
#import "RedditTableViewCell.h"
#import "MMProgressHUD.h"

static NSString *initialPage = @"";

@interface RedditTableViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *currentPage;
@property (nonatomic, strong) NSMutableArray *postList;

@end

@implementation RedditTableViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.postList = [NSMutableArray array];
    self.currentPage = initialPage;
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    if([self.restorationIdentifier isEqualToString:@"awwTableView"]) {
        self.navigationItem.title = @"Aww";
    } else if([self.restorationIdentifier isEqualToString:@"foodTableView"]) {
        self.navigationItem.title = @"Food";
    } else {
        NSLog(@"Erorr, this subreddit board is not supported %@", self.restorationIdentifier);
    }
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostsLoaded:) name:POSTS_DID_LOAD object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorLoadingPosts:) name:POSTS_DID_LOAD_WITH_ERROR object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    __weak typeof(self) weakSelf = self;
    // refresh new data when pull the table list
    [self.tableView addPullToRefreshWithActionHandler:^{
        weakSelf.currentPage = initialPage; // reset the page
        [weakSelf.postList removeAllObjects]; // remove all data
        [weakSelf.tableView reloadData]; // before load new content, clear the existing table list
        [weakSelf loadFromServer]; // load new data
        [weakSelf.tableView.pullToRefreshView stopAnimating]; // clear the animation
        
        // once refresh, allow the infinite scroll again
        weakSelf.tableView.showsInfiniteScrolling = YES;
    }];
    
    // load more content when scroll to the bottom most
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf loadFromServer];
    }];
    
    // load initial set from server on start.
    [self loadFromServer];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

#pragma mark - notification events
- (void)newPostsLoaded:(NSNotification*)notification
{
    NSDictionary *results = notification.object;
    
    NSArray *posts = [results objectForKey:@"posts"];
    // if no more result
    if ([posts count] == 0) {
        self.tableView.showsInfiniteScrolling = NO; // stop the infinite scroll
        return;
    }
    
    _currentPage = [results objectForKey:@"after"];
    int currentRow = (int) self.postList.count;
    
    // store the items into the existing list
    for (id obj in posts) {
        [self.postList addObject:obj];
    }
    [self reloadTableView:currentRow];
    
    // clear the pull to refresh & infinite scroll, this 2 lines very important
    [self.tableView.pullToRefreshView stopAnimating];
    [self.tableView.infiniteScrollingView stopAnimating];
 
    [MMProgressHUD dismissWithSuccess:@"" title:@"" afterDelay:0.2];
}

- (void)errorLoadingPosts:(NSNotification*)notification
{
    self.tableView.showsInfiniteScrolling = NO;
    NSError *error = notification.object;
    NSLog(@"error %@", error);
    [MMProgressHUD dismissWithError:@"" title:@"Unable to Fetch Reddits" afterDelay:1.0];
}

/**
 *  This is helpful for the scenario where the user did not have a data connection, and loadded no posts.
 *  Then, backgrounded the app and came back in.  In this case, it's nice to try to load posts again for them
 *  Without handling this event, they come into an empty tableView.
 */
- (void)handleDidBecomeActive:(NSNotification *)notification
{
    // We only want to reload the table if there were no posts.  It's annoying to reaload every time
    // they bounce between this and another app otherwise.
    if(self.postList.count == 0) {
        [self loadFromServer];
    }
}



#pragma mark - Segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Post *post = [self.postList objectAtIndex:indexPath.row];
    RedditDetailViewController *vc = segue.destinationViewController;
    vc.imageUrl = post.fullImageUrl;
    vc.navigationItem.title = post.title;
}


#pragma mark - UITableViewDataSource and Helpers
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.postList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    RedditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    Post *post = [self.postList objectAtIndex:[indexPath row]];
    cell.postTitle.text = post.title;
    cell.postSubtitle.text = post.subtitle;
    cell.thumbnail.imageURL = [NSURL URLWithString:post.thumbnailUrl];
    return cell;
}

- (void)loadFromServer
{
    // if the list is currently empty, we want to show the global loading
    // otherwise we'll not and just let SVPullToRefresh/InfiniteScrolling indicators display.
    if(self.postList.count == 0) {
        [MMProgressHUD showWithTitle:@"Loading..."];
    }
    
    SubRedditType type;
    if([self.restorationIdentifier isEqualToString:@"awwTableView"]) {
        type = kaww;
    } else if([self.restorationIdentifier isEqualToString:@"foodTableView"]) {
        type = kfood;
    } else {
        NSLog(@"Erorr, this subreddit board is not supported %@", self.restorationIdentifier);
    }
    
    RedditService *service = [RedditService sharedInstance];
    [service loadSubRedditTypeFromServer:type after:self.currentPage];
}

- (void)reloadTableView:(int)startingRow
{
    // the last row after added new items
    int endingRow = (int)self.postList.count;
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (; startingRow < endingRow; startingRow++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:startingRow inSection:0]];
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}


@end
