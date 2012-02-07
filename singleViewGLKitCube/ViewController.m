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
#import <objc/runtime.h>

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



@implementation FWrapper

-(FWrapper*)initWithCallback:(void(^)(id)) block andSender:sender {
    if (self = [super init]) {
        _callback = block;
        _sender = sender;
    }
    else{
        DLog(@"couldn't init, something bad happened");
    }
    return self;
}
-(void)invokeTheBlock {
    _callback(_sender);
}
@end

@interface UIButton (stuff) {
}
- (void)addTarget:(void (^)(id))block forControlEvents:(UIControlEvents)controlEvents;
@end
@implementation UIButton (stuff)
static const char * UIControlDDBlockActions = "unique";
- (void)addTarget:(void (^)(id))block forControlEvents:(UIControlEvents)controlEvents {
    NSMutableArray * blockActions = objc_getAssociatedObject(self, &UIControlDDBlockActions);
    if (blockActions == nil) {
        blockActions = [NSMutableArray array];
        objc_setAssociatedObject(self, &UIControlDDBlockActions, blockActions, OBJC_ASSOCIATION_RETAIN);
    }

    id del = [[FWrapper alloc] initWithCallback:block andSender:self];
    [blockActions addObject:del];
    [self addTarget:del action:@selector(invokeTheBlock) forControlEvents:controlEvents];
}
@end
@implementation ViewController

@synthesize effect = _effect;
@synthesize context = _context;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

BOOL on;

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}}
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

GLuint _vertexBuffer;
GLuint _indexBuffer;

float _rotation;

- (void) setupGL{
    //JRW: probably not needed.
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _increasing = YES;
    _curRed = 0.0;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *glkview = /*(GLKView*)[self.view.subviews //where subview class is GLKView
     first:^BOOL(id obj) {
         return [obj isKindOfClass:[GLKView class]];
     }];
    NSAssert(nil!= glkview, @"oh no!");*/
    (GLKView*)self.view;
    glkview.context = self.context;
    
    /*glkview.delegate = self;
    glkview.enableSetNeedsDisplay = NO;
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    */
    
    NSArray * buttons = 
    [self.view.subviews where:^BOOL(id obj) {
        return [obj isKindOfClass:[UIButton class]];
    }];
    if ([buttons count] >0) {
        UIButton *go = [buttons objectAtIndex:0];
        UIButton *stop = [buttons objectAtIndex:1];
        //go addTarget:<#(id)#> action:<#(SEL)#> forControlEvents:<#(UIControlEvents)#>
        [go addTarget:^(id sender){ self.paused=YES; } forControlEvents:UIControlEventTouchUpInside];
        [stop addTarget:^(id sender){ self.paused=NO; } forControlEvents:UIControlEventTouchUpInside];
    }
    //[go addTarget:self action:@selector(goon) forControlEvents:UIControlEventTouchUpInside];
    [self setupGL];
}
- (void)goon {
    on=YES;
}

- (void)tearDownGL{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    
    self.effect = nil;
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self tearDownGL];
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
    glClearColor(_curRed, 0.0, 0.0, _curRed);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];
        
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    
    
    //glBindVertexArrayOES(_vertexBuffer);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);


}
-(void)update{

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
    
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.0f);    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);   
    _rotation += 90 * self.timeSinceLastUpdate;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 0, 1);
    self.effect.transform.modelviewMatrix = modelViewMatrix;

    
   }
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    self.paused = !self.paused;
    NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
    NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
    NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
    NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);
}
@end
