#import <UIKit/UIKit.h>

@interface KeyboardAwareUIView : UIView {
    
    UIView *contentView;
    CGSize keyboardSize;
    BOOL scrolling;
}

@property (nonatomic, readonly) UIView *contentView;

- (id)initWithScrolling:(BOOL)scrolling;

@end