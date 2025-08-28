//
//  ImagePreviewView.swift
//  AIScanEnhance
//
//  图片预览视图
//

import SwiftUI

struct ImagePreviewView: View {
    let image: NSImage
    @Binding var isProcessing: Bool
    @State private var showingProcessedImage = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 图片显示区域
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.05))
                
                if isProcessing {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("AI 处理中...")
                            .font(.headline)
                            .padding(.top, 8)
                    }
                } else {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
            }
            
            // 图片信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("原始尺寸: \(Int(image.size.width)) × \(Int(image.size.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let imageRep = image.representations.first {
                        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(imageRep.pixelsWide * imageRep.pixelsHigh * 4), countStyle: .file)
                        Text("估计大小: \(fileSize)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 状态指示器
                HStack(spacing: 8) {
                    Circle()
                        .fill(isProcessing ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text(isProcessing ? "处理中" : "就绪")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

#Preview {
    if let image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil) {
        ImagePreviewView(image: image, isProcessing: .constant(false))
            .frame(height: 400)
            .padding()
    }
}