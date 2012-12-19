/*
 * This file is part of the JTGestureBasedTableView package.
 * (c) James Tang <mystcolor@gmail.com>, Paul van Nugteren <PMvanNugteren anAddSignHere gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>

@interface UIColor (JTGestureBasedTableViewHelper)
- (UIColor *)colorWithBrightness:(CGFloat)brightness;
- (UIColor *)colorWithHueOffset:(CGFloat)hueOffset;
+ (UIColor *)DoneTextColor;
+ (UIColor *)DoneCellBackgroundColor;
+(UIColor *)EditingStateBackgroundColorForDoneCell;
+ (UIColor *)tableViewCellHighestPriorityDefaultBackgroundColor;
+ (UIColor *)tableView: (UITableView *) tableView CellBackgroundColor: (UIColor *) initialBackgroundColor AtIndexPath: (NSIndexPath *)indexPath;
@end

