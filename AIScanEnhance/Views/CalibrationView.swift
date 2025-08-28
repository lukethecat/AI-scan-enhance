//
//  CalibrationView.swift
//  AIScanEnhance
//
//  用户校准界面
//

import SwiftUI

struct CalibrationView: View {
    let image: NSImage
    @ObservedObject var imageProcessor: ImageProcessor
    @Environment(\.dismiss) private var dismiss
    
    @State private var cornerPoints: [CGPoint] = [
        CGPoint(x: 0.1, y: 0.1),   // 左上
        CGPoint(x: 0.9, y: 0.1),   // 右上
        CGPoint(x: 0.9, y: 0.9),   // 右下
        CGPoint(x: 0.1, y: 0.9)    // 左下
    ]
    
    @State private var draggedPointIndex: Int? = nil
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题栏
            HStack {
                Text("手动校准")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            // 说明文字
            Text("拖拽四个角点到文档的边角位置")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 图片编辑区域
            GeometryReader { geometry in
                ZStack {
                    // 背景图片
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    
                    // 覆盖层 - 显示检测区域
                    Path { path in
                        let imageFrame = getImageFrame(in: geometry.size)
                        let points = cornerPoints.map { point in
                            CGPoint(
                                x: imageFrame.minX + point.x * imageFrame.width,
                                y: imageFrame.minY + point.y * imageFrame.height
                            )
                        }
                        
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            path.addLine(to: points[i])
                        }
                        path.closeSubpath()
                    }
                    .stroke(Color.blue, lineWidth: 2)
                    
                    // 可拖拽的角点
                    ForEach(0..<4, id: \.self) { index in
                        let imageFrame = getImageFrame(in: geometry.size)
                        let point = cornerPoints[index]
                        let screenPoint = CGPoint(
                            x: imageFrame.minX + point.x * imageFrame.width,
                            y: imageFrame.minY + point.y * imageFrame.height
                        )
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .position(screenPoint)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        draggedPointIndex = index
                                        let imageFrame = getImageFrame(in: geometry.size)
                                        let relativeX = max(0, min(1, (value.location.x - imageFrame.minX) / imageFrame.width))
                                        let relativeY = max(0, min(1, (value.location.y - imageFrame.minY) / imageFrame.height))
                                        cornerPoints[index] = CGPoint(x: relativeX, y: relativeY)
                                    }
                                    .onEnded { _ in
                                        draggedPointIndex = nil
                                    }
                            )
                    }
                }
            }
            .frame(maxHeight: 500)
            
            // 控制按钮
            HStack(spacing: 16) {
                Button("重置") {
                    resetCornerPoints()
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
                
                Spacer()
                
                Button("应用校准") {
                    Task {
                        isProcessing = true
                        await imageProcessor.processImageWithCorners(cornerPoints)
                        isProcessing = false
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 700, height: 600)
        .onAppear {
            // 尝试自动检测角点
            detectInitialCorners()
        }
    }
    
    private func getImageFrame(in containerSize: CGSize) -> CGRect {
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = containerSize.width / containerSize.height
        
        let imageSize: CGSize
        if imageAspectRatio > containerAspectRatio {
            // 图片更宽，以宽度为准
            imageSize = CGSize(width: containerSize.width, height: containerSize.width / imageAspectRatio)
        } else {
            // 图片更高，以高度为准
            imageSize = CGSize(width: containerSize.height * imageAspectRatio, height: containerSize.height)
        }
        
        let origin = CGPoint(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2
        )
        
        return CGRect(origin: origin, size: imageSize)
    }
    
    private func resetCornerPoints() {
        cornerPoints = [
            CGPoint(x: 0.1, y: 0.1),   // 左上
            CGPoint(x: 0.9, y: 0.1),   // 右上
            CGPoint(x: 0.9, y: 0.9),   // 右下
            CGPoint(x: 0.1, y: 0.9)    // 左下
        ]
    }
    
    private func detectInitialCorners() {
        // 这里可以调用AI检测来获取初始角点
        // 暂时使用默认值
        Task {
            if let detectedCorners = await imageProcessor.detectCorners() {
                cornerPoints = detectedCorners
            }
        }
    }
}

#Preview {
    if let image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil) {
        CalibrationView(image: image, imageProcessor: ImageProcessor())
    }
}