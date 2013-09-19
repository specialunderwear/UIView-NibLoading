//
//  UIView+NibLoading.m
//
//  Created by Nicolas Bouilleaud.
//
// 	https://github.com/n-b/UIView-NibLoading

#import "UIView+NibLoading.h"
#import <objc/runtime.h>

@implementation UIView(NibLoading)

+ (UINib*) _nibLoadingAssociatedNibWithName:(NSString*)nibName
{
    static char kUIViewNibLoading_associatedNibsKey;

    NSDictionary * associatedNibs = objc_getAssociatedObject(self, &kUIViewNibLoading_associatedNibsKey);
    UINib * nib = associatedNibs[nibName];
    if(nil==nib)
    {
        nib = [UINib nibWithNibName:nibName bundle:nil];
        if(nib)
        {
            NSMutableDictionary * newNibs = [NSMutableDictionary dictionaryWithDictionary:associatedNibs];
            newNibs[nibName] = nib;
            objc_setAssociatedObject(self, &kUIViewNibLoading_associatedNibsKey, [NSDictionary dictionaryWithDictionary:newNibs], OBJC_ASSOCIATION_RETAIN);
        }
    }

    return nib;
}

- (void) loadContentsFromNibNamed:(NSString*)nibName
{
    // Load the nib file, setting self as the owner.
    // The root view is only a container and is discarded after loading.
    UINib * nib = [[self class] _nibLoadingAssociatedNibWithName:nibName];
    NSAssert(nib!=nil, @"UIView+NibLoading : Can't load nib named %@.",nibName);

    NSArray * views = [nib instantiateWithOwner:self options:nil];
    NSAssert(views!=nil, @"UIView+NibLoading : Can't instantiate nib named %@.",nibName);
    NSAssert(views.count==1, @"UIView+NibLoading : There must be exactly one root container view in %@.",nibName);
    UIView * containerView = [views objectAtIndex:0];
    NSAssert([[containerView class] isEqual:[UIView class]], @"UIView+NibLoading : The container view in nib %@ should be a UIView instead of %@. (It's only a container, and it's discarded after loading.)",nibName,[containerView class]);
    
    if(CGRectEqualToRect(self.bounds, CGRectZero))
        // `self` has no size : use the containerView's size, from the nib file
        self.bounds = containerView.bounds;
    else
        // `self` has a specific size : resize the containerView to this size, so that the subviews are autoresized.
        containerView.bounds = self.bounds;
    
    // reparent the subviews from the nib file
    for (UIView * view in containerView.subviews) {
        [view removeFromSuperview];
        [self addSubview:view];
    }
}

- (void) loadContentsFromNib
{
    [self loadContentsFromNibNamed:NSStringFromClass([self class])];
}

@end

#pragma mark NibLoadedView

@implementation NibLoadedView : UIView

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self loadContentsFromNib];
    return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self loadContentsFromNib];
    return self;
}

@end
