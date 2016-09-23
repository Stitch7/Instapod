//
//  _LNPopupBarSupportObject.m
//  LNPopupController
//
//  Created by Leo Natan on 7/24/15.
//  Copyright © 2015 Leo Natan. All rights reserved.
//

#import "LNPopupController.h"
#import "LNPopupItem+Private.h"
@import ObjectiveC;

static const CFTimeInterval LNPopupBarGestureHeightPercentThreshold = 0.2;
static const CGFloat		LNPopupBarDeveloperPanGestureThreshold = 100;

@interface _LNPopupTransitionCoordinator : NSObject <UIViewControllerTransitionCoordinator> @end
@implementation _LNPopupTransitionCoordinator

- (BOOL)isInterruptible
{
	return NO;
}

- (BOOL)isAnimated
{
	return NO;
}

- (UIModalPresentationStyle)presentationStyle
{
	return UIModalPresentationNone;
}

- (BOOL)initiallyInteractive
{
	return NO;
}

- (BOOL)isInteractive
{
	return NO;
}

- (BOOL)isCancelled
{
	return NO;
}

- (NSTimeInterval)transitionDuration
{
	return 0.0;
}

- (CGFloat)percentComplete;
{
	return 1.0;
}

- (CGFloat)completionVelocity
{
	return 1.0;
}

- (UIViewAnimationCurve)completionCurve
{
	return UIViewAnimationCurveEaseInOut;
}

- (nullable __kindof UIViewController *)viewControllerForKey:(NSString *)key
{
	if([key isEqualToString:UITransitionContextFromViewControllerKey])
	{
		
	}
	else if([key isEqualToString:UITransitionContextToViewControllerKey])
	{
		
	}
	
	return nil;
}

- (nullable __kindof UIView *)viewForKey:(NSString *)key
{
	return nil;
}

- (UIView *)containerView
{
	return nil;
}

- (CGAffineTransform)targetTransform
{
	return CGAffineTransformIdentity;
}

- (BOOL)animateAlongsideTransition:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))animation
						completion:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))completion
{
	if(animation)
	{
		animation(self);
	}
	
	if(completion)
	{
		completion(self);
	}
	
	return YES;
}

- (BOOL)animateAlongsideTransitionInView:(nullable UIView *)view
							   animation:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))animation
							  completion:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))completion
{
	return [self animateAlongsideTransition:animation completion:completion];
}

- (void)notifyWhenInteractionEndsUsingBlock: (void (^)(id <UIViewControllerTransitionCoordinatorContext>context))handler
{ }

@end

@interface LNPopupContentView ()

- (instancetype)initWithFrame:(CGRect)frame popupBarStyle:(UIBarStyle)popupBarStyle;

@property (nonatomic, strong, readwrite) UIPanGestureRecognizer* popupInteractionGestureRecognizer;
@property (nonatomic, strong, readwrite) LNPopupCloseButton* popupCloseButton;

@end

@implementation LNPopupContentView

- (nonnull instancetype)initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame popupBarStyle:UIBarStyleDefault];
}

- (nonnull instancetype)initWithFrame:(CGRect)frame popupBarStyle:(UIBarStyle)popupBarStyle
{
	self = [super initWithEffect:nil];
	if(self) { self.frame = frame; }
	return self;
}

@end

@interface LNPopupController () <_LNPopupItemDelegate, UIGestureRecognizerDelegate, UIViewControllerPreviewingDelegate> @end

@implementation LNPopupController
{
	__weak __kindof UIViewController* _containerController;
	__weak LNPopupItem* _currentPopupItem;
	__weak __kindof UIViewController* _currentContentController;
	
	BOOL _dismissGestureStarted;
	CGFloat _dismissStartingOffset;
	CGFloat _dismissScrollViewStartingContentOffset;
	LNPopupPresentationState _stateBeforeDismissStarted;
	
	BOOL _dismissalOverride;
	
	//Cached for performance during panning the popup content
	CGRect _cachedDefaultFrame;
	CGRect _cachedOpenPopupFrame;
	
	CGFloat _tresholdToPassForStatusBarUpdate;
	CGFloat _statusBarTresholdDir;
	
	CGFloat _bottomBarOffset;
}

- (instancetype)initWithContainerViewController:(__kindof UIViewController*)containerController
{
	self = [super init];
	
	if(self)
	{
		_containerController = containerController;
		
		_popupControllerState = LNPopupPresentationStateHidden;
		_popupControllerTargetState = LNPopupPresentationStateHidden;
	}
	
	return self;
}

- (CGRect)_frameForOpenPopupBar
{
	CGRect defaultFrame = [_containerController defaultFrameForBottomDockingView_internalOrDeveloper];
	return CGRectMake(defaultFrame.origin.x, - _popupBar.frame.size.height, _containerController.view.bounds.size.width, _popupBar.frame.size.height);
}

- (CGRect)_frameForClosedPopupBar
{
	CGRect defaultFrame = [_containerController defaultFrameForBottomDockingView_internalOrDeveloper];
	return CGRectMake(defaultFrame.origin.x, defaultFrame.origin.y - _popupBar.frame.size.height, _containerController.view.bounds.size.width, _popupBar.frame.size.height);
}

- (void)_repositionPopupContent
{
	UIView* relativeViewForContentView = _bottomBar;
	
	CGFloat percent = [self _percentFromPopupBarForBottomBarDisplacement];
	CGRect bottomBarFrame = _cachedDefaultFrame;
	bottomBarFrame.origin.y += (percent * bottomBarFrame.size.height);
	_bottomBar.frame = bottomBarFrame;
	
	[_popupBar.toolbar setAlpha:1.0 - percent];
	[_popupBar.progressView setAlpha:1.0 - percent];
	
	CGRect contentFrame = _containerController.view.bounds;
	contentFrame.origin.x = _popupBar.frame.origin.x;
	contentFrame.origin.y = _popupBar.frame.origin.y + _popupBar.frame.size.height;

	// This rounds the height to the nearest fractional pixel size supported by the main screen of the
	// current device. It fixes an issue where the view doesn't quite touch all the way to the bottom bar
	CGFloat screenScale = _containerController.view.window.screen.scale;
	CGFloat fractionalHeight = relativeViewForContentView.frame.origin.y - (_popupBar.frame.origin.y + _popupBar.frame.size.height);
	contentFrame.size.height = ceil(fractionalHeight * screenScale) / screenScale;
	
	self.popupContentView.frame = contentFrame;
	_containerController.popupContentViewController.view.frame = _containerController.view.bounds;
	
	[self.popupContentView.popupCloseButton sizeToFit];
	CGRect popupCloseButtonFrame = self.popupContentView.popupCloseButton.frame;
	popupCloseButtonFrame.origin.x = 12;
	popupCloseButtonFrame.origin.y = 12 + ([UIApplication sharedApplication].isStatusBarHidden ? 0 : [UIApplication sharedApplication].statusBarFrame.size.height);
	if([_currentContentController isKindOfClass:[UINavigationController class]] && [(UINavigationController*)_currentContentController isNavigationBarHidden] == NO)
	{
		popupCloseButtonFrame.origin.y += CGRectGetHeight([(UINavigationController*)_currentContentController navigationBar].bounds);
	}
	
	if(!CGRectEqualToRect(self.popupContentView.popupCloseButton.frame, popupCloseButtonFrame))
	{
		[UIView animateWithDuration:0.2 animations:^{
			self.popupContentView.popupCloseButton.frame = popupCloseButtonFrame;
		}];
	}
}

static CGFloat __saturate(CGFloat x)
{
	return MAX(0, MIN(1, x));
}

static CGFloat __smoothstep(CGFloat a, CGFloat b, CGFloat x)
{
	float t = __saturate((x - a)/(b - a));
	return t * t * (3.0 - (2.0 * t));
}

- (CGFloat)_percentFromPopupBar
{
	return 1 - (_popupBar.center.y / _cachedDefaultFrame.origin.y);
}

- (CGFloat)_percentFromPopupBarForBottomBarDisplacement
{
	CGFloat percent = [self _percentFromPopupBar];
	
	return __smoothstep(0.05, 1.0, percent);
}

- (void)_setContentToState:(LNPopupPresentationState)state
{
	CGRect targetFrame = _popupBar.frame;
	if(state == LNPopupPresentationStateOpen)
	{
		targetFrame = [self _frameForOpenPopupBar];
	}
	else if(state == LNPopupPresentationStateClosed || (state == LNPopupPresentationStateTransitioning && _popupControllerTargetState == LNPopupPresentationStateHidden))
	{
		targetFrame = [self _frameForClosedPopupBar];
	}
	
	_cachedDefaultFrame = [_containerController defaultFrameForBottomDockingView_internalOrDeveloper];
	
	_popupBar.frame = targetFrame;
	
	if(state != LNPopupPresentationStateTransitioning)
	{
		[_containerController setNeedsStatusBarAppearanceUpdate];
	}
	
	[self _repositionPopupContent];
}

- (void)_transitionToState:(LNPopupPresentationState)state animated:(BOOL)animated completion:(void(^)())completion transitionOriginatedByUser:(BOOL)transitionOriginatedByUser
{
	if(transitionOriginatedByUser == YES && _popupControllerState == LNPopupPresentationStateTransitioning)
	{
		NSLog(@"The popup controller is already in transition. Will ignore this transition request.");
		return;
	}
	
	if(state == _popupControllerState)
	{
		return;
	}
	
	UIViewController* contentController = _containerController.popupContentViewController;
	
	if(_popupControllerState == LNPopupPresentationStateClosed)
	{
		[contentController beginAppearanceTransition:YES animated:NO];
		[UIView performWithoutAnimation:^{
			contentController.view.frame = _containerController.view.bounds;
			contentController.view.clipsToBounds = NO;
			contentController.view.autoresizingMask = UIViewAutoresizingNone;
			
			if(CGColorGetAlpha(contentController.view.backgroundColor.CGColor) < 1.0)
			{
				//Support for iOS8, where this property was exposed as readonly.
				[self.popupContentView setValue:[UIBlurEffect effectWithStyle:_popupBar.barStyle == UIBarStyleDefault ? UIBlurEffectStyleExtraLight : UIBlurEffectStyleDark] forKey:@"effect"];
				self.popupContentView.popupCloseButton.layer.shadowOpacity = 0.2;
			}
			else
			{
				[self.popupContentView setValue:nil forKey:@"effect"];
				self.popupContentView.popupCloseButton.layer.shadowOpacity = 0.1;
			}
			
			[self.popupContentView.contentView addSubview:contentController.view];
			[self.popupContentView.contentView sendSubviewToBack:contentController.view];
			
			[self.popupContentView.contentView setNeedsLayout];
			[self.popupContentView.contentView layoutIfNeeded];
		}];
		[contentController endAppearanceTransition];
	};;
	
	_popupControllerState = LNPopupPresentationStateTransitioning;
	_popupControllerTargetState = state;
	
	[UIView animateWithDuration:animated ? 0.5 : 0.0 delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0 options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionAllowAnimatedContent animations:^
	 {
		 if(state == LNPopupPresentationStateClosed)
		 {
			 [contentController beginAppearanceTransition:NO animated:YES];
		 }
		 
		 [self _setContentToState:state];
	 } completion:^(BOOL finished)
	 {
		 if(state == LNPopupPresentationStateClosed)
		 {
			 [contentController.view removeFromSuperview];
			 [contentController endAppearanceTransition];
			 
			 [self _cleanupGestureRecognizersForController:contentController];
			 
			 [contentController.viewForPopupInteractionGestureRecognizer removeGestureRecognizer:self.popupContentView.popupInteractionGestureRecognizer];
			 [_popupBar addGestureRecognizer:self.popupContentView.popupInteractionGestureRecognizer];
			 
			 [_popupBar _setTitleViewMarqueesPaused:NO];
			 
			 _popupContentView.accessibilityViewIsModal = NO;
			 UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
		 }
		 else if(state == LNPopupPresentationStateOpen)
		 {
			 [_popupBar _setTitleViewMarqueesPaused:YES];
			 
			 [_popupBar removeGestureRecognizer:self.popupContentView.popupInteractionGestureRecognizer];
			 [contentController.viewForPopupInteractionGestureRecognizer addGestureRecognizer:self.popupContentView.popupInteractionGestureRecognizer];
			 [self _fixupGestureRecognizersForController:contentController];
			 
			 _popupContentView.accessibilityViewIsModal = YES;
			 UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, _popupContentView.popupCloseButton);
		 }
		 
		 _popupControllerState = state;
		 
		 if(completion)
		 {
			 completion();
		 }
	 }];
}

- (void)_popupBarLongPressGestureRecognized:(UILongPressGestureRecognizer*)lpgr
{
	switch (lpgr.state) {
		case UIGestureRecognizerStateBegan:
			[_popupBar setHighlighted:YES];
			break;
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded:
			[_popupBar setHighlighted:NO];
			break;
		default:
			break;
	}
}

- (void)_popupBarTapGestureRecognized:(UITapGestureRecognizer*)tgr
{
	switch (tgr.state) {
		case UIGestureRecognizerStateEnded:
		{
			[self _transitionToState:LNPopupPresentationStateTransitioning animated:NO completion:^{
				[_containerController.view setNeedsLayout];
				[_containerController.view layoutIfNeeded];
				[self _transitionToState:LNPopupPresentationStateOpen animated:YES completion:nil transitionOriginatedByUser:NO];
			} transitionOriginatedByUser:NO];
		}	break;
		default:
			break;
	}
}

- (void)_popupBarPresentationByUserPanGestureHandler:(UIPanGestureRecognizer*)pgr
{
	if(_dismissalOverride)
	{
		return;
	}
	
	switch (pgr.state) {
		case UIGestureRecognizerStateChanged:
		{
			if(pgr != _popupContentView.popupInteractionGestureRecognizer)
			{
				UIScrollView* possibleScrollView = (id)pgr.view;
				if([possibleScrollView isKindOfClass:[UIScrollView class]])
				{
					if(_dismissGestureStarted == NO && possibleScrollView.contentOffset.y > - (possibleScrollView.contentInset.top + LNPopupBarDeveloperPanGestureThreshold))
					{
						return;
					}
					
					if(_dismissGestureStarted == NO)
					{
						_dismissScrollViewStartingContentOffset = possibleScrollView.contentOffset.y;
					}
					
					if(possibleScrollView.contentOffset.y < - (possibleScrollView.contentInset.top + LNPopupBarDeveloperPanGestureThreshold))
					{
						possibleScrollView.contentOffset = CGPointMake(possibleScrollView.contentOffset.x, _dismissScrollViewStartingContentOffset);
					}
				}
			}
			
			if(_dismissGestureStarted == NO)
			{
				_lastSeenMovement = CACurrentMediaTime();
				_popupBarLongPressGestureRecognizer.enabled = NO;
				_popupBarLongPressGestureRecognizer.enabled = YES;
				_lastPopupBarLocation = _popupBar.center;
				
				_statusBarTresholdDir = _popupControllerState == LNPopupPresentationStateOpen ? 1 : -1;
				_tresholdToPassForStatusBarUpdate = -10;
				
				_stateBeforeDismissStarted = _popupControllerState;
				
				[self _transitionToState:LNPopupPresentationStateTransitioning animated:YES completion:nil transitionOriginatedByUser:NO];
				
				_cachedDefaultFrame = [_containerController defaultFrameForBottomDockingView_internalOrDeveloper];
				_cachedOpenPopupFrame = [self _frameForOpenPopupBar];
				
				_dismissGestureStarted = YES;
				
				if(pgr != _popupContentView.popupInteractionGestureRecognizer)
				{
					_dismissStartingOffset = [pgr translationInView:_popupBar.superview].y;
				}
				else
				{
					_dismissStartingOffset = 0;
				}
			}
			
			if(_dismissGestureStarted == YES)
			{
				CGFloat targetCenterY = MIN(_lastPopupBarLocation.y + [pgr translationInView:_popupBar.superview].y, _cachedDefaultFrame.origin.y - _popupBar.frame.size.height / 2) - _dismissStartingOffset;
				targetCenterY = MAX(targetCenterY, _cachedOpenPopupFrame.origin.y + _popupBar.frame.size.height / 2);
				
				CGFloat currentCenterY = _popupBar.center.y;
				
				_popupBar.center = CGPointMake(_popupBar.center.x, targetCenterY);
				[self _repositionPopupContent];
				_lastSeenMovement = CACurrentMediaTime();
				
				if((_statusBarTresholdDir == 1 && currentCenterY < targetCenterY && targetCenterY >= _tresholdToPassForStatusBarUpdate)
				   || (_statusBarTresholdDir == -1 && currentCenterY > targetCenterY && targetCenterY < _tresholdToPassForStatusBarUpdate))
				{
					_statusBarTresholdDir = -_statusBarTresholdDir;
					
					[_containerController setNeedsStatusBarAppearanceUpdate];
				}
			}
		}	break;
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded:
		{
			if(_dismissGestureStarted == YES)
			{
				LNPopupPresentationState targetState = _stateBeforeDismissStarted;
				
				CGFloat barTransitionPercent = [self _percentFromPopupBar];
				BOOL hasPassedHeighThreshold = _stateBeforeDismissStarted == LNPopupPresentationStateClosed ? barTransitionPercent > LNPopupBarGestureHeightPercentThreshold : barTransitionPercent < (1.0 - LNPopupBarGestureHeightPercentThreshold);
				BOOL isPanUp = [pgr velocityInView:_containerController.view].y < 0;
				BOOL isPanDown = [pgr velocityInView:_containerController.view].y > 0;
				

				if(isPanUp)
				{
					targetState = LNPopupPresentationStateOpen;
				}
				else if(isPanDown)
				{
					targetState = LNPopupPresentationStateClosed;
				}
				else if(hasPassedHeighThreshold)
				{
					targetState = _stateBeforeDismissStarted == LNPopupPresentationStateClosed ? LNPopupPresentationStateOpen : LNPopupPresentationStateClosed;
				}
				
				[self _transitionToState:targetState animated:YES completion:nil transitionOriginatedByUser:NO];
			}
			
			_dismissGestureStarted = NO;
		}	break;
		default:
			break;
	}
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
	return UIBarPositionAny;
}

- (void)_closePopupContent
{
	[self closePopupAnimated:YES completion:nil];
}

- (void)_reconfigure_title
{
	_popupBar.title = _currentPopupItem.title;
}

- (void)_reconfigure_subtitle
{
	_popupBar.subtitle = _currentPopupItem.subtitle;
}

- (void)_reconfigure_progress
{
	[UIView performWithoutAnimation:^{
		[_popupBar.progressView setProgress:_currentPopupItem.progress animated:NO];
	}];
}

- (void)_reconfigure_accessibilityLavel
{
	_popupBar.accessibilityCenterLabel = _currentPopupItem.accessibilityLabel;
}

- (void)_reconfigure_accessibilityHint
{
	_popupBar.accessibilityCenterHint = _currentPopupItem.accessibilityHint;
}

- (void)_reconfigure_accessibilityProgressLabel
{
	_popupBar.accessibilityProgressLabel = _currentPopupItem.accessibilityProgressLabel;
}

- (void)_reconfigure_accessibilityProgressValue
{
	_popupBar.accessibilityProgressValue = _currentPopupItem.accessibilityProgressValue;
}

- (void)_reconfigureBarItems
{
	[_popupBar _delayBarButtonLayout];
	[_popupBar setLeftBarButtonItems:_currentPopupItem.leftBarButtonItems];
	[_popupBar setRightBarButtonItems:_currentPopupItem.rightBarButtonItems];
	[_popupBar _layoutBarButtonItems];
}

- (void)_reconfigure_leftBarButtonItems
{
	[self _reconfigureBarItems];
}

- (void)_reconfigure_rightBarButtonItems
{
	[self _reconfigureBarItems];
}

- (void)_popupItem:(LNPopupItem*)popupItem didChangeValueForKey:(NSString*)key
{
	NSString* reconfigureSelector = [NSString stringWithFormat:@"_reconfigure_%@", key];
	
	void (*configureDispatcher)(id, SEL) = (void(*)(id, SEL))objc_msgSend;
	configureDispatcher(self, NSSelectorFromString(reconfigureSelector));
}

- (void)_reconfigureContent
{
	_currentPopupItem.itemDelegate = nil;
	_currentPopupItem = _containerController.popupContentViewController.popupItem;
	_currentPopupItem.itemDelegate = self;
	
	_popupBar.popupItem = _currentPopupItem;
	
	if(_currentContentController)
	{
		__kindof UIViewController* oldContentController = _currentContentController;
		__kindof UIViewController* newContentController = _containerController.popupContentViewController;
		
		CGRect oldContentViewFrame = _currentContentController.view.frame;
		
		[newContentController beginAppearanceTransition:YES animated:NO];
		_LNPopupTransitionCoordinator* coordinator = [_LNPopupTransitionCoordinator new];
		[newContentController willTransitionToTraitCollection:_containerController.traitCollection withTransitionCoordinator:coordinator];
		[newContentController viewWillTransitionToSize:_containerController.view.bounds.size withTransitionCoordinator:coordinator];
		newContentController.view.frame = oldContentViewFrame;
		newContentController.view.clipsToBounds = NO;
		[self.popupContentView.contentView insertSubview:newContentController.view belowSubview:_currentContentController.view];
		[newContentController endAppearanceTransition];
		
		[_currentContentController beginAppearanceTransition:NO animated:NO];
		[_currentContentController.view removeFromSuperview];
		[_currentContentController endAppearanceTransition];
		
		_currentContentController = newContentController;
		
		if(_popupControllerState == LNPopupPresentationStateOpen)
		{
			UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
			
			[self _cleanupGestureRecognizersForController:oldContentController];
			[self _fixupGestureRecognizersForController:_currentContentController];
		}
	}
	
	NSArray<NSString*>* keys = @[@"title", @"subtitle", @"progress", @"leftBarButtonItems", @"accessibilityLavel", @"accessibilityHint", @"accessibilityProgressLabel", @"accessibilityProgressValue"];
	[keys enumerateObjectsUsingBlock:^(NSString * __nonnull key, NSUInteger idx, BOOL * __nonnull stop) {
		[self _popupItem:_currentPopupItem didChangeValueForKey:key];
	}];
}

- (void)_configurePopupBarFromBottomBar
{
	if([_bottomBar respondsToSelector:@selector(barStyle)])
	{
		[_popupBar setSystemBarStyle:[(id<_LNPopupBarSupport>)_bottomBar barStyle]];
	}
	_popupBar.systemTintColor = _bottomBar.tintColor;
	if([_bottomBar respondsToSelector:@selector(barTintColor)])
	{
		[_popupBar setSystemBarTintColor:[(id<_LNPopupBarSupport>)_bottomBar barTintColor]];
	}
	_popupBar.systemBackgroundColor = _bottomBar.backgroundColor;
}

- (void)_movePopupBarAndContentToBottomBarSuperview
{
	//	NSAssert(_bottomBar.superview != nil, @"Bottom docking view must have a superview before presenting popup.");
	[_popupBar removeFromSuperview];
	[_bottomBar.superview insertSubview:_popupBar belowSubview:_bottomBar];
	[_popupBar.superview bringSubviewToFront:_popupBar];
	[_popupBar.superview bringSubviewToFront:_bottomBar];
	[_popupBar.superview insertSubview:self.popupContentView belowSubview:_popupBar];
}

- (LNPopupContentView *)popupContentView
{
	if(_popupContentView)
	{
		return _popupContentView;
	}
	
	self.popupContentView = [[LNPopupContentView alloc] initWithFrame:_containerController.view.bounds popupBarStyle:_popupBar.barStyle];
	_popupContentView.layer.masksToBounds = YES;
	
	_popupContentView.preservesSuperviewLayoutMargins = YES;
	_popupContentView.contentView.preservesSuperviewLayoutMargins = YES;
	
	_popupContentView.popupCloseButton = [[LNPopupCloseButton alloc] initWithFrame: CGRectMake(0, 0, 0, 0)];
	[_popupContentView.popupCloseButton addTarget:self action:@selector(_closePopupContent) forControlEvents:UIControlEventTouchUpInside];
	[_popupContentView.contentView addSubview:self.popupContentView.popupCloseButton];
	
	self.popupContentView.popupInteractionGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_popupBarPresentationByUserPanGestureHandler:)];
	self.popupContentView.popupInteractionGestureRecognizer.delegate = self;
	
	return _popupContentView;
}

- (void)_fixupGestureRecognizersForController:(UIViewController*)vc
{
	[vc.view.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:[UIPanGestureRecognizer class]] && obj != _popupContentView.popupInteractionGestureRecognizer)
		{
			[obj addTarget:self action:@selector(_popupBarPresentationByUserPanGestureHandler:)];
		}
	}];
}

- (void)_cleanupGestureRecognizersForController:(UIViewController*)vc
{
	[vc.view.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:[UIPanGestureRecognizer class]] && obj != _popupContentView.popupInteractionGestureRecognizer)
		{
			[obj removeTarget:self action:@selector(_popupBarPresentationByUserPanGestureHandler:)];
		}
	}];
}

- (void)presentPopupBarAnimated:(BOOL)animated openPopup:(BOOL)open completion:(void(^)())completionBlock
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	
	_LNPopupTransitionCoordinator* coordinator = [_LNPopupTransitionCoordinator new];
	[_containerController.popupContentViewController willTransitionToTraitCollection:_containerController.traitCollection withTransitionCoordinator:coordinator];
	[_containerController.popupContentViewController viewWillTransitionToSize:_containerController.view.bounds.size withTransitionCoordinator:coordinator];
	
	if(_popupControllerTargetState == LNPopupPresentationStateHidden)
	{
		_dismissalOverride = NO;
		
		if(open)
		{
			_popupControllerState = LNPopupPresentationStateClosed;
		}
		else
		{
			_popupControllerState = LNPopupPresentationStateTransitioning;
		}
		_popupControllerTargetState = LNPopupPresentationStateClosed;
		
		_bottomBar = _containerController.bottomDockingViewForPopup_internalOrDeveloper;
		
		_popupBar = [[LNPopupBar alloc] initWithFrame:CGRectZero];
		_popupBar.hidden = NO;
		
		if([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 9)
		{
			[_containerController registerForPreviewingWithDelegate:self sourceView:_popupBar];
		}
		
		[self _movePopupBarAndContentToBottomBarSuperview];
		[self _configurePopupBarFromBottomBar];
		
		_popupBarLongPressGestureRecognizerDelegate = [LNPopupControllerLongPressGestureDelegate new];
		_popupBarLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_popupBarLongPressGestureRecognized:)];
		_popupBarLongPressGestureRecognizer.minimumPressDuration = 0;
		_popupBarLongPressGestureRecognizer.cancelsTouchesInView = NO;
		_popupBarLongPressGestureRecognizer.delaysTouchesBegan = NO;
		_popupBarLongPressGestureRecognizer.delaysTouchesEnded = NO;
		_popupBarLongPressGestureRecognizer.delegate = _popupBarLongPressGestureRecognizerDelegate;
		[_popupBar addGestureRecognizer:_popupBarLongPressGestureRecognizer];
		
		_popupBarTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_popupBarTapGestureRecognized:)];
		[_popupBar addGestureRecognizer:_popupBarTapGestureRecognizer];
		
		[_popupBar addGestureRecognizer:self.popupContentView.popupInteractionGestureRecognizer];
		
		[self _setContentToState:LNPopupPresentationStateClosed];
		[_containerController.view layoutIfNeeded];
		
		[self _reconfigureContent];
		
		[UIView animateWithDuration:animated ? 0.5 : 0.0 delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^
		 {
			 CGRect barFrame = _popupBar.frame;
			 barFrame.size.height = LNPopupBarHeight;
			 _popupBar.frame = barFrame;
			 _popupBar.frame = [self _frameForClosedPopupBar];
			 
			 _LNPopupSupportFixInsetsForViewController(_containerController, YES);
			 
			 if(open)
			 {
				 [self openPopupAnimated:animated completion:completionBlock];
			 }
		 } completion:^(BOOL finished)
		 {
			 _popupControllerState = LNPopupPresentationStateClosed;
			 
			 if(completionBlock != nil && !open)
			 {
				 completionBlock();
			 }
		 }];
	}
	else
	{
		[self _reconfigureContent];
		
		if(open)
		{
			[self openPopupAnimated:animated completion:completionBlock];
		}
		else if(completionBlock != nil)
		{
			completionBlock();
		}
	}
	
	_currentContentController = _containerController.popupContentViewController;
}

- (void)openPopupAnimated:(BOOL)animated completion:(void(^)())completionBlock
{
	[self _transitionToState:LNPopupPresentationStateTransitioning animated:NO completion:^{
		[_containerController.view setNeedsLayout];
		[_containerController.view layoutIfNeeded];
		[self _transitionToState:LNPopupPresentationStateOpen animated:animated completion:completionBlock transitionOriginatedByUser:NO];
	} transitionOriginatedByUser:YES];
}

- (void)closePopupAnimated:(BOOL)animated completion:(void(^)())completionBlock
{
	[self _transitionToState:LNPopupPresentationStateClosed animated:animated completion:completionBlock transitionOriginatedByUser:YES];
}

- (void)dismissPopupBarAnimated:(BOOL)animated completion:(void(^)())completionBlock
{
	if(_popupControllerState != LNPopupPresentationStateHidden)
	{
		void (^dismissalAnimationCompletionBlock)() = ^
		{
			_popupControllerState = LNPopupPresentationStateTransitioning;
			_popupControllerTargetState = LNPopupPresentationStateHidden;
			
			[UIView animateWithDuration:animated ? 0.5 : 0.0 delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^
			 {
				 CGRect barFrame = _popupBar.frame;
				 barFrame.size.height = 0;
				 _popupBar.frame = barFrame;
				 
				 _LNPopupSupportFixInsetsForViewController(_containerController, YES);
			 } completion:^(BOOL finished)
			 {
				 _popupControllerState = LNPopupPresentationStateHidden;
				 
				 _bottomBar.frame = [_containerController defaultFrameForBottomDockingView_internalOrDeveloper];
				 _bottomBar = nil;
				 
				 [_popupBar removeFromSuperview];
				 _popupBar = nil;
				 
				 [self.popupContentView removeFromSuperview];
				 self.popupContentView = nil;
				 
				 _popupBarLongPressGestureRecognizerDelegate = nil;
				 _popupBarLongPressGestureRecognizer = nil;
				 _popupBarTapGestureRecognizer = nil;
				 self.popupContentView.popupInteractionGestureRecognizer = nil;
				 
				 _LNPopupSupportFixInsetsForViewController(_containerController, YES);
				 
				 [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
				 [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
				 
				 _currentContentController = nil;
				 
				 _effectiveStatusBarUpdateController = nil;
				 
				 if(completionBlock != nil)
				 {
					 completionBlock();
				 }
			 }];
		};
		
		if(_popupControllerTargetState != LNPopupPresentationStateClosed)
		{
			_popupBar.hidden = YES;
			_dismissalOverride = YES;
			self.popupContentView.popupInteractionGestureRecognizer.enabled = NO;
			self.popupContentView.popupInteractionGestureRecognizer.enabled = YES;
			[self _transitionToState:LNPopupPresentationStateClosed animated:animated completion:dismissalAnimationCompletionBlock transitionOriginatedByUser:NO];
		}
		else
		{
			dismissalAnimationCompletionBlock();
		}
	}
}

#pragma mark Application Events

- (void)_applicationDidEnterBackground
{
	[_popupBar _setTitleViewMarqueesPaused:YES];
}

- (void)_applicationWillEnterForeground
{
	[_popupBar _setTitleViewMarqueesPaused:NO];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	if([NSStringFromClass(otherGestureRecognizer.class) containsString:@"Reveal"])
	{
		return NO;
	}
	
	if(_popupControllerState != LNPopupPresentationStateOpen)
	{
		return YES;
	}
	
	return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	if(_popupControllerState != LNPopupPresentationStateOpen)
	{
		return NO;
	}
	
	return YES;
}

#pragma mark UIViewControllerPreviewingDelegate

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
	return [_containerController.popupBarPreviewingDelegate previewingViewControllerForPopupBar:_containerController.popupBar];
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
	if([_containerController.popupBarPreviewingDelegate respondsToSelector:@selector(popupBar:commitPreviewingViewController:)])
	{
		[_containerController.popupBarPreviewingDelegate popupBar:_containerController.popupBar commitPreviewingViewController:viewControllerToCommit];
	}
}

@end
