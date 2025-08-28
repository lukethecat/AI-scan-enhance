//
//  RefinementView.swift
//  AIScanEnhance
//
//  用户精修视图
//

import SwiftUI

struct RefinementView: View {
    @ObservedObject var queueManager: QueueManager
    @State private var showingCalibration = false
    @State private var selectedCorners: [CGPoint] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("处理结果")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let currentItem = queueManager.currentItem,
                   currentItem.status == .completed || currentItem.status == .reviewing {
                    Text("待确认")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 主内容区域
            if let currentItem = queueManager.currentItem,
               (currentItem.status == .completed || currentItem.status == .reviewing) {
                refinementContentView(currentItem)
            } else {
                emptyStateView
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .sheet(isPresented: $showingCalibration) {
            if let originalImage = queueManager.currentItem?.originalImage {
                // 创建一个临时的ImageProcessor用于校准
                CalibrationView(
                    image: originalImage,
                    imageProcessor: ImageProcessor()
                )
            }
        }
    }
    
    @ViewBuilder
    private func refinementContentView(_ item: QueueItem) -> some View {
        VStack(spacing: 16) {
            // 处理结果图片
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(maxHeight: 350)
                
                if let processedImage = item.processedImage {
                    Image(nsImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.checkmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("处理中...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxHeight: 350)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 对比视图切换
            if item.originalImage != nil && item.processedImage != nil {
                comparisonToggle(item)
            }
            
            // 精修控制区域
            refinementControls(item)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("没有待精修的图片")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("处理完成的图片将在此显示")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func comparisonToggle(_ item: QueueItem) -> some View {
        // 这里可以添加原图/处理后对比功能
        HStack {
            Text("处理完成")
                .font(.caption)
                .foregroundColor(.green)
            
            Spacer()
            
            Button("查看原图") {
                // 显示原图对比
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func refinementControls(_ item: QueueItem) -> some View {
        VStack(spacing: 12) {
            // 精修选项
            VStack(spacing: 8) {
                Text("精修选项")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 6) {
                    Button("手动调整角点") {
                        showingCalibration = true
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("重新自动处理") {
                        Task {
                            await queueManager.reprocessWithCorners(item: item, corners: [])
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            
            Divider()
            
            // 确认按钮
            VStack(spacing: 8) {
                Button("确认并保存") {
                    queueManager.confirmProcessing(item: item)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("跳过此图片") {
                    // 跳过当前图片，移动到下一个
                    if let nextItem = queueManager.queueItems.first(where: { 
                        $0.status == .completed && $0.id != item.id 
                    }) {
                        queueManager.startReviewing(item: nextItem)
                    } else {
                        queueManager.currentItem = nil
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

// MARK: - 注意：CalibrationView 已在单独的文件中定义

#Preview {
    RefinementView(queueManager: QueueManager())
        .frame(width: 300, height: 500)
}