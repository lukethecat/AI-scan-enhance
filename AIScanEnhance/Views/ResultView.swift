//
//  ResultView.swift
//  AIScanEnhance
//
//  Created by AI Assistant on 2024-01-20.
//

import SwiftUI
import QuickLook

/// 结果展示视图
struct ResultView: View {
    @ObservedObject var documentProcessor: DocumentProcessor
    @State private var selectedDocument: DocumentItem?
    @State private var showingComparison = false
    @State private var showingQuickLook = false
    @State private var quickLookURL: URL?
    
    var completedDocuments: [DocumentItem] {
        documentProcessor.documents.filter { $0.isCompleted }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和操作
            headerView
            
            // 结果网格
            if completedDocuments.isEmpty {
                emptyStateView
            } else {
                resultGridView
            }
        }
        .padding()
        .sheet(isPresented: $showingComparison) {
            if let document = selectedDocument {
                ComparisonView(document: document)
            }
        }
        .quickLookPreview($quickLookURL)
    }
    
    // MARK: - 子视图
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("处理结果")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("共 \(completedDocuments.count) 个已完成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !completedDocuments.isEmpty {
                actionButtons
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("导出全部") {
                exportAllResults()
            }
            .buttonStyle(.bordered)
            
            Button("生成PDF") {
                documentProcessor.exportToPDF()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无处理结果")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("完成文档处理后，结果将在此显示")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var resultGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
            ], spacing: 16) {
                ForEach(completedDocuments) { document in
                    ResultCardView(
                        document: document,
                        onCompare: {
                            selectedDocument = document
                            showingComparison = true
                        },
                        onQuickLook: {
                            quickLookURL = document.processedURL
                            showingQuickLook = true
                        },
                        onExport: {
                            exportDocument(document)
                        }
                    )
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - 操作方法
    
    private func exportAllResults() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.folder]
        panel.canCreateDirectories = true
        panel.title = "选择导出目录"
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            documentProcessor.exportAllResults(to: url)
        }
    }
    
    private func exportDocument(_ document: DocumentItem) {
        guard let processedURL = document.processedURL else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg, .png]
        panel.nameFieldStringValue = document.fileName
        panel.title = "导出处理结果"
        
        if panel.runModal() == .OK {
            guard let saveURL = panel.url else { return }
            
            do {
                try FileManager.default.copyItem(at: processedURL, to: saveURL)
            } catch {
                print("导出失败: \(error)")
            }
        }
    }
}

/// 结果卡片视图
struct ResultCardView: View {
    let document: DocumentItem
    let onCompare: () -> Void
    let onQuickLook: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 预览图片
            thumbnailView
            
            // 文档信息
            documentInfoView
            
            // 操作按钮
            actionButtonsView
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var thumbnailView: some View {
        Group {
            if let processedURL = document.processedURL {
                AsyncImage(url: processedURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .frame(height: 150)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(height: 150)
        .clipped()
        .cornerRadius(8)
    }
    
    private var documentInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(document.fileName)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(2)
            
            HStack {
                Label("已完成", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text(document.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let processedAt = document.processedAt {
                Text("处理时间: \(processedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            Button("对比") {
                onCompare()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button("预览") {
                onQuickLook()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button("导出") {
                onExport()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}

/// 对比视图
struct ComparisonView: View {
    let document: DocumentItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingOriginal = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 切换按钮
                Picker("视图模式", selection: $showingOriginal) {
                    Text("处理后").tag(false)
                    Text("原始图片").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 图片显示
                imageComparisonView
                
                Spacer()
            }
            .navigationTitle("前后对比")
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
    
    private var imageComparisonView: some View {
        Group {
            if showingOriginal {
                AsyncImage(url: document.originalURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
            } else {
                if let processedURL = document.processedURL {
                    AsyncImage(url: processedURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Text("处理结果不可用")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ResultView(documentProcessor: DocumentProcessor())
}