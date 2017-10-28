//
//  ImageProcessor.h
//  ImageDemo
//
//  Created by dulingkang on 2017/10/28.
//  Copyright © 2017年 com.shawn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageProcessor : NSObject

+ (UIImage *)blendImage:(UIImage *)image otherImage:(UIImage *)image1 positon:(CGPoint)point;
+ (UIImage *)processUsingPixels:(UIImage*)inputImage;
@end
