//
//  ReditService.h - Data connectivity with Reddit.  Use to get results from a subreddit.
//

#import <Foundation/Foundation.h>

@interface RedditService : NSObject

#define AWW_URL @"https://www.reddit.com/r/aww.json"
#define FOOD_URL @"https://www.reddit.com/r/food.json"

#define POSTS_DID_LOAD @"POSTS_DID_LOAD"
#define POSTS_DID_LOAD_WITH_ERROR @"POSTS_DID_LOAD_WITH_ERROR"

typedef enum {
    kaww = 0,
    kfood
} SubRedditType;

/**
 *  Get a singleton instance of the reddit service.
 */
+ (RedditService *)sharedInstance;


/**
 *  Load reddit posts from the server.  This receiver will fire either a 
 *  notification after the results have been fetched
 *  if SUCCESS ->
 *       POSTS_DID_LOAD event - The object sent in the notitication is a Dictionary @{after: <after>, posts: <postArray>}
 *  if FAILURE ->
 *       POSTS_DID_LOAD_WITH_ERROR event - The object sent in the notfication is an NSError generated by the error.
 */
- (void)loadSubRedditTypeFromServer:(SubRedditType)subRedditType after:(NSString *)after;

@end
