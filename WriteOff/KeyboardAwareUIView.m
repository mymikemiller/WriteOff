#import "KeyboardAwareUIView.h"

@implementation KeyboardAwareUIView

@synthesize contentView;

- (void) initialize:(BOOL)s{
    scrolling = s;
    [super addSubview:contentView = [scrolling ? [UIScrollView alloc] : [UIView alloc] init]];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (id)initWithScrolling:(BOOL)s {
    
    self = [super init];
    if (self) {
        [self initialize:true];
    }
    return self;
}


- (id) initWithCoder:(NSCoder *)aCoder{
    if(self = [super initWithCoder:aCoder]){
        [self initialize:true];
    }
   return self;
}

- (id) initWithFrame:(CGRect)rect{
    if(self = [super initWithFrame:rect]){
        [self initialize:true];
    }    
    return self;
}


- (void)addSubview:(UIView *)view {
    
    [contentView addSubview:view];
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index {
    
    [contentView insertSubview:view atIndex:index];
}

- (void)adjustHeightForKeyboard {
    NSLog(@"Adjusting height for keyboard: %@", NSStringFromCGSize(keyboardSize));
    CGRect windowFrame = [self convertRect:self.window.bounds fromView:nil];
    CGRect keyboardIntersection = CGRectIntersection(CGRectMake(0, windowFrame.size.height - keyboardSize.height, keyboardSize.width, keyboardSize.height), self.bounds);
    CGRect newContentViewFrame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - keyboardIntersection.size.height);
    if (!CGRectEqualToRect(newContentViewFrame, contentView.frame)) contentView.frame = newContentViewFrame;
}

- (void)handleKeyboardNotification:(NSNotification*)notification {
    
    //NSTimeInterval animationDuration;
    //UIViewAnimationCurve animationCurve;
    //[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    //[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    //[UIView beginAnimations:nil context:nil];
    //[UIView setAnimationCurve:animationCurve];
    //[UIView setAnimationDuration:animationDuration];
    keyboardSize = notification.name == UIKeyboardWillHideNotification ? CGSizeZero : [self convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil].size;
    [self adjustHeightForKeyboard];
    //[UIView commitAnimations];
}

- (void)setFrame:(CGRect)frame {
    
    [super setFrame:frame];
    [self setNeedsLayout]; // TODO: I should not need this, as setNeedsLayout should be called when the size of a UIView changes!
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    [self adjustHeightForKeyboard];
    
    if (scrolling) {
        
        CGFloat height = 0, width = contentView.frame.size.width;
        for (UIView *view in contentView.subviews) {
            
            if (view.hidden || view.alpha == 0) continue;
            CGFloat bottom = view.frame.origin.y + view.frame.size.height;
            if (bottom > height) height = bottom;
        }
        ((UIScrollView *)contentView).contentSize = CGSizeMake(width, height);
    }
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end