//
//  ViewController.m
//  ImageDemo
//
//  Created by dulingkang on 2017/10/28.
//  Copyright © 2017年 com.shawn. All rights reserved.
//

#import "ViewController.h"
#import "ImageProcessor.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *image1 = [UIImage imageNamed:@"background"];
    UIImage *image2 = [UIImage imageNamed:@"lion"];

    self.imageView.image = [ImageProcessor processUsingPixels:image1];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
