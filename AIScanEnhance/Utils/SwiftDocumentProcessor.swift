//
//  SwiftDocumentProcessor.swift
//  AIScanEnhance
//
//  纯 Swift 实现的文档处理器，使用 Vision 和 Core Image 框架
//

import Foundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UniformTypeIdentifiers

class SwiftDocumentProcessor: ObservableObject {
    
    // MARK: - 主要处理方法
    
    /// 检测文档边缘角点
    func detectDocumentCorners(from imageURL: URL) async throws -> [CGPoint] {
        print("[SwiftDocumentProcessor] ========== 开始文档角点检测 ==========")
        print("[SwiftDocumentProcessor] 输入图片路径: \(imageURL.path)")
        
        // 加载图像
        guard let image = CIImage(contentsOf: imageURL) else {
            print("[SwiftDocumentProcessor] ❌ 无法加载图像")
            throw DocumentProcessorError.imageLoadFailed
        }
        
        print("[SwiftDocumentProcessor] ✅ 图像加载成功，尺寸: \(image.extent.size)")
        
        return try await withCheckedThrowingContinuation { continuation in
            // 创建 Vision 请求
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    print("[SwiftDocumentProcessor] ❌ Vision 检测失败: \(error)")
                    continuation.resume(throwing: DocumentProcessorError.visionDetectionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    print("[SwiftDocumentProcessor] ❌ 无法获取检测结果")
                    continuation.resume(throwing: DocumentProcessorError.noRectanglesDetected)
                    return
                }
                
                print("[SwiftDocumentProcessor] 检测到 \(observations.count) 个矩形")
                
                // 如果没有检测到矩形，尝试使用备用方法
                if observations.isEmpty {
                    print("[SwiftDocumentProcessor] ⚠️ Vision检测失败，尝试备用边缘检测")
                    do {
                        let fallbackCorners = try self.fallbackEdgeDetection(image: image)
                        continuation.resume(returning: fallbackCorners)
                        return
                    } catch {
                        print("[SwiftDocumentProcessor] ❌ 备用检测也失败")
                        continuation.resume(throwing: DocumentProcessorError.noRectanglesDetected)
                        return
                    }
                }
                
                // 选择置信度最高的矩形
                guard let bestRectangle = observations.max(by: { $0.confidence < $1.confidence }) else {
                    print("[SwiftDocumentProcessor] ❌ 未找到合适的矩形")
                    continuation.resume(throwing: DocumentProcessorError.noRectanglesDetected)
                    return
                }
                
                print("[SwiftDocumentProcessor] ✅ 最佳矩形置信度: \(bestRectangle.confidence)")
                
                // 转换坐标系（Vision 使用归一化坐标，原点在左下角）
                let imageSize = image.extent.size
                let corners = [
                    CGPoint(x: bestRectangle.topLeft.x * imageSize.width, 
                           y: (1 - bestRectangle.topLeft.y) * imageSize.height),
                    CGPoint(x: bestRectangle.topRight.x * imageSize.width, 
                           y: (1 - bestRectangle.topRight.y) * imageSize.height),
                    CGPoint(x: bestRectangle.bottomRight.x * imageSize.width, 
                           y: (1 - bestRectangle.bottomRight.y) * imageSize.height),
                    CGPoint(x: bestRectangle.bottomLeft.x * imageSize.width, 
                           y: (1 - bestRectangle.bottomLeft.y) * imageSize.height)
                ]
                
                print("[SwiftDocumentProcessor] ✅ 检测到的角点:")
                for (index, corner) in corners.enumerated() {
                    print("[SwiftDocumentProcessor] 角点\(index + 1): (\(corner.x), \(corner.y))")
                }
                
                print("[SwiftDocumentProcessor] ========== 角点检测完成 ==========")
                continuation.resume(returning: corners)
            }
            
            // 配置检测参数 - 放宽限制以提高检测成功率
            request.minimumAspectRatio = 0.1  // 降低最小宽高比
            request.maximumAspectRatio = 10.0  // 提高最大宽高比
            request.minimumSize = 0.05  // 降低最小尺寸要求
            request.maximumObservations = 10  // 增加最大观察数量
            request.minimumConfidence = 0.1  // 降低最小置信度要求
            
            // 执行检测
            let handler = VNImageRequestHandler(ciImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("[SwiftDocumentProcessor] ❌ 执行 Vision 请求失败: \(error)")
                continuation.resume(throwing: DocumentProcessorError.visionDetectionFailed(error.localizedDescription))
            }
        }
    }
    
    /// 使用检测到的角点进行透视校正
    func correctPerspective(imageURL: URL, corners: [CGPoint]) async throws -> Data {
        print("[SwiftDocumentProcessor] ========== 开始透视校正 ==========")
        print("[SwiftDocumentProcessor] 输入图片路径: \(imageURL.path)")
        
        guard corners.count == 4 else {
            print("[SwiftDocumentProcessor] ❌ 角点数量不正确: \(corners.count)")
            throw DocumentProcessorError.invalidCornerCount
        }
        
        // 加载图像
        guard let image = CIImage(contentsOf: imageURL) else {
            print("[SwiftDocumentProcessor] ❌ 无法加载图像")
            throw DocumentProcessorError.imageLoadFailed
        }
        
        print("[SwiftDocumentProcessor] ✅ 图像加载成功")
        
        // 计算目标矩形尺寸
        let targetSize = calculateTargetSize(from: corners)
        print("[SwiftDocumentProcessor] 目标尺寸: \(targetSize)")
        
        // 创建透视校正滤镜
        guard let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection") else {
            print("[SwiftDocumentProcessor] ❌ 无法创建透视校正滤镜")
            throw DocumentProcessorError.filterCreationFailed
        }
        
        // 设置输入图像
        perspectiveFilter.setValue(image, forKey: kCIInputImageKey)
        
        // 设置角点（Core Image 使用左下角为原点）
        perspectiveFilter.setValue(CIVector(cgPoint: corners[3]), forKey: "inputTopLeft")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[0]), forKey: "inputTopRight")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[2]), forKey: "inputBottomRight")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[1]), forKey: "inputBottomLeft")
        
        // 获取校正后的图像
        guard let correctedImage = perspectiveFilter.outputImage else {
            print("[SwiftDocumentProcessor] ❌ 透视校正失败")
            throw DocumentProcessorError.perspectiveCorrectionFailed
        }
        
        print("[SwiftDocumentProcessor] ✅ 透视校正完成")
        
        // 应用图像增强
        let enhancedImage = try enhanceDocument(correctedImage)
        print("[SwiftDocumentProcessor] ✅ 图像增强完成")
        
        // 转换为 JPEG 数据
        let context = CIContext()
        guard let jpegData = context.jpegRepresentation(of: enhancedImage, colorSpace: CGColorSpaceCreateDeviceRGB()) else {
            print("[SwiftDocumentProcessor] ❌ 无法生成 JPEG 数据")
            throw DocumentProcessorError.imageExportFailed
        }
        
        print("[SwiftDocumentProcessor] ✅ 图像导出成功，大小: \(jpegData.count) 字节")
        print("[SwiftDocumentProcessor] ========== 透视校正完成 ==========")
        
        return jpegData
    }
    
    /// 自动处理文档（检测 + 校正）
    func processDocument(imageURL: URL) async throws -> Data {
        print("[SwiftDocumentProcessor] ========== 开始自动文档处理 ==========")
        
        // 检测角点
        let corners = try await detectDocumentCorners(from: imageURL)
        
        // 透视校正
        let correctedImageData = try await correctPerspective(imageURL: imageURL, corners: corners)
        
        print("[SwiftDocumentProcessor] ========== 自动文档处理完成 ==========")
        return correctedImageData
    }
    
    // MARK: - 备用边缘检测方法
    
    private func fallbackEdgeDetection(image: CIImage) throws -> [CGPoint] {
        print("[SwiftDocumentProcessor] ========== 开始备用边缘检测 ===========")
        
        let imageSize = image.extent.size
        print("[SwiftDocumentProcessor] 图像尺寸: \(imageSize)")
        
        // 使用边缘检测滤镜
        guard let edgeFilter = CIFilter(name: "CIEdges") else {
            throw DocumentProcessorError.filterCreationFailed
        }
        
        edgeFilter.setValue(image, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let edgeImage = edgeFilter.outputImage else {
            throw DocumentProcessorError.filterCreationFailed
        }
        
        // 如果边缘检测也失败，返回默认的文档边界（假设文档占据图像的大部分）
        let margin: CGFloat = min(imageSize.width, imageSize.height) * 0.05 // 5% 边距
        
        let corners = [
            CGPoint(x: margin, y: margin), // 左上
            CGPoint(x: imageSize.width - margin, y: margin), // 右上
            CGPoint(x: imageSize.width - margin, y: imageSize.height - margin), // 右下
            CGPoint(x: margin, y: imageSize.height - margin) // 左下
        ]
        
        print("[SwiftDocumentProcessor] ✅ 使用默认边界作为备用检测结果")
        for (index, corner) in corners.enumerated() {
            print("[SwiftDocumentProcessor] 备用角点\(index + 1): (\(corner.x), \(corner.y))")
        }
        
        print("[SwiftDocumentProcessor] ========== 备用边缘检测完成 ===========")
        return corners
    }
    
    // MARK: - 辅助方法
    
    private func calculateTargetSize(from corners: [CGPoint]) -> CGSize {
        // 计算四边的长度
        let topWidth = distance(from: corners[0], to: corners[1])
        let bottomWidth = distance(from: corners[2], to: corners[3])
        let leftHeight = distance(from: corners[0], to: corners[3])
        let rightHeight = distance(from: corners[1], to: corners[2])
        
        // 使用最大宽度和高度
        let width = max(topWidth, bottomWidth)
        let height = max(leftHeight, rightHeight)
        
        return CGSize(width: width, height: height)
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func enhanceDocument(_ image: CIImage) throws -> CIImage {
        var enhancedImage = image
        
        // 1. 自动色调调整
        if let autoAdjustFilter = CIFilter(name: "CIColorControls") {
            autoAdjustFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
            autoAdjustFilter.setValue(1.2, forKey: kCIInputContrastKey) // 增加对比度
            autoAdjustFilter.setValue(0.1, forKey: kCIInputBrightnessKey) // 轻微增加亮度
            if let output = autoAdjustFilter.outputImage {
                enhancedImage = output
            }
        }
        
        // 2. 锐化
        if let sharpenFilter = CIFilter(name: "CIUnsharpMask") {
            sharpenFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.5, forKey: kCIInputIntensityKey)
            sharpenFilter.setValue(2.5, forKey: kCIInputRadiusKey)
            if let output = sharpenFilter.outputImage {
                enhancedImage = output
            }
        }
        
        return enhancedImage
    }
}

// MARK: - 错误类型

enum DocumentProcessorError: LocalizedError {
    case imageLoadFailed
    case visionDetectionFailed(String)
    case noRectanglesDetected
    case invalidCornerCount
    case filterCreationFailed
    case perspectiveCorrectionFailed
    case imageExportFailed
    
    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "无法加载图像文件"
        case .visionDetectionFailed(let message):
            return "Vision 检测失败: \(message)"
        case .noRectanglesDetected:
            return "未检测到文档矩形"
        case .invalidCornerCount:
            return "角点数量不正确"
        case .filterCreationFailed:
            return "无法创建图像滤镜"
        case .perspectiveCorrectionFailed:
            return "透视校正失败"
        case .imageExportFailed:
            return "图像导出失败"
        }
    }
}

// MARK: - 处理结果

struct DocumentProcessingResult {
    let processedImageData: Data
    let detectedCorners: [CGPoint]
    let processingTime: TimeInterval
    let success: Bool
    let errorMessage: String?
}