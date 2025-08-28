//
//  ContentView.swift
//  AIScanEnhance
//
//  主界面视图 - 现代化三栏布局
//

import SwiftUI

struct ContentView: View {
    @StateObject private var queueManager = QueueManager()
    @State private var selectedSidebarItem: SidebarItem = .queue
    
    enum SidebarItem: String, CaseIterable {
        case queue = "队列"
        case processing = "处理"
        case refinement = "精修"
        
        var icon: String {
            switch self {
            case .queue: return "list.bullet"
            case .processing: return "gearshape.2"
            case .refinement: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            List(SidebarItem.allCases, id: \.self, selection: $selectedSidebarItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .font(.system(size: 14, weight: .medium))
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            .listStyle(.sidebar)
        } content: {
            // 主内容区域
            Group {
                switch selectedSidebarItem {
                case .queue:
                    QueueView(queueManager: queueManager)
                case .processing:
                    CurrentProcessingView(queueManager: queueManager)
                case .refinement:
                    RefinementView(queueManager: queueManager)
                }
            }
            .navigationSplitViewColumnWidth(min: 400, ideal: 500)
        } detail: {
            // 详情区域
            if let currentItem = queueManager.currentItem {
                DetailView(item: currentItem, queueManager: queueManager)
            } else {
                EmptyDetailView()
            }
        }
        .navigationTitle("AI 扫描增强")
        .navigationSubtitle("智能文档处理工具")
        .toolbar(content: toolbarContent)
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button(action: openFileDialog) {
                Label("添加文件", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .disabled(queueManager.isProcessing)
            
            Button(action: { queueManager.startProcessing() }) {
                Label("开始处理", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(queueManager.isProcessing || queueManager.queueItems.isEmpty)
        }
    }
    
    private func openFileDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .heic, .tiff, .bmp]
        panel.title = "选择图片文件"
        panel.prompt = "选择"
        
        if panel.runModal() == .OK {
            queueManager.addToQueue(urls: panel.urls)
        }
    }
}

// MARK: - 详情视图
struct DetailView: View {
    let item: QueueItem
    @ObservedObject var queueManager: QueueManager
    @State private var showComparison = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.fileName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if item.processedImage != nil {
                    Button(action: { showComparison.toggle() }) {
                        Label(showComparison ? "显示处理后" : "对比原图", 
                              systemImage: showComparison ? "eye" : "rectangle.split.2x1")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            // 图片显示区域
            GeometryReader { geometry in
                ZStack {
                    Color(NSColor.controlBackgroundColor)
                    
                    if showComparison, let originalImage = item.originalImage, let processedImage = item.processedImage {
                        // 对比视图
                        HStack(spacing: 1) {
                            Image(nsImage: originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width / 2)
                                .overlay(alignment: .topLeading) {
                                    Text("原图")
                                        .font(.caption)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .padding()
                                }
                            
                            Image(nsImage: processedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width / 2)
                                .overlay(alignment: .topLeading) {
                                    Text("处理后")
                                        .font(.caption)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .padding()
                                }
                        }
                    } else if let displayImage = displayImage {
                        // 单图显示
                        Image(nsImage: displayImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .padding()
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("加载中...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 处理进度覆盖层
                    if item.status == .processing {
                        ZStack {
                            Color.black.opacity(0.3)
                            
                            VStack(spacing: 20) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                VStack(spacing: 8) {
                                    Text("AI 处理中...")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("\(Int(item.processingProgress * 100))% 完成")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                ProgressView(value: item.processingProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                    .frame(width: 200)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            // 操作按钮
            if item.status == .completed {
                HStack(spacing: 12) {
                    Button("重新处理") {
                        Task {
                            await queueManager.reprocessWithCorners(item: item, corners: [])
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("保存图片") {
                        saveProcessedImage()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.regularMaterial)
            }
        }
    }
    
    private var displayImage: NSImage? {
        if let processedImage = item.processedImage, item.status == .completed || item.status == .reviewing {
            return processedImage
        }
        return item.originalImage
    }
    
    private var statusDescription: String {
        switch item.status {
        case .pending: return "等待处理"
        case .processing: return "正在处理 - \(Int(item.processingProgress * 100))%"
        case .completed: return "处理完成"
        case .failed: return "处理失败"
        case .reviewing: return "等待精修"
        }
    }
    
    private func saveProcessedImage() {
        guard let processedImage = item.processedImage else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg]
        panel.nameFieldStringValue = "\(item.fileName)_enhanced.jpg"
        panel.title = "保存处理后的图片"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let tiffData = processedImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) {
                try? jpegData.write(to: url)
            }
        }
    }
}

// MARK: - 空状态详情视图
struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("选择图片查看详情")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("从队列中选择一张图片来查看处理详情和结果")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    ContentView()
}