//
//  ViewController.m
//  singleViewGLKitCube
//
//  Created by Jay R Wren on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>

@interface NSArray (stuff) {
}
//JRW: first or firstObjectPassingTest ?
- (id)first: (BOOL (^)(id obj))block;
- (NSArray *)where: (BOOL (^)(id obj))block;
@end
@implementation NSArray (stuff)

- (id)first: (BOOL (^)(id obj))block{
    for (id item in self) {
        if (block(item))
            return item;
    }
    return nil;
}
-(NSArray *)where:(BOOL (^)(id))block{
    NSMutableArray *array = [[NSMutableArray alloc] init ];
    for (id item in self) {
        if (block(item)) {
            [array addObject:item];
        }
    }
    return array;
}
@end

@interface Delegate : NSObject {
    void (^_callback)(id sender);
    id _sender;
}
-(void)invoke;
@end

@implementation Delegate
-(Delegate*)initWithCallback:(void(^)(id sender)) callback andSender:sender {
    if (self = [super init]) {
        _callback = callback;
        _sender = sender;
    }
    return self;
}
-(void)invoke {
    _callback(_sender);
}
@end

@interface UIButton (stuff) {
}
- (void)addTarget:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents;
@end
@implementation UIButton (stuff)

- (void)addTarget:(void (^)(id))block forControlEvents:(UIControlEvents)controlEvents {
    Delegate *del = [[Delegate alloc] initWithCallback:block andSender:self];
    [self addTarget:del action:@selector(invoke) forControlEvents:controlEvents];
}
@end
@implementation ViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
float _curRed;
BOOL _increasing;
GLKView * glkview;
BOOL on;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _increasing = YES;
    _curRed = 0.0;
    
    glkview = (GLKView*)[self.view.subviews //where subview class is GLKView
     first:^BOOL(id obj) {
         return [obj isKindOfClass:[GLKView class]];
     }];
    NSAssert(nil!= glkview, @"oh no!");
    glkview.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //DLog(@"view frame:%@",[glkview frame]);
    glkview.delegate = self;
    glkview.enableSetNeedsDisplay = NO;
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    NSArray * buttons = 
    [self.view.subviews where:^BOOL(id obj) {
        return [obj isKindOfClass:[UIButton class]];
    }];
    UIButton *go = [buttons objectAtIndex:0];
    UIButton *stop = [buttons objectAtIndex:1];
    //go addTarget:<#(id)#> action:<#(SEL)#> forControlEvents:<#(UIControlEvents)#>
    [go addTarget:^(id _){ on=YES; } forControlEvents:UIControlEventTouchUpInside];
    [stop addTarget:^(id _){ on=NO; } forControlEvents:UIControlEventTouchUpInside];
}
- (void)render:(CADisplayLink*)displayLink {

    [glkview display];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    if (!on) return;
    if (_increasing) {
        _curRed += 0.01;
    } else {
        _curRed -= 0.01;
    }
    if (_curRed >= 1.0) {
        _curRed = 1.0;
        _increasing = NO;
    }
    if (_curRed <= 0.0) {
        _curRed = 0.0;
        _increasing = YES;
    }
    
    glClearColor(_curRed, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}
@end
