//
//  ViewController.h
//  singleViewGLKitCube
//
//  Created by Jay R Wren on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface NSArray (stuff) {
}
//JRW: first or firstObjectPassingTest ?
- (id)first: (BOOL (^)(id obj))block;
- (NSArray *)where: (BOOL (^)(id obj))block;
@end

@interface FWrapper : NSObject {
    void (^_callback)(id);
    id _sender;
}

-(FWrapper*)initWithCallback:(void(^)(id)) callback andSender:sender;
-(void)invokeTheBlock;
@end

@interface ViewController : UIViewController<GLKViewDelegate>

@end
