//
//  SpotlightIndexer.swift
//  AIScanEnhance
//
//  Created by AI Assistant on 2025-01-28.
//

import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import AppKit

class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    
    private init() {}
    
    /// 索引文档到Spotlight
    func indexDocument(_ document: DocumentItem) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.image)
        
        // 基本信息
        attributeSet.title = document.fileName
        attributeSet.displayName = document.fileName
        attributeSet.contentDescription = "AI增强扫描文档"
        
        // 文件信息
        attributeSet.contentURL = document.originalURL
        attributeSet.contentCreationDate = Date()
        attributeSet.contentModificationDate = Date()
        
        // 应用特定信息
        attributeSet.creator = "AI Scan Enhance"
        attributeSet.kind = "扫描文档"
        
        // 关键词
        var keywords = ["扫描", "文档", "AI增强", "图像处理"]
        if document.processingStatus == .completed {
            keywords.append("已处理")
        }
        attributeSet.keywords = keywords
        
        // 缩略图
        if let thumbnailData = generateThumbnail(for: document) {
            attributeSet.thumbnailData = thumbnailData
        }
        
        // 创建可搜索项
        let item = CSSearchableItem(
            uniqueIdentifier: document.id.uuidString,
            domainIdentifier: "com.aiscanenhance.documents",
            attributeSet: attributeSet
        )
        
        // 索引到Spotlight
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Spotlight索引失败: \(error.localizedDescription)")
            } else {
                print("文档已成功索引到Spotlight: \(document.fileName)")
            }
        }
    }
    
    /// 批量索引文档
    func indexDocuments(_ documents: [DocumentItem]) {
        let items = documents.map { document in
            let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.image)
            
            attributeSet.title = document.fileName
            attributeSet.displayName = document.fileName
            attributeSet.contentDescription = "AI增强扫描文档"
            attributeSet.contentURL = document.originalURL
            attributeSet.contentCreationDate = Date()
             attributeSet.contentModificationDate = Date()
            attributeSet.creator = "AI Scan Enhance"
            attributeSet.kind = "扫描文档"
            
            var keywords = ["扫描", "文档", "AI增强", "图像处理"]
            if document.processingStatus == .completed {
                keywords.append("已处理")
            }
            attributeSet.keywords = keywords
            
            if let thumbnailData = generateThumbnail(for: document) {
                attributeSet.thumbnailData = thumbnailData
            }
            
            return CSSearchableItem(
                uniqueIdentifier: document.id.uuidString,
                domainIdentifier: "com.aiscanenhance.documents",
                attributeSet: attributeSet
            )
        }
        
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("批量Spotlight索引失败: \(error.localizedDescription)")
            } else {
                print("\(items.count)个文档已成功索引到Spotlight")
            }
        }
    }
    
    /// 从Spotlight移除文档索引
    func removeDocumentFromIndex(_ documentId: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [documentId.uuidString]) { error in
            if let error = error {
                print("从Spotlight移除索引失败: \(error.localizedDescription)")
            } else {
                print("文档已从Spotlight移除: \(documentId)")
            }
        }
    }
    
    /// 清除所有索引
    func clearAllIndexes() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.aiscanenhance.documents"]) { error in
            if let error = error {
                print("清除Spotlight索引失败: \(error.localizedDescription)")
            } else {
                print("所有Spotlight索引已清除")
            }
        }
    }
    
    /// 生成文档缩略图
    private func generateThumbnail(for document: DocumentItem) -> Data? {
        guard let image = NSImage(contentsOf: document.originalURL) else { return nil }
        
        let thumbnailSize = NSSize(width: 128, height: 128)
        let thumbnail = NSImage(size: thumbnailSize)
        
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbnailSize),
                  from: NSRect(origin: .zero, size: image.size),
                  operation: NSCompositingOperation.sourceOver,
                  fraction: 1.0)
        thumbnail.unlockFocus()
        
        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])
    }
    
    /// 处理Spotlight搜索结果点击
    func handleSpotlightSelection(userActivity: NSUserActivity) -> UUID? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let documentId = UUID(uuidString: uniqueIdentifier) else {
            return nil
        }
        
        return documentId
    }
}