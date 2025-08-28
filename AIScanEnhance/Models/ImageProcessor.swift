//
//  ImageProcessor.swift
//  AIScanEnhance
//
//  图片处理核心逻辑
//

import SwiftUI
import Foundation
import Vision
import CoreImage
import UserNotifications

class ImageProcessor: ObservableObject {
    @Published var currentImage: NSImage?
    @Published var processedImage: NSImage?
    @Published var originalImageURL: URL?
    
    private let documentProcessor = SwiftDocumentProcessor()
    
    // MARK: - 图片加载
    
    func loadImage(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("无法访问文件: \(url)")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let imageData = try Data(contentsOf: url)
            loadImage(from: imageData)
            originalImageURL = url
        } catch {
            print("加载图片失败: \(error)")
        }
    }
    
    func loadImage(from data: Data) {
        guard let image = NSImage(data: data) else {
            print("无法创建图片对象")
            return
        }
        
        DispatchQueue.main.async {
            self.currentImage = image
            self.processedImage = nil
        }
    }
    
    // MARK: - 图片处理
    
    func processImage() async {
        guard let image = currentImage,
              let originalURL = originalImageURL else {
            print("没有可处理的图片")
            return
        }
        
        do {
            let startTime = Date()
            let processedImageData = try await documentProcessor.processDocument(imageURL: originalURL)
            let processingTime = Date().timeIntervalSince(startTime)
            
            let result = ProcessingResult(
                processedImageData: processedImageData,
                detectedCorners: nil,
                processingTime: processingTime,
                success: true,
                errorMessage: nil
            )
            
            DispatchQueue.main.async {
                self.processedImage = NSImage(data: processedImageData)
                
                // 保存处理后的图片
                self.saveProcessedImage(result: result)
            }
        } catch {
            print("图片处理失败: \(error)")
        }
    }
    
    func processImageWithCorners(_ corners: [CGPoint]) async {
        guard let image = currentImage,
              let originalURL = originalImageURL else {
            print("没有可处理的图片")
            return
        }
        
        do {
            let startTime = Date()
            let processedImageData = try await documentProcessor.correctPerspective(
                imageURL: originalURL,
                corners: corners
            )
            let processingTime = Date().timeIntervalSince(startTime)
            
            let result = ProcessingResult(
                processedImageData: processedImageData,
                detectedCorners: corners,
                processingTime: processingTime,
                success: true,
                errorMessage: nil
            )
            
            DispatchQueue.main.async {
                self.processedImage = NSImage(data: processedImageData)
                
                // 保存处理后的图片
                self.saveProcessedImage(result: result)
            }
        } catch {
            print("图片处理失败: \(error)")
        }
    }
    
    func detectCorners() async -> [CGPoint]? {
        guard let originalURL = originalImageURL else {
            return nil
        }
        
        do {
            return try await documentProcessor.detectDocumentCorners(from: originalURL)
        } catch {
            print("角点检测失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 文件管理
    
    private func saveProcessedImage(result: ProcessingResult) {
        guard let originalURL = originalImageURL,
              let processedData = result.processedImageData else {
            return
        }
        
        let fileManager = FileManager.default
        let originalDirectory = originalURL.deletingLastPathComponent()
        let originalName = originalURL.deletingPathExtension().lastPathComponent
        
        // 创建输出文件夹
        let outputFolderName = "\(originalName)_AI_enhance"
        let outputDirectory = originalDirectory.appendingPathComponent(outputFolderName)
        
        do {
            if !fileManager.fileExists(atPath: outputDirectory.path) {
                try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            }
            
            // 保存处理后的图片
            let outputFileName = "\(originalName)_corrected.jpg"
            let outputURL = outputDirectory.appendingPathComponent(outputFileName)
            
            try processedData.write(to: outputURL)
            
            print("图片已保存到: \(outputURL.path)")
            
            // 显示保存成功的通知
            DispatchQueue.main.async {
                self.showSaveSuccessNotification(outputURL: outputURL)
            }
            
        } catch {
            print("保存图片失败: \(error)")
        }
    }
    
    private func showSaveSuccessNotification(outputURL: URL) {
        // 使用现代通知框架
        let center = UNUserNotificationCenter.current()
        // 先请求授权（仅请求一次，不会重复弹框，系统会记忆）
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知授权失败: \(error)")
                return
            }
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "处理完成"
            content.body = "图片已保存到: \(outputURL.path)"
            content.sound = .default
            
            // 立即触发一次
            let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                content: content,
                                                trigger: nil)
            center.add(request) { err in
                if let err = err { print("添加通知失败: \(err)") }
            }
        }
    }
    
    // MARK: - 清理
    
    func clearImage() {
        currentImage = nil
        processedImage = nil
        originalImageURL = nil
    }
}

// MARK: - 处理结果结构

struct ProcessingResult {
    let processedImageData: Data?
    let detectedCorners: [CGPoint]?
    let processingTime: TimeInterval
    let success: Bool
    let errorMessage: String?
}