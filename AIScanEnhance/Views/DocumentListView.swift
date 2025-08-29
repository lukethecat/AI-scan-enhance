//
//  DocumentListView.swift
//  AIScanEnhance
//
//  Created by AI Assistant on 2024-01-20.
//

import SwiftUI

/// 文档列表视图
struct DocumentListView: View {
    @ObservedObject var documentProcessor: DocumentProcessor
    @State private var selectedDocument: DocumentItem?
    @State private var showingPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和统计信息
            headerView
            
            // 文档列表
            if documentProcessor.documents.isEmpty {
                emptyStateView
            } else {
                documentListContent
            }
        }
        .padding()
        .sheet(isPresented: $showingPreview) {
            if let document = selectedDocument {
                DocumentPreviewSheet(document: document)
            }
        }
    }
    
    // MARK: - 子视图
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("文档列表")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("共 \(documentProcessor.documents.count) 个文档")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 批量操作按钮
            if !documentProcessor.documents.isEmpty {
                batchActionButtons
            }
        }
    }
    
    private var batchActionButtons: some View {
        HStack(spacing: 8) {
            Button("清空列表") {
                documentProcessor.clearAllDocuments()
            }
            .buttonStyle(.bordered)
            
            Button("导出PDF") {
                documentProcessor.exportToPDF()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!documentProcessor.hasCompletedDocuments)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无文档")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("拖拽图片文件到此处开始处理")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var documentListContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(documentProcessor.documents) { document in
                    DocumentRowView(
                        document: document,
                        onPreview: {
                            selectedDocument = document
                            showingPreview = true
                        },
                        onRetry: {
                            documentProcessor.retryProcessing(document)
                        },
                        onRemove: {
                            documentProcessor.removeDocument(document)
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/// 文档行视图
struct DocumentRowView: View {
    let document: DocumentItem
    let onPreview: () -> Void
    let onRetry: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态图标
            statusIcon
            
            // 文档信息
            documentInfo
            
            Spacer()
            
            // 操作按钮
            actionButtons
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(document.processingStatus.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusIcon: some View {
        Image(systemName: document.processingStatus.iconName)
            .font(.title3)
            .foregroundColor(document.processingStatus.color)
            .frame(width: 24, height: 24)
    }
    
    private var documentInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(document.fileName)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)
            
            HStack(spacing: 8) {
                Text(document.processingStatus.displayName)
                    .font(.caption)
                    .foregroundColor(document.processingStatus.color)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(document.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 处理进度条
            if document.isProcessing {
                ProgressView(value: document.processingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 4)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            if document.isCompleted {
                Button("预览", action: onPreview)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            
            if document.canRetry {
                Button("重试", action: onRetry)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            
            Button("移除", action: onRemove)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
        }
    }
}

/// 文档预览弹窗
struct DocumentPreviewSheet: View {
    let document: DocumentItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let processedURL = document.processedURL {
                    AsyncImage(url: processedURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Text("无法加载预览")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(document.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DocumentListView(documentProcessor: DocumentProcessor())
}