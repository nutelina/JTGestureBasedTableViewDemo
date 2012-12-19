/*
 * This file is part of the JTGestureBasedTableView package.
 * (c) James Tang <mystcolor@gmail.com>, Paul van Nugteren <PMvanNugteren anAddSignHere gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIColor+JTGestureBasedTableViewHelper.h"

@implementation UIColor (JTGestureBasedTableViewHelper)
- (UIColor *)colorWithBrightness:(CGFloat)brightnessComponent {
    
    UIColor *newColor = nil;
    if ( ! newColor) {
        CGFloat hue, saturation, brightness, alpha;
        if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
            newColor = [UIColor colorWithHue:hue
                                  saturation:saturation
                                  brightness:brightness * brightnessComponent
                                       alpha:alpha];
        }
    }
    
    if ( ! newColor) {
        CGFloat red, green, blue, alpha;
        if ([self getRed:&red green:&green blue:&blue alpha:&alpha]) {
            newColor = [UIColor colorWithRed:red*brightnessComponent
                                       green:green*brightnessComponent
                                        blue:blue*brightnessComponent
                                       alpha:alpha];
        }
    }
    
    if ( ! newColor) {
        CGFloat white, alpha;
        if ([self getWhite:&white alpha:&alpha]) {
            newColor = [UIColor colorWithWhite:white * brightnessComponent alpha:alpha];
        }
    }
    
    return newColor;
}

- (UIColor *)colorWithHueOffset:(CGFloat)hueOffset {
    UIColor *newColor = nil;
    if ( ! newColor) {
        CGFloat hue, saturation, brightness, alpha;
        if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
            // We wants the hue value to be between 0 - 1 after appending the offset
            CGFloat newHue = fmodf((hue + hueOffset), 1);
            newColor = [UIColor colorWithHue:newHue
                                  saturation:saturation
                                  brightness:brightness
                                       alpha:alpha];
        }
    }
    return newColor;
}

+ (UIColor *)DoneTextColor {
    return [UIColor grayColor];
}

+ (UIColor *)DoneCellBackgroundColor {
    return [UIColor darkGrayColor];
}

+(UIColor *)EditingStateBackgroundColorForDoneCell {
    return [UIColor colorWithRed:0 green:0.6 blue:0.30 alpha:1];
}

+ (UIColor *)tableViewCellHighestPriorityDefaultBackgroundColor {
    return [UIColor colorWithRed:1 green:0.25 blue:0.15 alpha:1];
    
}

+ (UIColor *)tableView: (UITableView *) tableView CellBackgroundColor: (UIColor *) initialBackgroundColor AtIndexPath: (NSIndexPath *)indexPath {
    return  [initialBackgroundColor colorWithHueOffset:0.12 * indexPath.row / [tableView numberOfRowsInSection:indexPath.section]];
}

@end
