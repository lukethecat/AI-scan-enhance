//
//  ProcessingView.swift
//  AIScanEnhance
//
//  Created by AI Assistant on 2024-01-20.
//

import SwiftUI

/// 处理进度视图
struct ProcessingView: View {
    @ObservedObject var documentProcessor: DocumentProcessor
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // 整体进度
            overallProgressSection
            
            // 当前处理的文档
            if let currentDocument = documentProcessor.currentProcessingDocument {
                currentDocumentSection(currentDocument)
            }
            
            // 处理队列
            if !documentProcessor.pendingDocuments.isEmpty {
                queueSection
            }
            
            // 处理统计
            statisticsSection
        }
        .padding()
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - 子视图
    
    private var overallProgressSection: some View {
        VStack(spacing: 12) {
            Text("处理进度")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 整体进度条
            VStack(spacing: 8) {
                HStack {
                    Text("总进度")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(documentProcessor.completedCount)/\(documentProcessor.totalCount)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: documentProcessor.overallProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private func currentDocumentSection(_ document: DocumentItem) -> some View {
        VStack(spacing: 12) {
            Text("当前处理")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                // 动画图标
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(animationOffset))
                    .animation(
                        .linear(duration: 2.0).repeatForever(autoreverses: false),
                        value: animationOffset
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.fileName)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("正在进行AI增强处理...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            
            // 当前文档进度
            if document.processingProgress > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("处理进度")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(document.processingProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: document.processingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 6)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("等待队列 (\(documentProcessor.pendingDocuments.count))")
                .font(.headline)
                .fontWeight(.medium)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(documentProcessor.pendingDocuments.enumerated()), id: \.element.id) { index, document in
                        queueItemView(document: document, position: index + 1)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }
    
    private func queueItemView(document: DocumentItem, position: Int) -> some View {
        HStack(spacing: 12) {
            // 队列位置
            Text("\(position)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.orange)
                .clipShape(Circle())
            
            // 文档信息
            VStack(alignment: .leading, spacing: 2) {
                Text(document.fileName)
                    .font(.body)
                    .lineLimit(1)
                
                Text(document.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 等待图标
            Image(systemName: "clock")
                .font(.body)
                .foregroundColor(.orange)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 12) {
            Text("处理统计")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack(spacing: 20) {
                statisticItem(
                    title: "已完成",
                    value: "\(documentProcessor.completedCount)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                statisticItem(
                    title: "处理中",
                    value: "\(documentProcessor.processingCount)",
                    color: .blue,
                    icon: "gear"
                )
                
                statisticItem(
                    title: "等待中",
                    value: "\(documentProcessor.pendingCount)",
                    color: .orange,
                    icon: "clock"
                )
                
                statisticItem(
                    title: "失败",
                    value: "\(documentProcessor.failedCount)",
                    color: .red,
                    icon: "xmark.circle.fill"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func statisticItem(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 动画
    
    private func startAnimation() {
        withAnimation {
            animationOffset = 360
        }
    }
}

#Preview {
    ProcessingView(documentProcessor: DocumentProcessor())
}