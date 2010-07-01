    //
//  TestViewController.m
//  asm-neon-sample
//
//  Created by akira on 10/06/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TestViewController.h"
#import "test.h"


@implementation TestViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated{
	textView.text = @"Push START.";
	//[self start];

}

- (void)dealloc {
    [super dealloc];
}

-(IBAction)start{
	NSString* info = NULL;
	Test* test = new Test;
	
	textView.text = @"C...\n";
	info = test->testC();
	textView.text = [NSString stringWithFormat:@"%@%@\n", textView.text, info];
	
	textView.text = [NSString stringWithFormat:@"%@ASM...\n", textView.text, info];
	info = test->testAsm();
	textView.text = [NSString stringWithFormat:@"%@%@\n", textView.text, info];
	
	textView.text = [NSString stringWithFormat:@"%@ASM-NEON...\n", textView.text, info];
	info = test->testNeon();
	textView.text = [NSString stringWithFormat:@"%@%@\n", textView.text, info];
	
	if(test){
		delete test;
	}
}

@end
