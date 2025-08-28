//
//  DropZoneView.swift
//  AIScanEnhance
//
//  拖拽区域视图
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var imageProcessor: ImageProcessor
    @State private var isDragOver = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isDragOver ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isDragOver ? Color.blue : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: isDragOver ? "photo.badge.plus.fill" : "photo.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(isDragOver ? .blue : .gray)
                    
                    Text(isDragOver ? "释放以添加图片" : "拖拽图片到此处")
                        .font(.headline)
                        .foregroundColor(isDragOver ? .blue : .gray)
                    
                    Text("支持 JPEG, PNG, HEIC 格式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
            .onDrop(of: [UTType.image], isTargeted: $isDragOver) { providers in
                handleDrop(providers: providers)
            }
            .animation(.easeInOut(duration: 0.2), value: isDragOver)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                DispatchQueue.main.async {
                    if let url = item as? URL {
                        imageProcessor.loadImage(from: url)
                    } else if let data = item as? Data {
                        imageProcessor.loadImage(from: data)
                    }
                }
            }
            return true
        }
        
        return false
    }
}

#Preview {
    DropZoneView(imageProcessor: ImageProcessor())
        .frame(height: 300)
        .padding()
}