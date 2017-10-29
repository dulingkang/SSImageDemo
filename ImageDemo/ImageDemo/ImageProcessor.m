//
//  ImageProcessor.m
//  ImageDemo
//
//  Created by dulingkang on 2017/10/28.
//  Copyright © 2017年 com.shawn. All rights reserved.
//

#import "ImageProcessor.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation ImageProcessor

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

+ (UIImage *)blendImage:(UIImage *)image otherImage:(UIImage *)image1 positon:(CGPoint)point {
    
    // 1. Get the raw pixels of the image
    CGImageRef inputCGImage = [image CGImage];
    NSUInteger inputWidth = CGImageGetWidth(inputCGImage);
    NSUInteger inputHeight = CGImageGetHeight(inputCGImage);
    
    UInt32 * inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    CGContextRef context = [self drawToContextWithImage:inputCGImage pixels:inputPixels size:CGSizeZero];
    
    // 2. Blend the ghost onto the image
    CGImageRef ghostCGImage = [image1 CGImage];
    
    // 2.1 Calculate the size & position of the ghost
    CGFloat ghostImageAspectRatio = image1.size.width / image1.size.height;
    NSInteger targetGhostWidth = inputWidth * 0.25;
    CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
    CGPoint ghostOrigin = point;
    
    // 2.2 Scale & Get pixels of the ghost
    UInt32 * ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));
    CGContextRef ghostContext = [self drawToContextWithImage:ghostCGImage pixels:ghostPixels size:ghostSize];
    
    // 2.3 Blend each pixel
    NSUInteger offsetPixelCountForInput = ghostOrigin.y * inputWidth + ghostOrigin.x;
    for (NSUInteger j = 0; j < ghostSize.height; j++) {
        for (NSUInteger i = 0; i < ghostSize.width; i++) {
            UInt32 * inputPixel = inputPixels + j * inputWidth + i + offsetPixelCountForInput;
            UInt32 inputColor = *inputPixel;
            
            UInt32 * ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel;
            // Blend the ghost with 50% alpha
            CGFloat ghostAlpha = 0.8f * (A(ghostColor) / 255.0);
            UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha;
            UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
            UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
            
            //Clamp, not really useful here :p
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            *inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
        }
    }
    
    // 3. Convert the image to Black & White
//    for (NSUInteger j = 0; j < inputHeight; j++) {
//        for (NSUInteger i = 0; i < inputWidth; i++) {
//            UInt32 * currentPixel = inputPixels + (j * inputWidth) + i;
//            UInt32 color = *currentPixel;
//
//            // Average of RGB = greyscale
//            UInt32 averageColor = (R(color) + G(color) + B(color)) / 3.0;
//
//            *currentPixel = RGBAMake(averageColor, averageColor, averageColor, A(color));
//        }
//    }
    
    // 4. Create a new UIImage
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];
    
    // 5. Cleanup!
    CGContextRelease(context);
    CGContextRelease(ghostContext);
    free(inputPixels);
    free(ghostPixels);
    
    return processedImage;
}

+ (CGContextRef)drawToContextWithImage:(CGImageRef)image pixels:(UInt32 *)pixels size:(CGSize)size {
    size_t width = size.width ?: CGImageGetWidth(image);
    size_t height = size.height ?: CGImageGetHeight(image);
    
    // 2.
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    // 3.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // 4.
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    // 5. Cleanup
    CGColorSpaceRelease(colorSpace);
    return context;
}

@end
