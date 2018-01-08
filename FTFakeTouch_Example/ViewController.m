//
//  ViewController.m
//  FTFakeTouch_Example
//
//  Created by 刘博 on 2018/1/9.
//  Copyright © 2018年 devliubo. All rights reserved.
//

#import "ViewController.h"
#import "FTFakeTouch.h"
#import "TestView.h"
#import <MapKit/MapKit.h>

@interface ViewController ()<MKMapViewDelegate>

@property (nonatomic, strong) TestView *testView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) MKMapView *mapView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.testView = [[TestView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.testView];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    self.tapGesture.numberOfTapsRequired = 1;
    self.tapGesture.numberOfTouchesRequired = 1;
    [self.testView addGestureRecognizer:self.tapGesture];
    
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectInset(self.view.bounds, 10, 40)];
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(100, 100, 70, 40);
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"Test" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonAction {
    CGPoint touchPoint = CGPointMake(40, 400);
    CGPoint touchPoint2 = CGPointMake(100, 400);
//    CGPoint touchPoint3 = CGPointMake(100, 500);
    
//    [[FTFakeTouch sharedInstance] twoFingerTapInView:self.view atPoint:touchPoint];
//
//    [[FTFakeTouch sharedInstance] tapInView:self.view atPoint:touchPoint];
//    [[FTFakeTouch sharedInstance] tapInView:self.view atPoint:touchPoint];
//
//    [[FTFakeTouch sharedInstance] dragInView:self.view fromPoint:touchPoint toPoint:touchPoint2 steps:10];
//
//    [[FTFakeTouch sharedInstance] twoFingerPanInView:self.view fromPoint:touchPoint3 toPoint:touchPoint2 steps:10];
//
//    [[FTFakeTouch sharedInstance] pinchInView:self.view atPoint:touchPoint2 distance:50 steps:5];
//
//    [[FTFakeTouch sharedInstance] twoFingerRotateInView:self.view atPoint:touchPoint2 angle:90];
    
    [[FTFakeTouch sharedInstance] tapAtPoint:touchPoint];
    [[FTFakeTouch sharedInstance] tapAtPoint:touchPoint];
    
    [[FTFakeTouch sharedInstance] dragFromPoint:touchPoint toPoint:touchPoint2 steps:10];
}

- (void)tapGestureAction:(UITapGestureRecognizer *)gesture {
    CGPoint tapPoint = [gesture locationInView:self.view];
    NSLog(@"--------------------Tap At Point: %@", NSStringFromCGPoint(tapPoint));
}

@end
