//
//  QueueManager.swift
//  AIScanEnhance
//
//  文件队列管理器
//

import SwiftUI
import Foundation
import Vision
import CoreImage

// MARK: - 处理状态枚举
enum ProcessingStatus {
    case pending      // 待处理
    case processing   // 处理中
    case completed    // 已完成
    case failed       // 处理失败
    case reviewing    // 用户精修中
}

// MARK: - 队列项目
struct QueueItem: Identifiable {
    let id = UUID()
    let originalURL: URL
    let fileName: String
    var status: ProcessingStatus = .pending
    var originalImage: NSImage?
    var processedImage: NSImage?
    var detectedCorners: [CGPoint]?
    var processingProgress: Double = 0.0
    var errorMessage: String?
    
    init(url: URL) {
        self.originalURL = url
        self.fileName = url.lastPathComponent
    }
}

// MARK: - 队列管理器
class QueueManager: ObservableObject {
    @Published var queueItems: [QueueItem] = []
    @Published var currentItem: QueueItem?
    @Published var isProcessing = false
    
    private let imageProcessor = ImageProcessor()
    private let documentProcessor = SwiftDocumentProcessor()
    
    // MARK: - 队列操作
    
    func addToQueue(urls: [URL]) {
        for url in urls {
            let item = QueueItem(url: url)
            queueItems.append(item)
            loadImageForItem(item)
        }
    }
    
    func removeFromQueue(item: QueueItem) {
        queueItems.removeAll { $0.id == item.id }
        if currentItem?.id == item.id {
            currentItem = nil
        }
    }
    
    func clearQueue() {
        queueItems.removeAll()
        currentItem = nil
    }
    
    // MARK: - 图片加载
    
    private func loadImageForItem(_ item: QueueItem) {
        guard let index = queueItems.firstIndex(where: { $0.id == item.id }) else { return }
        
        guard item.originalURL.startAccessingSecurityScopedResource() else {
            updateItemStatus(item.id, status: .failed, errorMessage: "无法访问文件")
            return
        }
        
        defer {
            item.originalURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            let imageData = try Data(contentsOf: item.originalURL)
            if let image = NSImage(data: imageData) {
                DispatchQueue.main.async {
                    self.queueItems[index].originalImage = image
                }
            }
        } catch {
            updateItemStatus(item.id, status: .failed, errorMessage: "加载图片失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 处理流程
    
    func startProcessing() {
        guard !isProcessing else { return }
        processNextItem()
    }
    
    private func processNextItem() {
        guard let nextItem = queueItems.first(where: { $0.status == .pending }) else {
            isProcessing = false
            return
        }
        
        isProcessing = true
        currentItem = nextItem
        updateItemStatus(nextItem.id, status: .processing)
        
        Task {
            await processItem(nextItem)
        }
    }
    
    private func processItem(_ item: QueueItem) async {
        do {
            // 更新进度
            updateItemProgress(item.id, progress: 0.2)
            
            // 检测角点
            let corners = try await documentProcessor.detectDocumentCorners(from: item.originalURL)
            updateItemProgress(item.id, progress: 0.5)
            
            // 处理图片
            let processedImageData = try await documentProcessor.processDocument(imageURL: item.originalURL)
            updateItemProgress(item.id, progress: 0.8)
            
            DispatchQueue.main.async {
                if let index = self.queueItems.firstIndex(where: { $0.id == item.id }) {
                    self.queueItems[index].detectedCorners = corners
                    self.queueItems[index].processedImage = NSImage(data: processedImageData)
                    self.queueItems[index].status = .completed
                    self.queueItems[index].processingProgress = 1.0
                }
                
                // 继续处理下一个
                self.processNextItem()
            }
            
        } catch {
            DispatchQueue.main.async {
                self.updateItemStatus(item.id, status: .failed, errorMessage: error.localizedDescription)
                self.processNextItem()
            }
        }
    }
    
    // MARK: - 用户精修
    
    func startReviewing(item: QueueItem) {
        currentItem = item
        updateItemStatus(item.id, status: .reviewing)
    }
    
    func confirmProcessing(item: QueueItem) {
        // 保存最终结果
        saveProcessedImage(item: item)
        updateItemStatus(item.id, status: .completed)
        
        // 移动到下一个需要精修的项目
        if let nextReviewItem = queueItems.first(where: { $0.status == .completed && $0.id != item.id }) {
            startReviewing(item: nextReviewItem)
        } else {
            currentItem = nil
        }
    }
    
    func reprocessWithCorners(item: QueueItem, corners: [CGPoint]) async {
        updateItemStatus(item.id, status: .processing)
        
        do {
            let processedImageData = try await documentProcessor.correctPerspective(
                imageURL: item.originalURL,
                corners: corners
            )
            
            DispatchQueue.main.async {
                if let index = self.queueItems.firstIndex(where: { $0.id == item.id }) {
                    self.queueItems[index].detectedCorners = corners
                    self.queueItems[index].processedImage = NSImage(data: processedImageData)
                    self.queueItems[index].status = .completed
                }
            }
        } catch {
            updateItemStatus(item.id, status: .failed, errorMessage: error.localizedDescription)
        }
    }
    
    // MARK: - 辅助方法
    
    private func updateItemStatus(_ itemId: UUID, status: ProcessingStatus, errorMessage: String? = nil) {
        DispatchQueue.main.async {
            if let index = self.queueItems.firstIndex(where: { $0.id == itemId }) {
                self.queueItems[index].status = status
                if let error = errorMessage {
                    self.queueItems[index].errorMessage = error
                }
            }
        }
    }
    
    private func updateItemProgress(_ itemId: UUID, progress: Double) {
        DispatchQueue.main.async {
            if let index = self.queueItems.firstIndex(where: { $0.id == itemId }) {
                self.queueItems[index].processingProgress = progress
            }
        }
    }
    
    private func saveProcessedImage(item: QueueItem) {
        guard let processedImage = item.processedImage else { return }
        
        // 转换NSImage为Data
        guard let tiffData = processedImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
            return
        }
        
        let fileManager = FileManager.default
        let originalDirectory = item.originalURL.deletingLastPathComponent()
        let originalName = item.originalURL.deletingPathExtension().lastPathComponent
        
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
            
            try jpegData.write(to: outputURL)
            print("图片已保存到: \(outputURL.path)")
            
        } catch {
            print("保存图片失败: \(error)")
        }
    }
}