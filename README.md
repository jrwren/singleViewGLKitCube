# This is just a test

* ViewController.m has all the goods

the goods look like this:

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
