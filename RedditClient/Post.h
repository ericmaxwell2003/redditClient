//
//  Post.h - Post is a simple data object to hold the information about a post on Reddit.
//

#import <UIKit/UIKit.h>

@interface Post : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;

@property (nonatomic, strong) NSString *thumbnailUrl;
@property (nonatomic, strong) NSString *fullImageUrl;

@end
