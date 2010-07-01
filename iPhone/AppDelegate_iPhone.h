//
//  AppDelegate_iPhone.h
//  asm-neon-sample
//
//  Created by akira on 10/06/28.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TestViewController.h"

@interface AppDelegate_iPhone : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	TestViewController* testViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) TestViewController* testViewController;

@end

