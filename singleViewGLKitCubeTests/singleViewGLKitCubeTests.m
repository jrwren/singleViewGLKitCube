//
//  singleViewGLKitCubeTests.m
//  singleViewGLKitCubeTests
//
//  Created by Jay R Wren on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "singleViewGLKitCubeTests.h"

#import "ViewController.h"

@implementation singleViewGLKitCubeTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    //STFail(@"Unit tests are not implemented yet in singleViewGLKitCubeTests");
}
- (void)testWhere
{
    //NSArray *numbers = [[NSArray alloc] initWithObjects:0,1,2,3,4,5,6,7,8,9,10,11, nil];
    NSMutableArray *numbers = [[NSMutableArray alloc] init];
    for(int i = 0; i<=11;i++)
        [numbers addObject:[NSNumber numberWithInt:i]];
    NSArray *evens = [numbers where:^BOOL(id obj) {
        NSNumber* x = (NSNumber*)obj;
        return [x intValue]%2 == 0;
    } ];
    STAssertEquals((NSUInteger)12, [numbers count], @"Type Mismatch is BullShit should be 12 things");
    STAssertEquals([NSNumber numberWithInt:0], [evens objectAtIndex:0], @"zeor should be zeor");
    STAssertTrue([(NSNumber*)[evens objectAtIndex:1] intValue]==2, @" %d should be 2", [[evens objectAtIndex:1] intValue]);
    STAssertEquals([NSNumber numberWithInt:2], [evens objectAtIndex:1], @" should be two ", @"wtf");
}

-(void)testFWrapper{
    __block NSObject *x = [[NSObject alloc]init];
    NSObject *y = [[NSObject alloc]init];
    FWrapper *f = [[FWrapper alloc] initWithCallback:^(void){
        x=y;
    } andSender:nil];
    [f invokeTheBlock];
    STAssertTrue(x==y, @"", nil);
}
BOOL flag;
-(void)test__blockMember{
    flag = NO;
    FWrapper *f = [[FWrapper alloc] initWithCallback:^{
        flag=YES;
    } andSender:nil];
    [f invokeTheBlock];
    STAssertTrue(flag, @"", nil);
}

-(void)testWhereIsLikePredicateButNotAsCool
{
    NSMutableArray *numbers = [[NSMutableArray alloc] init];
    for(int i = 0; i<=11;i++)
        [numbers addObject:[NSNumber numberWithInt:i]];
    NSArray *evens = [numbers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"modulus:by:(SELF,2)==0"]];
    STAssertEquals((NSUInteger)12, [numbers count], @"Type Mismatch is BullShit should be 12 things");
    STAssertEquals([NSNumber numberWithInt:0], [evens objectAtIndex:0], @"zeor should be zeor");
    //^^^ I don't know why zero passes.
    STAssertTrue([(NSNumber*)[evens objectAtIndex:1] intValue]==2, @"", nil);
    
}
@end
