//
//  RedditTableViewCell.h
//  Used a custom table view cell to get more control over the layout and view constraints.
//

#import <UIKit/UIKit.h>

@interface RedditTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *postTitle;
@property (weak, nonatomic) IBOutlet UILabel *postSubtitle;

@end
