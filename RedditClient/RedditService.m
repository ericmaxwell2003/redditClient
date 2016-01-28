//
//  ReditService.m
//

#import "RedditService.h"

#import "AFNetworking.h"
#import "Post.h"
#import "NSDate+TimeAgo.h"

@implementation RedditService

+ (RedditService *)sharedInstance
{
    __strong static RedditService *_sharedObject = nil;
    static dispatch_once_t pred=0;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}


- (void)loadSubRedditTypeFromServer:(SubRedditType)subRedditType after:(NSString *)after
{
    NSString *urlString;
    switch(subRedditType) {
        case kaww :
            urlString = AWW_URL;
            break;
        case kfood :
            urlString = FOOD_URL;
            break;
    }

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:urlString parameters:@{@"after": after} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSMutableArray *posts = [NSMutableArray array];
        NSString *after = [[responseObject objectForKey:@"data"] objectForKey:@"after"];
        
        for (id json in [[responseObject objectForKey:@"data"] objectForKey:@"children"]) {
        
            Post *post = [[Post alloc] init];
            post.id = [[json objectForKey:@"data"] objectForKey:@"id"];
            post.title = [[json objectForKey:@"data"] objectForKey:@"title"];
            
            NSNumber *createdUtc = [[json objectForKey:@"data"] objectForKey:@"created_utc"];
            NSDate *datePosted = [NSDate dateWithTimeIntervalSince1970:createdUtc.intValue];
            NSString *postedBy = [[json objectForKey:@"data"] objectForKey:@"author"];
            NSString *subTitle = [NSString stringWithFormat:@"submitted %@ by %@", datePosted.timeAgo, postedBy];
            post.subtitle = subTitle;
            
            post.thumbnailUrl = [[json objectForKey:@"data"] objectForKey:@"thumbnail"];
            post.fullImageUrl = [[json objectForKey:@"data"] objectForKey:@"url"];
            
            [posts addObject:post];
        }
        NSDictionary *eventObject = @{@"posts": posts, @"after": after};
        [[NSNotificationCenter defaultCenter] postNotificationName:POSTS_DID_LOAD object:eventObject];
        

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:POSTS_DID_LOAD_WITH_ERROR object:error];
    }];
}


@end
