//
//  ViewController.m
//  JTGestureBasedTableViewDemo
//
//  Created by James Tang on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "TransformableTableViewCell.h"
#import "JTTableViewGestureRecognizer.h"
#import "UIColor+JTGestureBasedTableViewHelper.h"

// Configure your viewController to conform to JTTableViewGestureEditingRowDelegate
// and/or JTTableViewGestureAddingRowDelegate depends on your needs
@interface ViewController () <JTTableViewGestureEditingRowDelegate, JTTableViewGestureAddingRowDelegate, JTTableViewGestureMoveRowDelegate>
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) JTTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic, strong) id grabbedObject;

@property (nonatomic, strong) UITextView *taskEntry; //We need just one textView just for entering text into one cell at a time. Needs to be strong because when weak taskEntry is released (ARC) when tableview:didSelectRowForIndexPath: ended
@property (nonatomic, strong) NSIndexPath *currentIndexPath;//Needs to be strong
@property (nonatomic) NSUInteger textViewPreviousNumberOfCharacters; //We need to know if the text increased or decreased in textViewDidChange


- (void)moveRowToBottomForIndexPath:(NSIndexPath *)indexPath;

@end

@implementation ViewController

@synthesize rows;
@synthesize tableViewRecognizer;
@synthesize grabbedObject;
@synthesize taskEntry = _taskEntry;
@synthesize currentIndexPath = _currentIndexPath;


#define ADDING_CELL @"Continue..."
#define DONE_CELL @"Done"
#define DUMMY_CELL @"Dummy"
#define COMMITING_CREATE_CELL_HEIGHT 60.0f
#define NORMAL_CELL_FINISHING_HEIGHT 60.0f

#define FONT_SIZE 14.0f
#define CELL_CONTENT_WIDTH 320.0f
#define CELL_CONTENT_MARGIN 12.0f
#define CELL_MAX_CONTENT_HEIGHT 20000.0f

#define TEXT_VIEW_OFF_SET_X 2 //These are the offsets to make the text
#define TEXT_VIEW_OFF_SET_Y 10 //in the textview appear in the same place as the cell's text


#define CHARACTERS_PER_LINE  40 //Rewrite by using CELL_CONTENT_WIDTH etc.
#define CELL_HEIGHT_CHUNK_PER_LINE 20 //Rewrite by using CELL_CONTENT_WIDTH etc.

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // In this example, we setup self.rows as datasource
    self.rows = [NSMutableArray arrayWithObjects:
                 @"Swipe to the right to complete",
                 @"Swipe to left to delete",
                 @"Drag down to create a new cell",
                 @"Pinch two rows apart to create cell",
                 @"Long hold to start reorder cell",
                 @"More then 27 characters on this line, word word word word word word word word word word word word word word word word word word", //test item!
                 nil];
    
    
    // Setup your tableView.delegate and tableView.datasource,
    // then enable gesture recognition in one line.
    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
    
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor  = [UIColor colorWithRed:0.75 green:0.26 blue:0.14 alpha:1];
    //self.tableView.rowHeight       = NORMAL_CELL_FINISHING_HEIGHT; //No we want dynamic rowheights for multple lines of text!
}

#pragma mark - Private Method

- (void)moveRowToBottomForIndexPath:(NSIndexPath *)indexPath {
    [self.tableView beginUpdates];
    
    id object = [self.rows objectAtIndex:indexPath.row];
    [self.rows removeObjectAtIndex:indexPath.row];
    [self.rows addObject:object];
    
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:[self.rows count] - 1 inSection:0];
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:lastIndexPath];
    
    [self.tableView endUpdates];
    
    [self.tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:lastIndexPath afterDelay:JTTableViewRowAnimationDuration];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.rows count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *object = [self.rows objectAtIndex:indexPath.row];
    UIColor *backgroundColor = [[UIColor colorWithRed:1 green:0.25 blue:0.15 alpha:1] colorWithHueOffset: (0.12 * indexPath.row / [self tableView:tableView numberOfRowsInSection:indexPath.section] )];
    if ([object isEqual:ADDING_CELL]) {
        NSString *cellIdentifier = nil;
        TransformableTableViewCell *cell = nil;
        
        // IndexPath.row == 0 is the case we wanted to pick the pullDown style
        if (indexPath.row == 0) {
            cellIdentifier = @"PullDownTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [TransformableTableViewCell transformableTableViewCellWithStyle:TransformableTableViewCellStylePullDown
                                                                       reuseIdentifier:cellIdentifier];
                cell.textLabel.lineBreakMode = UILineBreakModeWordWrap; // Example: The brown fox...dog
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.textAlignment = UITextAlignmentCenter;
            }
            
            
            cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
            if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
                cell.imageView.image = [UIImage imageNamed:@"reload.png"];
                cell.tintColor = [UIColor blackColor];
                cell.textLabel.text = @"Return to list...";
            } else if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
                cell.imageView.image = nil;
                // Setup tint color
                cell.tintColor = backgroundColor;
                cell.textLabel.text = @"Release to create cell...";
            } else {
                cell.imageView.image = nil;
                // Setup tint color
                cell.tintColor = backgroundColor;
                cell.textLabel.text = @"Continue Pulling...";
            }
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.text = @" ";
            return cell;
            
        } else {
            // Otherwise is the case we wanted to pick the unfolding style
            cellIdentifier = @"UnfoldingTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [TransformableTableViewCell transformableTableViewCellWithStyle:TransformableTableViewCellStyleUnfolding
                                                                       reuseIdentifier:cellIdentifier];
                cell.textLabel.adjustsFontSizeToFitWidth = NO;
                cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.textAlignment = UITextAlignmentCenter;
            }
            
            // Setup tint color
            cell.tintColor = backgroundColor;
            
            cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
            if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
                cell.textLabel.text = @"Release to create cell...";
            } else {
                cell.textLabel.text = @"Continue Pinching...";
            }
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.text = @" ";
            return cell;
        }
        
    } else {
        
        static NSString *cellIdentifier = @"MyCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.textLabel.text = [NSString stringWithFormat:@"%@", (NSString *)object];;
            cell.textLabel.numberOfLines = 4; //After that the textView should start to scroll
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = [NSString stringWithFormat:@"%@", (NSString *)object];
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if ([object isEqual:DONE_CELL]) {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.contentView.backgroundColor = [UIColor darkGrayColor];
        } else if ([object isEqual:DUMMY_CELL]) {
            cell.textLabel.text = @"";
            cell.contentView.backgroundColor = [UIColor clearColor];
        } else {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.contentView.backgroundColor = backgroundColor;
        }
        return cell;
    }
    
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Add to NORMAL_CELL_FINISHING_HEIGHT chunk when more then 27 characters per line are added something TOTAL_AMOUNT_OF_TEXT/27 where TOTAL_AMOUNT_OF_TEXT is an int
    NSString *text = [self.rows objectAtIndex:indexPath.row];
    //CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), CELL_MAX_CONTENT_HEIGHT);
    
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE]constrainedToSize: CGSizeMake(320-5, 4000)lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat height = MAX(size.height, NORMAL_CELL_FINISHING_HEIGHT);
    
    return (height + (CELL_CONTENT_MARGIN * 2));
    
    // if numberOfCharacters -1 < CHARACTERS_PER_LINE (numberOfCharacters -1) / CHARACTERS_PER_LINE == 0 ie. everything fits on one line thus we return the NORMAL_CELL_FINISHING_HEIGHT
    //return (numberOfCharacters -1) / CHARACTERS_PER_LINE * CELL_HEIGHT_CHUNK_PER_LINE + NORMAL_CELL_FINISHING_HEIGHT; //Bug: Returns int!
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES]; //first scroll to the top (but it doesn't work and no idea why!!?)
    if (self.taskEntry) self.taskEntry = nil; // release it? We just want one TextView
    self.taskEntry = [[UITextView alloc]initWithFrame:CGRectMake(TEXT_VIEW_OFF_SET_X, TEXT_VIEW_OFF_SET_Y, 320-TEXT_VIEW_OFF_SET_X, [self tableView:tableView heightForRowAtIndexPath:indexPath]-TEXT_VIEW_OFF_SET_Y)]; //The text offset to make it appear that the taskEntry.text position equals the cell.textLabel.text position
    //
    [[tableView cellForRowAtIndexPath:indexPath] addSubview:self.taskEntry]; //Add it only when we need it
    self.taskEntry.delegate = self; //toDO: This suffices once->move to somewhere global
    self.taskEntry.backgroundColor = [UIColor clearColor];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    self.taskEntry.textColor = [UIColor whiteColor];
    self.taskEntry.font = cell.textLabel.font;
    self.taskEntry.text = [NSString stringWithFormat:@"%@", (NSString *)[self.rows objectAtIndex:indexPath.row]];
    //NSLog(@"text: %@", self.taskEntry.text);
    cell.textLabel.text = nil;
    self.currentIndexPath = indexPath;
    self.textViewPreviousNumberOfCharacters = self.taskEntry.text.length;
    NSLog(@"self.currentIndexPath.row %d", self.currentIndexPath.row);
    [self.taskEntry becomeFirstResponder];
}

#pragma mark - TextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    //If more text then fits on a single line (remainder zero) grow cell
    CGSize size = [textView.text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE]constrainedToSize: CGSizeMake(320-5, 4000)lineBreakMode:UILineBreakModeWordWrap];
    int height = size.height;
    NSLog(@"height: %i", height);
    if (height > 18 && height % 18 == 0  && self.textViewPreviousNumberOfCharacters < textView.text.length) { //ie. we're adding text
        //Buffer the string before it gets reloaded by the tableview
        [self.rows replaceObjectAtIndex: self.currentIndexPath.row withObject: textView.text];
        self.textViewPreviousNumberOfCharacters = textView.text.length; //So that we know if the text increased instead of decreased
        [self.taskEntry removeFromSuperview]; //see below
        [self.tableView reloadRowsAtIndexPaths: [self.tableView indexPathsForVisibleRows ] withRowAnimation:UITableViewRowAnimationNone];
        [[self.tableView cellForRowAtIndexPath:self.currentIndexPath] addSubview:self.taskEntry]; //Reloading a row causes the table view to ask its data source for a new cell for that row. So we must re-add it:
        UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:self.currentIndexPath];
        selectedCell.textLabel.text = nil;
        self.taskEntry.frame = CGRectMake(0, 0, selectedCell.contentView.frame.size.width, selectedCell.contentView.frame.size.height);//Increase the size of the frame of the textView
        [self.taskEntry becomeFirstResponder];
    }
    if (textView.text.length >= 18 && textView.text.length % 18 == 0 && self.textViewPreviousNumberOfCharacters > textView.text.length) { //ie. we're removing text
        //Buffer the string before it gets reloaded by the tableview
        [self.rows replaceObjectAtIndex: self.currentIndexPath.row withObject: textView.text];
        self.textViewPreviousNumberOfCharacters = textView.text.length; //So that we know if the text decreased instead of increased
        [self.taskEntry removeFromSuperview];
        //reload the visible cells
        [self.tableView reloadRowsAtIndexPaths: [self.tableView indexPathsForVisibleRows ] withRowAnimation:UITableViewRowAnimationNone];
        //re-add the textView as a subview after the reload since this is a new cell
        [[self.tableView cellForRowAtIndexPath:self.currentIndexPath] addSubview:self.taskEntry];
        UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:self.currentIndexPath];
        selectedCell.textLabel.text = nil;
        self.taskEntry.frame = CGRectMake(0, 0, selectedCell.contentView.frame.size.width, selectedCell.contentView.frame.size.height);
        [self.taskEntry becomeFirstResponder];
    }
    
}

#pragma mark - JTTableViewGestureAddingRowDelegate

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows insertObject:ADDING_CELL atIndex:indexPath.row];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows replaceObjectAtIndex:indexPath.row withObject:@"Added!"];
    TransformableTableViewCell *cell = (id)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    
    BOOL isFirstCell = indexPath.section == 0 && indexPath.row == 0;
    if (isFirstCell && cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
        [self.rows removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
        // Return to list
    }
    else {
        cell.finishedHeight = NORMAL_CELL_FINISHING_HEIGHT;
        cell.imageView.image = nil;
        cell.textLabel.text = @"Just Added!";
    }
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows removeObjectAtIndex:indexPath.row];
}

// Uncomment to following code to disable pinch in to create cell gesture
//- (NSIndexPath *)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer willCreateCellAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.section == 0 && indexPath.row == 0) {
//        return indexPath;
//    }
//    return nil;
//}

#pragma mark JTTableViewGestureEditingRowDelegate

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(JTTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    UIColor *backgroundColor = nil;
    switch (state) {
        case JTTableViewCellEditingStateMiddle:
            backgroundColor = [UIColor tableView: self.tableView CellBackgroundColor: [UIColor tableViewCellHighestPriorityDefaultBackgroundColor] AtIndexPath: indexPath];
            break;
        case JTTableViewCellEditingStateRight:
            backgroundColor = [UIColor EditingStateBackgroundColorForDoneCell];
            break;
        default:
            backgroundColor = [UIColor DoneCellBackgroundColor];
            break;
    }
    cell.contentView.backgroundColor = backgroundColor;
    if ([cell isKindOfClass:[TransformableTableViewCell class]]) {
        ((TransformableTableViewCell *)cell).tintColor = backgroundColor;
    }
}

// This is needed to be implemented to let our delegate choose whether the panning gesture should work
- (BOOL)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(JTTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableView *tableView = gestureRecognizer.tableView;
    
    
    NSIndexPath *rowToBeMovedToBottom = nil;
    
    [tableView beginUpdates];
    if (state == JTTableViewCellEditingStateLeft) {
        // An example to discard the cell at JTTableViewCellEditingStateLeft
        [self.rows removeObjectAtIndex:indexPath.row]; //toDo future: add the object to "Today" list
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    } else if (state == JTTableViewCellEditingStateRight) {
        // An example to retain the cell at commiting at JTTableViewCellEditingStateRight
        [self.rows replaceObjectAtIndex:indexPath.row withObject:DONE_CELL];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        rowToBeMovedToBottom = indexPath;
    } else {
        // JTTableViewCellEditingStateMiddle shouldn't really happen in
        // - [JTTableViewGestureDelegate gestureRecognizer:commitEditingState:forRowAtIndexPath:]
    }
    [tableView endUpdates];
    
    
    // Row color needs update after datasource changes, reload it.
    [tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:indexPath afterDelay:JTTableViewRowAnimationDuration];
    
    if (rowToBeMovedToBottom) {
        [self performSelector:@selector(moveRowToBottomForIndexPath:) withObject:rowToBeMovedToBottom afterDelay:JTTableViewRowAnimationDuration * 2];
    }
}

#pragma mark JTTableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.grabbedObject = [self.rows objectAtIndex:indexPath.row];
    [self.rows replaceObjectAtIndex:indexPath.row withObject:DUMMY_CELL];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id object = [self.rows objectAtIndex:sourceIndexPath.row];
    [self.rows removeObjectAtIndex:sourceIndexPath.row];
    [self.rows insertObject:object atIndex:destinationIndexPath.row];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows replaceObjectAtIndex:indexPath.row withObject:self.grabbedObject];
    self.grabbedObject = nil;
}

@end
