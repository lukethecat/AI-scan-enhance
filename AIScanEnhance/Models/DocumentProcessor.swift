//
//  DocumentProcessor.swift
//  AIScanEnhance
//
//  文档处理核心类 - 统一管理图像处理流程
//

import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers
import PDFKit

// MARK: - 文档项目模型
struct DocumentItem: Identifiable, Hashable {
    let id = UUID()
    let originalURL: URL
    let fileName: String
    var originalImage: NSImage?
    var processedImage: NSImage?
    var processingStatus: ProcessingStatus = .pending
    var processingProgress: Double = 0.0
    var detectedCorners: [CGPoint] = []
    var errorMessage: String?
    
    init(url: URL) {
        self.originalURL = url
        self.fileName = url.lastPathComponent
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DocumentItem, rhs: DocumentItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 处理状态
enum ProcessingStatus {
    case pending
    case processing
    case completed
    case failed
    case reviewing
}

// MARK: - 文档处理器
@MainActor
class DocumentProcessor: ObservableObject {
    @Published var documents: [DocumentItem] = []
    @Published var selectedDocument: DocumentItem?
    @Published var isProcessing = false
    @Published var showFileImporter = false
    @Published var processingProgress: Double = 0.0
    
    private let imageProcessor = AdvancedImageProcessor()
    private var processingTask: Task<Void, Never>?
    
    // MARK: - 文档管理
    
    func addDocuments(from urls: [URL]) {
        for url in urls {
            let document = DocumentItem(url: url)
            documents.append(document)
            loadImage(for: document)
            
            // 自动索引到Spotlight
            SpotlightIndexer.shared.indexDocument(document)
        }
    }
    
    func removeDocument(_ document: DocumentItem) {
        // 从Spotlight移除索引
        SpotlightIndexer.shared.removeDocumentFromIndex(document.id)
        
        documents.removeAll { $0.id == document.id }
        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
    }
    
    func clearAllDocuments() {
        documents.removeAll()
        selectedDocument = nil
        stopProcessing()
    }
    
    func selectDocument(_ document: DocumentItem) {
        selectedDocument = document
    }
    
    // MARK: - 图像加载
    
    private func loadImage(for document: DocumentItem) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        
        Task {
            do {
                let imageData = try Data(contentsOf: document.originalURL)
                if let image = NSImage(data: imageData) {
                    documents[index].originalImage = image
                }
            } catch {
                documents[index].processingStatus = .failed
                documents[index].errorMessage = "加载图片失败: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - 批量处理
    
    func startBatchProcessing() {
        guard !isProcessing else { return }
        
        isProcessing = true
        processingProgress = 0.0
        
        processingTask = Task {
            let pendingDocuments = documents.filter { $0.processingStatus == .pending }
            let totalCount = pendingDocuments.count
            
            for (index, document) in pendingDocuments.enumerated() {
                await processDocument(document)
                processingProgress = Double(index + 1) / Double(totalCount)
            }
            
            isProcessing = false
            processingProgress = 1.0
        }
    }
    
    func stopProcessing() {
        processingTask?.cancel()
        isProcessing = false
        processingProgress = 0.0
    }
    
    // MARK: - 单个文档处理
    
    private func processDocument(_ document: DocumentItem) async {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        
        documents[index].processingStatus = .processing
        documents[index].processingProgress = 0.0
        
        do {
            // 步骤1: 检测文档角点
            documents[index].processingProgress = 0.2
            let corners = try await imageProcessor.detectDocumentCorners(from: document.originalURL)
            documents[index].detectedCorners = corners
            
            // 步骤2: 透视校正
            documents[index].processingProgress = 0.5
            let correctedImageData = try await imageProcessor.correctPerspective(
                imageURL: document.originalURL,
                corners: corners
            )
            
            // 步骤3: 图像增强
            documents[index].processingProgress = 0.8
            let enhancedImageData = try await imageProcessor.enhanceDocument(correctedImageData)
            
            // 步骤4: 创建处理后的图像
            documents[index].processingProgress = 1.0
            if let processedImage = NSImage(data: enhancedImageData) {
                documents[index].processedImage = processedImage
                documents[index].processingStatus = .completed
            } else {
                throw DocumentProcessorError.imageExportFailed
            }
            
        } catch {
            documents[index].processingStatus = .failed
            documents[index].errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - 重新处理
    
    func reprocessDocument(_ document: DocumentItem, with corners: [CGPoint]? = nil) async {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        
        documents[index].processingStatus = .processing
        documents[index].processingProgress = 0.0
        
        do {
            let cornersToUse = corners ?? documents[index].detectedCorners
            
            let correctedImageData = try await imageProcessor.correctPerspective(
                imageURL: document.originalURL,
                corners: cornersToUse
            )
            
            let enhancedImageData = try await imageProcessor.enhanceDocument(correctedImageData)
            
            if let processedImage = NSImage(data: enhancedImageData) {
                documents[index].processedImage = processedImage
                documents[index].processingStatus = .completed
                documents[index].processingProgress = 1.0
            }
            
        } catch {
            documents[index].processingStatus = .failed
            documents[index].errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - 导出功能
    
    func saveProcessedImage(_ document: DocumentItem) {
        guard let processedImage = document.processedImage else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.jpeg, .png]
        savePanel.nameFieldStringValue = "\(document.fileName)_processed"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                self.saveImage(processedImage, to: url)
            }
        }
    }
    
    func exportToPDF() {
        let completedDocuments = documents.filter { $0.processingStatus == .completed && $0.processedImage != nil }
        guard !completedDocuments.isEmpty else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "扫描文档.pdf"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                self.createPDF(from: completedDocuments, at: url)
            }
        }
    }
    
    private func saveImage(_ image: NSImage, to url: URL) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return }
        
        let imageData: Data?
        
        switch url.pathExtension.lowercased() {
        case "png":
            imageData = bitmapRep.representation(using: .png, properties: [:])
        case "jpg", "jpeg":
            imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        default:
            imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        }
        
        try? imageData?.write(to: url)
    }
    
    private func createPDF(from documents: [DocumentItem], at url: URL) {
        let pdfDocument = PDFDocument()
        
        // 统一文档尺寸 - 使用A4标准尺寸
        let standardSize = CGSize(width: 595, height: 842) // A4 in points
        
        for (index, document) in documents.enumerated() {
            guard let image = document.processedImage else { continue }
            
            // 调整图像尺寸以适应标准页面
            let normalizedImage = normalizeImageSize(image, to: standardSize)
            let page = PDFPage(image: normalizedImage)
            pdfDocument.insert(page!, at: index)
        }
        
        pdfDocument.write(to: url)
    }
    
    // MARK: - 图像尺寸标准化
    
    private func normalizeImageSize(_ image: NSImage, to targetSize: CGSize) -> NSImage {
        let imageSize = image.size
        let targetAspectRatio = targetSize.width / targetSize.height
        let imageAspectRatio = imageSize.width / imageSize.height
        
        var newSize: CGSize
        
        if imageAspectRatio > targetAspectRatio {
            // 图像更宽，以宽度为准
            newSize = CGSize(
                width: targetSize.width,
                height: targetSize.width / imageAspectRatio
            )
        } else {
            // 图像更高，以高度为准
            newSize = CGSize(
                width: targetSize.height * imageAspectRatio,
                height: targetSize.height
            )
        }
        
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        
        // 白色背景
        NSColor.white.setFill()
        NSRect(origin: .zero, size: targetSize).fill()
        
        // 居中绘制图像
        let drawRect = NSRect(
            x: (targetSize.width - newSize.width) / 2,
            y: (targetSize.height - newSize.height) / 2,
            width: newSize.width,
            height: newSize.height
        )
        
        image.draw(in: drawRect)
        newImage.unlockFocus()
        
        return newImage
    }
    
    // MARK: - 批量尺寸统一
    
    func normalizeAllDocuments() {
        guard !isProcessing else { return }
        
        isProcessing = true
        processingProgress = 0.0
        
        processingTask = Task {
            let completedDocuments = documents.filter { $0.processingStatus == .completed && $0.processedImage != nil }
            let totalCount = completedDocuments.count
            
            for (index, document) in completedDocuments.enumerated() {
                guard let processedImage = document.processedImage else { continue }
                
                // 统一尺寸为A4比例
                let standardSize = CGSize(width: 2480, height: 3508) // A4 at 300 DPI
                let normalizedImage = normalizeImageSize(processedImage, to: standardSize)
                
                // 更新文档
                if let docIndex = documents.firstIndex(where: { $0.id == document.id }) {
                    documents[docIndex].processedImage = normalizedImage
                }
                
                processingProgress = Double(index + 1) / Double(totalCount)
            }
            
            isProcessing = false
            processingProgress = 1.0
        }
    }
    
    /// 批量索引现有文档到Spotlight
    func indexAllDocumentsToSpotlight() {
        SpotlightIndexer.shared.indexDocuments(documents)
    }
    
    /// 添加文档时自动索引到Spotlight
    func addDocumentWithSpotlightIndex(from url: URL) {
        addDocuments(from: [url])
        
        // 找到刚添加的文档并索引
        if let document = documents.first(where: { $0.originalURL == url }) {
            SpotlightIndexer.shared.indexDocument(document)
        }
    }
    
    /// 删除文档时从Spotlight移除索引
    func removeDocumentWithSpotlightIndex(_ document: DocumentItem) {
        SpotlightIndexer.shared.removeDocumentFromIndex(document.id)
        removeDocument(document)
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