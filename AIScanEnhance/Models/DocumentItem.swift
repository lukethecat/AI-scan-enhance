//
//  DocumentItem.swift
//  AIScanEnhance
//
//  Created by AI Assistant on 2024-01-20.
//

import Foundation
import SwiftUI

/// 文档项数据模型
struct DocumentItem: Identifiable, Codable {
    let id = UUID()
    let originalURL: URL
    let fileName: String
    var processingStatus: ProcessingStatus = .pending
    var processedURL: URL?
    var thumbnailData: Data?
    var createdAt: Date = Date()
    var processedAt: Date?
    var fileSize: Int64 = 0
    var imageSize: CGSize = .zero
    var processingProgress: Double = 0.0
    var errorMessage: String?
    
    /// 初始化文档项
    init(url: URL) {
        self.originalURL = url
        self.fileName = url.lastPathComponent
        
        // 获取文件大小
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            self.fileSize = size
        }
    }
    
    /// 格式化文件大小
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// 是否处理完成
    var isCompleted: Bool {
        processingStatus == .completed
    }
    
    /// 是否处理失败
    var isFailed: Bool {
        processingStatus == .failed
    }
    
    /// 是否正在处理
    var isProcessing: Bool {
        processingStatus == .processing
    }
}

/// 文档项扩展 - 用于预览和测试
extension DocumentItem {
    static let sampleData: [DocumentItem] = [
        DocumentItem(url: URL(fileURLWithPath: "/Users/sample/document1.jpg")),
        DocumentItem(url: URL(fileURLWithPath: "/Users/sample/document2.png")),
        DocumentItem(url: URL(fileURLWithPath: "/Users/sample/document3.pdf"))
    ]
}