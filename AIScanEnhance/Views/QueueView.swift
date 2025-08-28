//
//  QueueView.swift
//  AIScanEnhance
//
//  文件队列视图
//

import SwiftUI

struct QueueView: View {
    @ObservedObject var queueManager: QueueManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 现代化标题栏
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("处理队列")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(queueManager.queueItems.count) 个文件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 状态指示器
                if queueManager.isProcessing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                        Text("处理中")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial)
            
            Divider()
            
            // 队列列表
            if queueManager.queueItems.isEmpty {
                // 现代化空状态
                VStack(spacing: 24) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("暂无文件")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("拖拽图片文件到此处\n或点击下方按钮添加文件")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    
                    Button("选择文件") {
                        selectFiles()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(queueManager.queueItems) { item in
                            QueueItemView(
                                item: item,
                                isSelected: queueManager.currentItem?.id == item.id,
                                onSelect: {
                                    if item.status == .completed {
                                        queueManager.startReviewing(item: item)
                                    }
                                },
                                onRemove: {
                                    queueManager.removeFromQueue(item: item)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
            }
            
            if !queueManager.queueItems.isEmpty {
                Divider()
                
                // 现代化控制按钮区域
                VStack(spacing: 12) {
                    // 文件操作按钮
                    HStack(spacing: 12) {
                        Button(action: selectFiles) {
                            Label("添加文件", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                        .disabled(queueManager.isProcessing)
                        .frame(maxWidth: .infinity)
                        
                        Button(action: { queueManager.clearQueue() }) {
                            Label("清空", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .disabled(queueManager.isProcessing)
                        .tint(.red)
                    }
                    
                    // 主要处理按钮
                    Button(action: { queueManager.startProcessing() }) {
                        HStack(spacing: 8) {
                            if queueManager.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("处理中...")
                            } else {
                                Image(systemName: "play.fill")
                                Text("开始处理")
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(queueManager.isProcessing || queueManager.queueItems.isEmpty)
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.regularMaterial)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        // 检查是否为图片文件
                        let imageExtensions = ["jpg", "jpeg", "png", "heic", "tiff", "bmp"]
                        if imageExtensions.contains(url.pathExtension.lowercased()) {
                            urls.append(url)
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !urls.isEmpty {
                queueManager.addToQueue(urls: urls)
            }
        }
        
        return true
    }
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .heic, .tiff, .bmp]
        panel.title = "选择图片文件"
        panel.prompt = "选择"
        
        if panel.runModal() == .OK {
            let urls = panel.urls
            queueManager.addToQueue(urls: urls)
        }
    }
}

// MARK: - 现代化队列项目视图
struct QueueItemView: View {
    let item: QueueItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 现代化缩略图
            Group {
                if let image = item.originalImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // 文件信息
            VStack(alignment: .leading, spacing: 6) {
                Text(item.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 8) {
                    statusIcon
                        .font(.system(size: 11))
                    statusText
                    Spacer(minLength: 0)
                }
            }
            
            Spacer()
            
            // 删除按钮
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundColor(.orange)
        case .processing:
            Image(systemName: "gear")
                .foregroundColor(.blue)
        case .completed:
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
        case .reviewing:
            Image(systemName: "eye")
                .foregroundColor(.purple)
        }
    }
    
    @ViewBuilder
    private var statusText: some View {
        switch item.status {
        case .pending:
            Text("待处理")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.orange)
        case .processing:
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text("处理中")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.blue)
                    Text("\(Int(item.processingProgress * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: item.processingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 40, height: 3)
            }
        case .completed:
            Text("已完成")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green)
        case .failed:
            Text("处理失败")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.red)
        case .reviewing:
            Text("等待精修")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.purple)
        }
    }
}

#Preview {
    QueueView(queueManager: QueueManager())
        .frame(width: 250, height: 400)
}