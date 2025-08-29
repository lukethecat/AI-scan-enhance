//
//  ContentView.swift
//  AIScanEnhance
//
//  主界面视图 - 现代化单页面设计
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation
import Vision
import CoreImage
import PDFKit

struct ContentView: View {
    @EnvironmentObject var documentProcessor: DocumentProcessor
    @State private var showingImagePicker = false
    @State private var dragOver = false
    
    var body: some View {
        HSplitView {
            // 左侧：文档列表
            DocumentListView()
                .frame(minWidth: 300, idealWidth: 350, maxWidth: 400)
            
            // 右侧：图像预览和处理
            DocumentDetailView()
                .frame(minWidth: 600)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { documentProcessor.showFileImporter = true }) {
                    Label("添加图片", systemImage: "plus")
                }
                .help("添加要处理的图片文件")
                
                if !documentProcessor.documents.isEmpty {
                    Button(action: { documentProcessor.startBatchProcessing() }) {
                        Label("开始处理", systemImage: documentProcessor.isProcessing ? "stop.fill" : "play.fill")
                    }
                    .disabled(documentProcessor.documents.allSatisfy { $0.processingStatus == .completed })
                    .help(documentProcessor.isProcessing ? "停止处理" : "开始批量处理")
                    
                    Button(action: { documentProcessor.normalizeAllDocuments() }) {
                        Label("统一尺寸", systemImage: "rectangle.3.group")
                    }
                    .disabled(documentProcessor.documents.filter { $0.processingStatus == .completed }.isEmpty || documentProcessor.isProcessing)
                    .help("将所有文档统一为A4尺寸")
                    
                    Button(action: { documentProcessor.exportToPDF() }) {
                        Label("导出PDF", systemImage: "doc.text")
                    }
                    .disabled(documentProcessor.documents.filter { $0.processingStatus == .completed }.isEmpty)
                    .help("将处理完成的文档导出为PDF")
                }
            }
        }
        .fileImporter(
            isPresented: $documentProcessor.showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                documentProcessor.addDocuments(from: urls)
            case .failure(let error):
                print("文件选择失败: \(error)")
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
            handleDrop(providers: providers)
        }
        .overlay(
            dragOver ? 
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 3)
                .background(Color.accentColor.opacity(0.1))
                .animation(.easeInOut(duration: 0.2), value: dragOver)
            : nil
        )
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let urls = providers.compactMap { provider -> URL? in
            var url: URL?
            let semaphore = DispatchSemaphore(value: 0)
            
            _ = provider.loadObject(ofClass: URL.self) { loadedURL, _ in
                url = loadedURL
                semaphore.signal()
            }
            
            semaphore.wait()
            return url
        }
        
        let imageURLs = urls.filter { url in
            let allowedTypes: [UTType] = [.jpeg, .png, .tiff, .heic, .bmp, .gif]
            return allowedTypes.contains { $0.conforms(to: UTType(filenameExtension: url.pathExtension) ?? UTType.data) }
        }
        
        if !imageURLs.isEmpty {
            documentProcessor.addDocuments(from: imageURLs)
            
            // macOS原生反馈 - 触觉反馈和声音
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            NSSound(named: .init("Blow"))?.play()
            
            return true
        }
        
        return false
    }
}

// MARK: - 文档列表视图

struct DocumentListView: View {
    @EnvironmentObject var documentProcessor: DocumentProcessor
    @State private var selectedDocumentForPreview: DocumentItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("文档列表")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(documentProcessor.documents.count) 个文件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            
            Divider()
            
            // 文档列表
            if documentProcessor.documents.isEmpty {
                EmptyDocumentListView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(documentProcessor.documents) { document in
                        DocumentRowView(document: document)
                            .onTapGesture {
                                documentProcessor.selectDocument(document)
                            }
                            .focusable()
                            .modifier(SpaceKeyModifier(document: document, selectedDocumentForPreview: $selectedDocumentForPreview))
                    }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            
            // 底部操作栏
            if !documentProcessor.documents.isEmpty {
                Divider()
                
                HStack(spacing: 12) {
                    Button("清空列表") {
                        documentProcessor.clearAllDocuments()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    if documentProcessor.isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("处理中...")
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(item: $selectedDocumentForPreview) { document in
            QuickPreviewView(document: document)
        }
    }
}

// MARK: - 快速预览视图
struct QuickPreviewView: View {
    let document: DocumentItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text(document.fileName)
                    .font(.headline)
                Spacer()
                Button("关闭") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            
            ScrollView([.horizontal, .vertical]) {
                if let processedImage = document.processedImage {
                    Image(nsImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    if let nsImage = NSImage(contentsOf: document.originalURL) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(.quaternary)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .focusable()
        .modifier(EscapeKeyModifier(dismiss: dismiss))
    }
}

// MARK: - 空文档列表视图

struct EmptyDocumentListView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无文档")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("拖拽图片文件到此处或点击添加按钮")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 文档行视图

struct DocumentRowView: View {
    let document: DocumentItem
    @EnvironmentObject var documentProcessor: DocumentProcessor
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            Group {
                if let nsImage = NSImage(contentsOf: document.originalURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 60, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 0.5)
            )
            
            // 文档信息
            VStack(alignment: .leading, spacing: 4) {
                Text(document.originalURL.lastPathComponent)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    StatusBadge(status: document.processingStatus)
                    
                    if document.processingStatus == .processing {
                        ProgressView(value: document.processingProgress)
                            .progressViewStyle(.linear)
                            .frame(width: 60)
                    }
                }
                
                if let error = document.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 操作按钮
            VStack(spacing: 4) {
                if document.processingStatus == .completed {
                    Button(action: {
                        documentProcessor.selectedDocument = document
                    }) {
                        Image(systemName: "eye")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("查看结果")
                }
                
                Button(action: {
                    documentProcessor.removeDocument(document)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .help("删除")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            documentProcessor.selectedDocument?.id == document.id ? 
            Color.accentColor.opacity(0.1) : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            documentProcessor.selectedDocument = document
        }
    }
}

// MARK: - 状态标识

struct StatusBadge: View {
    let status: ProcessingStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .reviewing: return .purple
        case .cancelled: return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending: return "等待中"
        case .processing: return "处理中"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .reviewing: return "审核中"
        case .cancelled: return "已取消"
        }
    }
}

// MARK: - 文档详情视图

struct DocumentDetailView: View {
    @EnvironmentObject var documentProcessor: DocumentProcessor
    
    var body: some View {
        Group {
            if let selectedDocument = documentProcessor.selectedDocument {
                DocumentComparisonView(document: selectedDocument)
            } else {
                EmptyDetailView()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - 文档对比视图

struct DocumentComparisonView: View {
    let document: DocumentItem
    @EnvironmentObject var documentProcessor: DocumentProcessor
    @State private var showingOriginal = false
    @State private var zoomScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.originalURL.lastPathComponent)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        StatusBadge(status: document.processingStatus)
                        
                        if document.processingStatus == .processing {
                            ProgressView(value: document.processingProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 100)
                        }
                    }
                }
                
                Spacer()
                
                // 控制按钮
                HStack(spacing: 12) {
                    if document.processingStatus == .completed {
                        Toggle("显示原图", isOn: $showingOriginal)
                            .toggleStyle(.switch)
                        
                        Button("重新处理") {
                            Task {
                                await documentProcessor.reprocessDocument(document)
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("保存图片") {
                            documentProcessor.saveProcessedImage(document)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial)
            
            Divider()
            
            // 图像显示区域
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    DocumentImageView(
                        document: document,
                        showingOriginal: showingOriginal
                    )
                    .scaleEffect(zoomScale)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                }
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = max(0.5, min(3.0, value))
                    }
            )
            
            // 底部信息栏
            if document.processingStatus == .completed {
                Divider()
                
                HStack {
                    Text(showingOriginal ? "原始图像" : "处理后图像")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("缩放: \(Int(zoomScale * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(.regularMaterial)
            }
        }
    }
}

// MARK: - 处理中覆盖层

struct DocumentImageView: View {
    let document: DocumentItem
    let showingOriginal: Bool
    
    var body: some View {
        Group {
            if document.processingStatus == .completed {
                CompletedDocumentImageView(document: document, showingOriginal: showingOriginal)
            } else {
                ProcessingDocumentImageView(document: document)
            }
        }
    }
}

struct CompletedDocumentImageView: View {
    let document: DocumentItem
    let showingOriginal: Bool
    
    var body: some View {
        Group {
            if showingOriginal {
                OriginalImageView(url: document.originalURL)
            } else if let processedImage = document.processedImage {
                Image(nsImage: processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

struct ProcessingDocumentImageView: View {
    let document: DocumentItem
    
    var body: some View {
        OriginalImageView(url: document.originalURL)
            .overlay {
                if document.processingStatus == .processing {
                    ProcessingOverlay(progress: document.processingProgress)
                }
            }
    }
}

struct OriginalImageView: View {
    let url: URL
    
    var body: some View {
        Group {
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }
}

struct ProcessingOverlay: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            
            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                
                Text("处理中... \(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - 空详情视图

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text("选择文档查看详情")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("从左侧列表中选择一个文档来查看处理结果")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
     }
}

// MARK: - Custom View Modifiers

struct SpaceKeyModifier: ViewModifier {
    let document: DocumentItem
    @Binding var selectedDocumentForPreview: DocumentItem?
    
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content
                .onKeyPress(.space) {
                    selectedDocumentForPreview = document
                    return .handled
                }
        } else {
            content
        }
    }
}

struct EscapeKeyModifier: ViewModifier {
    let dismiss: DismissAction
    
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content
                .onKeyPress(.escape) {
                    dismiss()
                    return .handled
                }
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DocumentProcessor())
}