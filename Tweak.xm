#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>

@interface MCUIAppSigner : NSObject
@property (nonatomic,retain) NSArray * applications;
@end

@interface MCProfileListController : UIViewController
@property (nonatomic,retain) NSArray * developerAppSigners;
@property (nonatomic,retain) NSArray * enterpriseAppSigners;
@end

@interface MCAppSignerViewController : UIViewController
@property (nonatomic,retain) MCUIAppSigner * appSigner;
@property (assign,nonatomic) BOOL isNetworkReachable;
-(id)initWithAppSigner:(id)arg1;
-(void)_trustActionGroupVerifyAppsAndTrustSigner:(BOOL)arg1;
@end

@interface _UIAlertControllerInterfaceActionGroupView : NSObject
@end

@interface UIAlertController ()
@property (readonly) NSMutableArray *_actions;
- (void)_dismissWithCancelAction;
@end

@interface SBIcon : NSObject
@property (assign,nonatomic) NSString * applicationBundleID;
@end

@interface SBIconController
+ (id)sharedInstance;
- (void)_launchIcon:(SBIcon*)arg1;
@end

void trustBundleID(NSString * bundleID)
{
	if(bundleID) {
		dlopen("/System/Library/PreferenceBundles/ManagedConfigurationUI.bundle/ManagedConfigurationUI", RTLD_LAZY);
		MCUIAppSigner* signerToAllow = nil;
		static __strong MCProfileListController* profileCont = [[%c(MCProfileListController) alloc] init];
		[profileCont loadView];
		[profileCont viewDidLoad];
		while(profileCont.developerAppSigners == nil || profileCont.enterpriseAppSigners == nil) {
			sleep(1/4);
		}
		for(MCUIAppSigner* SignerNow in profileCont.developerAppSigners) {
			for(NSString* bundleIdNow in SignerNow.applications) {
				if([bundleIdNow isEqualToString:bundleID]) {
					signerToAllow = SignerNow;
					break;
				}
			}
		}
		if(signerToAllow==nil) {
			for(MCUIAppSigner* SignerNow in profileCont.enterpriseAppSigners) {
				for(NSString* bundleIdNow in SignerNow.applications) {
					if([bundleIdNow isEqualToString:bundleID]) {
						signerToAllow = SignerNow;
						break;
					}
				}
			}
		}
		if(signerToAllow) {
			MCAppSignerViewController* AppSignerView = [[%c(MCAppSignerViewController) alloc] initWithAppSigner:signerToAllow];
			if(AppSignerView && AppSignerView.isNetworkReachable) {
				[AppSignerView _trustActionGroupVerifyAppsAndTrustSigner:YES];
			}
		}
	}
}

static SBIcon* lastClickIcon;

%hook SBIconController
- (void)_launchIcon:(SBIcon*)arg1
{
	lastClickIcon = arg1;
	%orig;
}
%end

%hook _UIAlertControllerInterfaceActionGroupView
-(id)initWithAlertController:(UIAlertController*)arg1 actionGroup:(id)arg2 actionHandlerInvocationDelegate:(id)arg3
{
	if([[arg1 _actions] count] == 1 && (arg1.title!=nil && [arg1.title isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"] localizedStringForKey:@"APP_FREE_DEVELOPER_PROFILE_NOT_TRUSTED_TITLE" value:@"" table:@"SpringBoard"]])) {
		UIAlertAction* allowButton = [UIAlertAction actionWithTitle:[[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/ManagedConfigurationUI.bundle"] localizedStringForKey:@"TRUST" value:@"Trust" table:@"ManagedConfigurationUI"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				if(!lastClickIcon) {
					return;
				}
				trustBundleID(lastClickIcon.applicationBundleID);
				dispatch_async(dispatch_get_main_queue(), ^{
					[[%c(SBIconController) sharedInstance] _launchIcon:lastClickIcon];
				});
			});
			
			[arg1 _dismissWithCancelAction];
		}];
		[arg1 addAction:allowButton];
	}
	return %orig;
}
%end


%ctor
{
	%init;
}
