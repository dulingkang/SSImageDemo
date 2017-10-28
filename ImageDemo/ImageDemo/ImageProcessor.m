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
    CGImageRef cgImage = [image CGImage];
    CGImageRef cgImage1 = [image1 CGImage];
    NSUInteger sourceWidth = CGImageGetWidth(cgImage);
    NSUInteger sourceHeight = CGImageGetHeight(cgImage);

    NSUInteger width1 = CGImageGetWidth(cgImage1);
    NSUInteger height1 = CGImageGetHeight(cgImage1);
   
    UInt32 *pixels = (UInt32 *)calloc(sourceHeight * sourceWidth, sizeof(UInt32));
    UInt32 *pixels1 = (UInt32 *)calloc(height1 * width1, sizeof(UInt32));
   
    CGContextRef context1 = [self drawToContextWithImage:cgImage1 pixels:pixels1 size:CGSizeMake(width1, height1)];

    CGContextRef context = [self drawToContextWithImage:cgImage pixels:pixels size:CGSizeZero];
    
    // offsetToSourceImage is is relative to source image position
    NSUInteger offsetToSourceImage = point.y * sourceWidth + point.x;
    // blend pixels
    for (NSInteger j = 0; j < height1; j++) {
        for (NSInteger i = 0; i < width1; i++) {
            // `j * sourceWidth + i` is relative position in image1.
            UInt32 *pixel = pixels + j * sourceWidth + i + offsetToSourceImage;
            UInt32 color = *pixel;
            
            UInt32 * pixel1 = pixels1 + j * (int)width1 + i;
            UInt32 color1 = *pixel1;
            
            // Blend the image1 with 50% alpha
            CGFloat alpha1 = 0.5f * (A(color1) / 255.0);
            UInt32 newR = R(color) * (1 - alpha1) + R(color1) * alpha1;
            UInt32 newG = G(color) * (1 - alpha1) + G(color1) * alpha1;
            UInt32 newB = B(color) * (1 - alpha1) + B(color1) * alpha1;
            
            //Clamp, not really useful here :p
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            *pixels = RGBAMake(newR, newG, newB, A(color));
        }
    }
    
    for (NSUInteger j = 0; j < sourceHeight; j++) {
        for (NSUInteger i = 0; i < sourceWidth; i++) {
            UInt32 * currentPixel = pixels + (j * sourceWidth) + i;
            UInt32 color = *currentPixel;
            
            // Average of RGB = greyscale
            UInt32 averageColor = (R(color) + G(color) + B(color)) / 3.0;
            
            *currentPixel = RGBAMake(averageColor, averageColor, averageColor, A(color));
        }
    }

    
    // 4. Create a new UIImage
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];
    
    // 5. Cleanup!
    CGContextRelease(context);
    CGContextRelease(context1);
    free(pixels);
    free(pixels1);
    
    return processedImage;
}

+ (CGContextRef)drawToContextWithImage:(CGImageRef)image pixels:(UInt32 *)pixels size:(CGSize)size {
    NSUInteger width = size.width ?: CGImageGetWidth(image);
    NSUInteger height = size.height ?: CGImageGetHeight(image);
    
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

+ (UIImage *)processUsingPixels:(UIImage*)inputImage {
    
    // 1. Get the raw pixels of the image
    UInt32 * inputPixels;
    
    CGImageRef inputCGImage = [inputImage CGImage];
    NSUInteger inputWidth = CGImageGetWidth(inputCGImage);
    NSUInteger inputHeight = CGImageGetHeight(inputCGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bitsPerComponent = 8;
    
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth;
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), inputCGImage);
    
    // 2. Blend the ghost onto the image
    UIImage * ghostImage = [UIImage imageNamed:@"lion"];
    CGImageRef ghostCGImage = [ghostImage CGImage];
    
    // 2.1 Calculate the size & position of the ghost
    CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height;
    NSInteger targetGhostWidth = inputWidth * 0.25;
    CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
    CGPoint ghostOrigin = CGPointMake(inputWidth * 0.5, inputHeight * 0.2);
    
    // 2.2 Scale & Get pixels of the ghost
    NSUInteger ghostBytesPerRow = bytesPerPixel * ghostSize.width;
    
    UInt32 * ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));
    
    CGContextRef ghostContext = CGBitmapContextCreate(ghostPixels, ghostSize.width, ghostSize.height,
                                                      bitsPerComponent, ghostBytesPerRow, colorSpace,
                                                      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height),ghostCGImage);
    
    // 2.3 Blend each pixel
    NSUInteger offsetPixelCountForInput = ghostOrigin.y * inputWidth + ghostOrigin.x;
    for (NSUInteger j = 0; j < ghostSize.height; j++) {
        for (NSUInteger i = 0; i < ghostSize.width; i++) {
            UInt32 * inputPixel = inputPixels + j * inputWidth + i + offsetPixelCountForInput;
            UInt32 inputColor = *inputPixel;
            
            UInt32 * ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel;
            // Blend the ghost with 50% alpha
            CGFloat ghostAlpha = 0.5f * (A(ghostColor) / 255.0);
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
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGContextRelease(ghostContext);
    free(inputPixels);
    free(ghostPixels);
    
    return processedImage;
}

@end
