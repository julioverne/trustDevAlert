#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>

#define NSLog(...)

@interface MCUIAppSigner : NSObject
@property (nonatomic,retain) NSArray * applications;

+(NSArray*)enterpriseAppSignersWithOutDeveloperAppSigners:(id*)arg1 ;
+(NSArray*)_uppProfilesBySignerIDWithOutFreeDevProfilesBySignerID:(id*)arg1 ;
@end

@interface MCUIDataManager : NSObject
+ (id)sharedManager;
@property (nonatomic,retain) NSArray * freeDeveloperAppSigners;
@property (nonatomic,retain) NSArray * enterpriseAppSigners;
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

@interface SBIconView : NSObject
@property (assign,nonatomic) SBIcon * icon;
@end

@interface SBIconController
+ (id)sharedInstance;
- (void)_launchIcon:(SBIcon*)arg1;
@end

static MCUIAppSigner* resultFromArraySigners(NSArray* DevSigners, NSString* bundleID)
{
	@try {
		for(MCUIAppSigner* SignerNow in DevSigners) {
			for(NSString* bundleIdNow in SignerNow.applications) {
				if([bundleIdNow isEqualToString:bundleID]) {
					return SignerNow;
				}
			}
		}
	}@catch (NSException * e) {
		return nil;
	}
	return nil;
}

void trustBundleID(NSString * bundleID)
{
	if(bundleID) {
		dlopen("/System/Library/PreferenceBundles/ManagedConfigurationUI.bundle/ManagedConfigurationUI", RTLD_LAZY);
		dlopen("/System/Library/PrivateFrameworks/ManagedConfigurationUI.framework/ManagedConfigurationUI", RTLD_LAZY);
		MCUIAppSigner* signerToAllow = nil;
		
		if([%c(MCProfileListController) respondsToSelector:@selector(developerAppSigners)]) {
			static __strong MCProfileListController* profileCont = [[%c(MCProfileListController) alloc] init];
			[profileCont loadView];
			[profileCont viewDidLoad];
			while(profileCont.developerAppSigners == nil || profileCont.enterpriseAppSigners == nil) {
				sleep(1/4);
			}
			signerToAllow = resultFromArraySigners(profileCont.developerAppSigners, bundleID);
			if(signerToAllow==nil) {
				if([profileCont respondsToSelector:@selector(enterpriseAppSigners)]) {
					signerToAllow = resultFromArraySigners(profileCont.enterpriseAppSigners, bundleID);
				}
			}
		}
		if(signerToAllow==nil) {
			if([%c(MCUIAppSigner) respondsToSelector:@selector(enterpriseAppSignersWithOutDeveloperAppSigners:)]) {
				signerToAllow = resultFromArraySigners([%c(MCUIAppSigner) enterpriseAppSignersWithOutDeveloperAppSigners:nil], bundleID);
			}
		}
		if(signerToAllow==nil) {
			if([%c(MCUIDataManager) respondsToSelector:@selector(sharedManager)]) {
				MCUIDataManager* shrd = [%c(MCUIDataManager) sharedManager];
				sleep(1);
				if([shrd respondsToSelector:@selector(freeDeveloperAppSigners)]) {
					signerToAllow = resultFromArraySigners([shrd freeDeveloperAppSigners], bundleID);
				}
				if(signerToAllow==nil) {
					if([shrd respondsToSelector:@selector(enterpriseAppSigners)]) {
						signerToAllow = resultFromArraySigners([shrd enterpriseAppSigners], bundleID);
					}
				}
			}
		}
		@try {
			if(signerToAllow) {
				MCAppSignerViewController* AppSignerView = [[%c(MCAppSignerViewController) alloc] initWithAppSigner:signerToAllow];
				if(AppSignerView && AppSignerView.isNetworkReachable) {
					[AppSignerView _trustActionGroupVerifyAppsAndTrustSigner:YES];
				}
			}
		}@catch(NSException* e) {
		}
	}
}

static SBIcon* lastClickIcon;
static SEL lastClickIconSEL;

%hook SBIconController
- (void)_launchIcon:(SBIcon*)arg1
{
	lastClickIcon = arg1;
	lastClickIconSEL = @selector(_launchIcon:);
	%orig;
}

-(void)_launchFromIconView:(id)arg1
{
	lastClickIcon = arg1;
	lastClickIconSEL = @selector(_launchFromIconView:);
	%orig;
}
-(void)iconTapped:(id)arg1
{
	lastClickIcon = arg1;
	lastClickIconSEL = @selector(iconTapped:);
	%orig;
}
%end

%hook UIViewController
- (void)presentViewController:(UIAlertController*)arg1 animated:(BOOL)arg2 completion:(id)arg3
{
	if(arg1&&[arg1 isKindOfClass:[UIAlertController class]]) {
		if([[arg1 _actions] count] == 1 && (arg1.title!=nil && ([arg1.title isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"] localizedStringForKey:@"APP_FREE_DEVELOPER_PROFILE_NOT_TRUSTED_TITLE" value:@"" table:@"SpringBoard"]]||[arg1.title isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"] localizedStringForKey:@"APP_PROFILE_NOT_TRUSTED_TITLE" value:@"" table:@"SpringBoard"]]))) {
			UIAlertAction* allowButton = [UIAlertAction actionWithTitle:[[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/ManagedConfigurationUI.bundle"] localizedStringForKey:@"TRUST" value:([NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/ManagedConfigurationUI.framework"]!=nil)?[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/ManagedConfigurationUI.framework"] localizedStringForKey:@"TRUST" value:@"Trust" table:@"ManagedConfigurationUI"]:@"Trust" table:@"ManagedConfigurationUI"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					NSLog(@"**** [trustDev] _launchIcon: %@", lastClickIcon);
					if(!lastClickIcon) {
						return;
					}
					trustBundleID([lastClickIcon isKindOfClass:%c(SBIconView)]?[(SBIconView *)lastClickIcon icon].applicationBundleID:lastClickIcon.applicationBundleID);
					dispatch_async(dispatch_get_main_queue(), ^{
						[[%c(SBIconController) sharedInstance] performSelector:lastClickIconSEL withObject:lastClickIcon];
					});
				});
				[arg1 _dismissWithCancelAction];
			}];
			[arg1 addAction:allowButton];
		}
	}
	%orig;
}
%end


%ctor
{
	%init;
}
