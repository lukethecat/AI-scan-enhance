//
//  AdvancedImageProcessor.swift
//  AIScanEnhance
//
//  高级图像处理器 - 实现完整的AI文档处理流程
//

import Foundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

class AdvancedImageProcessor {
    private let context = CIContext()
    
    // MARK: - 文档角点检测
    
    func detectDocumentCorners(from imageURL: URL) async throws -> [CGPoint] {
        print("[AdvancedImageProcessor] 开始检测文档角点")
        
        guard let image = CIImage(contentsOf: imageURL) else {
            throw DocumentProcessorError.imageLoadFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: DocumentProcessorError.visionDetectionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation],
                      let rectangle = observations.first else {
                    // 如果Vision检测失败，使用边缘检测作为备选方案
                    do {
                        let fallbackCorners = try self.fallbackEdgeDetection(image: image)
                        continuation.resume(returning: fallbackCorners)
                    } catch {
                        continuation.resume(throwing: DocumentProcessorError.noRectanglesDetected)
                    }
                    return
                }
                
                // 转换坐标系统（Vision使用标准化坐标，原点在左下角）
                let imageSize = image.extent.size
                let corners = [
                    CGPoint(x: rectangle.topLeft.x * imageSize.width, y: (1 - rectangle.topLeft.y) * imageSize.height),
                    CGPoint(x: rectangle.topRight.x * imageSize.width, y: (1 - rectangle.topRight.y) * imageSize.height),
                    CGPoint(x: rectangle.bottomRight.x * imageSize.width, y: (1 - rectangle.bottomRight.y) * imageSize.height),
                    CGPoint(x: rectangle.bottomLeft.x * imageSize.width, y: (1 - rectangle.bottomLeft.y) * imageSize.height)
                ]
                
                print("[AdvancedImageProcessor] 检测到角点: \(corners)")
                continuation.resume(returning: corners)
            }
            
            request.maximumObservations = 1
            request.minimumAspectRatio = 0.2
            request.maximumAspectRatio = 1.0
            request.minimumSize = 0.2
            request.minimumConfidence = 0.3
            
            let handler = VNImageRequestHandler(ciImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DocumentProcessorError.visionDetectionFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - 备选边缘检测
    
    private func fallbackEdgeDetection(image: CIImage) throws -> [CGPoint] {
        print("[AdvancedImageProcessor] 使用备选边缘检测")
        
        // 转换为灰度图像
        guard let grayFilter = CIFilter(name: "CIColorControls") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        grayFilter.setValue(image, forKey: kCIInputImageKey)
        grayFilter.setValue(0.0, forKey: kCIInputSaturationKey)
        
        guard let grayImage = grayFilter.outputImage else {
            throw DocumentProcessorError.filterCreationFailed
        }
        
        // 边缘检测
        guard let edgeFilter = CIFilter(name: "CIEdges") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        edgeFilter.setValue(grayImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let edgeImage = edgeFilter.outputImage else {
            throw DocumentProcessorError.filterCreationFailed
        }
        
        // 简化的角点检测 - 返回图像四个角的近似位置
        let imageSize = image.extent.size
        let margin: CGFloat = min(imageSize.width, imageSize.height) * 0.1
        
        return [
            CGPoint(x: margin, y: margin), // 左上
            CGPoint(x: imageSize.width - margin, y: margin), // 右上
            CGPoint(x: imageSize.width - margin, y: imageSize.height - margin), // 右下
            CGPoint(x: margin, y: imageSize.height - margin) // 左下
        ]
    }
    
    // MARK: - 透视校正
    
    func correctPerspective(imageURL: URL, corners: [CGPoint]) async throws -> Data {
        print("[AdvancedImageProcessor] 开始透视校正")
        
        guard let image = CIImage(contentsOf: imageURL) else {
            throw DocumentProcessorError.imageLoadFailed
        }
        
        guard corners.count == 4 else {
            throw DocumentProcessorError.invalidCornerCount
        }
        
        // 计算目标尺寸
        let targetSize = calculateOptimalTargetSize(from: corners)
        
        // 定义目标矩形的四个角点
        let targetCorners = [
            CGPoint(x: 0, y: 0), // 左上
            CGPoint(x: targetSize.width, y: 0), // 右上
            CGPoint(x: targetSize.width, y: targetSize.height), // 右下
            CGPoint(x: 0, y: targetSize.height) // 左下
        ]
        
        // 创建透视校正滤镜
        guard let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        
        perspectiveFilter.setValue(image, forKey: kCIInputImageKey)
        perspectiveFilter.setValue(CIVector(cgPoint: corners[0]), forKey: "inputTopLeft")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[1]), forKey: "inputTopRight")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[2]), forKey: "inputBottomRight")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[3]), forKey: "inputBottomLeft")
        
        guard let correctedImage = perspectiveFilter.outputImage else {
            throw DocumentProcessorError.perspectiveCorrectionFailed
        }
        
        // 裁剪到目标尺寸
        let croppedImage = correctedImage.cropped(to: CGRect(origin: .zero, size: targetSize))
        
        // 转换为Data
        guard let outputData = context.jpegRepresentation(of: croppedImage, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!) else {
            throw DocumentProcessorError.imageExportFailed
        }
        
        print("[AdvancedImageProcessor] 透视校正完成")
        return outputData
    }
    
    // MARK: - 文档增强
    
    func enhanceDocument(_ imageData: Data) async throws -> Data {
        print("[AdvancedImageProcessor] 开始文档增强")
        
        guard let image = CIImage(data: imageData) else {
            throw DocumentProcessorError.imageLoadFailed
        }
        
        var enhancedImage = image
        
        // 1. 去除反光和阴影
        enhancedImage = try removeReflectionAndShadows(enhancedImage)
        
        // 2. 色彩校正和对比度增强
        enhancedImage = try enhanceColorsAndContrast(enhancedImage)
        
        // 3. 锐化处理
        enhancedImage = try sharpenImage(enhancedImage)
        
        // 4. 噪点减少
        enhancedImage = try reduceNoise(enhancedImage)
        
        // 转换为高质量JPEG
        guard let outputData = context.jpegRepresentation(
            of: enhancedImage,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.95]
        ) else {
            throw DocumentProcessorError.imageExportFailed
        }
        
        print("[AdvancedImageProcessor] 文档增强完成")
        return outputData
    }
    
    // MARK: - 私有增强方法
    
    private func removeReflectionAndShadows(_ image: CIImage) throws -> CIImage {
        // 使用高斯模糊创建背景估计
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        blurFilter.setValue(image, forKey: kCIInputImageKey)
        blurFilter.setValue(50.0, forKey: kCIInputRadiusKey)
        
        guard let blurredImage = blurFilter.outputImage else {
            throw DocumentProcessorError.filterCreationFailed
        }
        
        // 使用除法混合模式去除不均匀光照
        guard let divideFilter = CIFilter(name: "CIDivideBlendMode") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        divideFilter.setValue(image, forKey: kCIInputImageKey)
        divideFilter.setValue(blurredImage, forKey: kCIInputBackgroundImageKey)
        
        guard let normalizedImage = divideFilter.outputImage else {
            throw DocumentProcessorError.filterCreationFailed
        }
        
        return normalizedImage
    }
    
    private func enhanceColorsAndContrast(_ image: CIImage) throws -> CIImage {
        // 自动色彩平衡
        guard let autoAdjustFilter = CIFilter(name: "CIColorControls") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        autoAdjustFilter.setValue(image, forKey: kCIInputImageKey)
        autoAdjustFilter.setValue(1.2, forKey: kCIInputContrastKey) // 增加对比度
        autoAdjustFilter.setValue(1.1, forKey: kCIInputSaturationKey) // 轻微增加饱和度
        autoAdjustFilter.setValue(0.1, forKey: kCIInputBrightnessKey) // 轻微增加亮度
        
        guard let adjustedImage = autoAdjustFilter.outputImage else {
            throw DocumentProcessorError.filterCreationFailed
        }
        
        // 伽马校正
        guard let gammaFilter = CIFilter(name: "CIGammaAdjust") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        gammaFilter.setValue(adjustedImage, forKey: kCIInputImageKey)
        gammaFilter.setValue(0.9, forKey: "inputPower") // 轻微的伽马校正
        
        return gammaFilter.outputImage ?? adjustedImage
    }
    
    private func sharpenImage(_ image: CIImage) throws -> CIImage {
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        sharpenFilter.setValue(image, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.8, forKey: kCIInputSharpnessKey) // 适度锐化
        
        return sharpenFilter.outputImage ?? image
    }
    
    private func reduceNoise(_ image: CIImage) throws -> CIImage {
        guard let noiseFilter = CIFilter(name: "CINoiseReduction") else {
            // 如果噪点减少滤镜不可用，使用轻微的高斯模糊
            guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
                return image
            }
            blurFilter.setValue(image, forKey: kCIInputImageKey)
            blurFilter.setValue(0.3, forKey: kCIInputRadiusKey)
            return blurFilter.outputImage ?? image
        }
        
        noiseFilter.setValue(image, forKey: kCIInputImageKey)
        noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
        noiseFilter.setValue(0.4, forKey: "inputSharpness")
        
        return noiseFilter.outputImage ?? image
    }
    
    // MARK: - 辅助方法
    
    private func calculateOptimalTargetSize(from corners: [CGPoint]) -> CGSize {
        // 计算四边的长度
        let topWidth = distance(from: corners[0], to: corners[1])
        let bottomWidth = distance(from: corners[3], to: corners[2])
        let leftHeight = distance(from: corners[0], to: corners[3])
        let rightHeight = distance(from: corners[1], to: corners[2])
        
        // 使用最大宽度和高度来保持文档的完整性
        let targetWidth = max(topWidth, bottomWidth)
        let targetHeight = max(leftHeight, rightHeight)
        
        // 确保尺寸合理（最小300px，最大4000px）
        let clampedWidth = max(300, min(4000, targetWidth))
        let clampedHeight = max(300, min(4000, targetHeight))
        
        return CGSize(width: clampedWidth, height: clampedHeight)
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}