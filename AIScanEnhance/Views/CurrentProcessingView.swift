//
//  CurrentProcessingView.swift
//  AIScanEnhance
//
//  当前处理视图
//

import SwiftUI

struct CurrentProcessingView: View {
    @ObservedObject var queueManager: QueueManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("当前处理")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let currentItem = queueManager.currentItem {
                    statusBadge(for: currentItem.status)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 主内容区域
            if let currentItem = queueManager.currentItem {
                currentItemView(currentItem)
            } else {
                emptyStateView
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    @ViewBuilder
    private func currentItemView(_ item: QueueItem) -> some View {
        VStack(spacing: 20) {
            // 文件名
            Text(item.fileName)
                .font(.title3)
                .fontWeight(.medium)
                .padding(.top, 20)
            
            // 图片显示区域
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(maxHeight: 400)
                
                // 根据处理状态显示不同的图片
                if let processedImage = item.processedImage, item.status == .completed || item.status == .reviewing {
                    // 显示处理后的图片
                    Image(nsImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                } else if let originalImage = item.originalImage {
                    // 显示原始图片
                    Image(nsImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("加载中...")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 处理状态覆盖层
                if item.status == .processing {
                    processingOverlay(item)
                }
            }
            .frame(maxHeight: 400)
            
            // 状态信息
            statusInfoView(item)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("没有正在处理的图片")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("从左侧队列选择图片开始处理")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func processingOverlay(_ item: QueueItem) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                VStack(spacing: 4) {
                    Text("AI 处理中...")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(progressDescription(for: item.processingProgress))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                ProgressView(value: item.processingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
            }
        }
    }
    
    @ViewBuilder
    private func statusInfoView(_ item: QueueItem) -> some View {
        VStack(spacing: 12) {
            switch item.status {
            case .pending:
                Label("等待处理", systemImage: "clock")
                    .foregroundColor(.orange)
                
            case .processing:
                VStack(spacing: 8) {
                    Label("正在处理", systemImage: "gear")
                        .foregroundColor(.blue)
                    
                    HStack {
                        Text("进度:")
                            .font(.caption)
                        Text("\(Int(item.processingProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                }
                
            case .completed:
                Label("处理完成", systemImage: "checkmark.circle")
                    .foregroundColor(.green)
                
            case .failed:
                VStack(spacing: 4) {
                    Label("处理失败", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    
                    if let errorMessage = item.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
            case .reviewing:
                Label("等待用户精修", systemImage: "eye")
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private func statusBadge(for status: ProcessingStatus) -> some View {
        HStack(spacing: 4) {
            switch status {
            case .pending:
                Image(systemName: "clock")
                Text("待处理")
            case .processing:
                Image(systemName: "gear")
                Text("处理中")
            case .completed:
                Image(systemName: "checkmark.circle")
                Text("已完成")
            case .failed:
                Image(systemName: "exclamationmark.triangle")
                Text("失败")
            case .reviewing:
                Image(systemName: "eye")
                Text("精修中")
            }
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor(for: status).opacity(0.2))
        .foregroundColor(statusColor(for: status))
        .clipShape(Capsule())
    }
    
    private func statusColor(for status: ProcessingStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .reviewing: return .purple
        }
    }
    
    private func progressDescription(for progress: Double) -> String {
        switch progress {
        case 0.0..<0.3:
            return "初始化处理..."
        case 0.3..<0.6:
            return "检测文档边缘..."
        case 0.6..<0.9:
            return "应用透视矫正..."
        default:
            return "完成处理..."
        }
    }
}

#Preview {
    CurrentProcessingView(queueManager: QueueManager())
        .frame(width: 400, height: 500)
}