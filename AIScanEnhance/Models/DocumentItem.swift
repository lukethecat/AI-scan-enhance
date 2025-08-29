//
//  DocumentItem.swift
//  AIScanEnhance
//
//  文档项目数据模型
//

import Foundation
import AppKit
import Vision
import SwiftUI

struct DocumentItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let originalURL: URL
    let fileName: String
    var processingStatus: ProcessingStatus = .pending
    var processingProgress: Double = 0.0
    var errorMessage: String?
    var processedImagePath: String?
    
    // 非持久化属性 - 用于运行时图像处理
    var originalImage: NSImage?
    var processedImage: NSImage?
    var detectedCorners: [CGPoint]?
    
    init(url: URL) {
        self.originalURL = url
        self.fileName = url.lastPathComponent
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case originalURL
        case fileName
        case processingStatus
        case processingProgress
        case errorMessage
        case processedImagePath
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalURL = try container.decode(URL.self, forKey: .originalURL)
        fileName = try container.decode(String.self, forKey: .fileName)
        processingStatus = try container.decode(ProcessingStatus.self, forKey: .processingStatus)
        processingProgress = try container.decode(Double.self, forKey: .processingProgress)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        processedImagePath = try container.decodeIfPresent(String.self, forKey: .processedImagePath)
        
        // 非持久化属性设为默认值
        originalImage = nil
        processedImage = nil
        detectedCorners = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(originalURL, forKey: .originalURL)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(processingStatus, forKey: .processingStatus)
        try container.encode(processingProgress, forKey: .processingProgress)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encodeIfPresent(processedImagePath, forKey: .processedImagePath)
        // 不编码非持久化属性
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(originalURL)
        hasher.combine(fileName)
        hasher.combine(processingStatus)
    }
    
    static func == (lhs: DocumentItem, rhs: DocumentItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.originalURL == rhs.originalURL &&
               lhs.fileName == rhs.fileName &&
               lhs.processingStatus == rhs.processingStatus
    }
    
    // MARK: - Helper Methods
    mutating func updateProgress(_ progress: Double) {
        self.processingProgress = min(max(progress, 0.0), 1.0)
    }
    
    mutating func setError(_ message: String) {
        self.errorMessage = message
        self.processingStatus = .failed
    }
    
    mutating func clearError() {
        self.errorMessage = nil
    }
    
    var hasError: Bool {
        return errorMessage != nil
    }
    
    var isProcessingComplete: Bool {
        return processingStatus == .completed
    }
}