//
//  SettingsView.swift
//  AIScanEnhance
//
//  Created by AI Assistant on 2024-01-20.
//

import SwiftUI

/// 设置视图
struct SettingsView: View {
    @AppStorage("outputFormat") private var outputFormat: OutputFormat = .jpeg
    @AppStorage("imageQuality") private var imageQuality: Double = 0.9
    @AppStorage("autoProcessing") private var autoProcessing: Bool = true
    @AppStorage("enableSpotlight") private var enableSpotlight: Bool = true
    @AppStorage("outputDirectory") private var outputDirectory: String = ""
    @AppStorage("uniformSize") private var uniformSize: Bool = false
    @AppStorage("targetWidth") private var targetWidth: Double = 2480
    @AppStorage("targetHeight") private var targetHeight: Double = 3508
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // 处理设置
                processingSection
                
                // 输出设置
                outputSection
                
                // 系统集成
                integrationSection
                
                // 高级设置
                advancedSection
                
                // 关于
                aboutSection
            }
            .navigationTitle("设置")
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
    
    // MARK: - 设置分组
    
    private var processingSection: some View {
        Section("处理设置") {
            Toggle("自动处理", isOn: $autoProcessing)
                .help("拖入文件后自动开始处理")
            
            Toggle("统一尺寸", isOn: $uniformSize)
                .help("将所有文档调整为统一尺寸")
            
            if uniformSize {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("目标宽度:")
                        Spacer()
                        TextField("宽度", value: $targetWidth, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("px")
                    }
                    
                    HStack {
                        Text("目标高度:")
                        Spacer()
                        TextField("高度", value: $targetHeight, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("px")
                    }
                }
                .padding(.leading)
            }
        }
    }
    
    private var outputSection: some View {
        Section("输出设置") {
            Picker("输出格式", selection: $outputFormat) {
                ForEach(OutputFormat.allCases, id: \.self) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.menu)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("图像质量:")
                    Spacer()
                    Text("\(Int(imageQuality * 100))%")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $imageQuality, in: 0.1...1.0, step: 0.1) {
                    Text("质量")
                } minimumValueLabel: {
                    Text("低")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("高")
                        .font(.caption)
                }
            }
            
            HStack {
                Text("输出目录:")
                Spacer()
                
                if outputDirectory.isEmpty {
                    Text("默认")
                        .foregroundColor(.secondary)
                } else {
                    Text(URL(fileURLWithPath: outputDirectory).lastPathComponent)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Button("选择") {
                    selectOutputDirectory()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    private var integrationSection: some View {
        Section("系统集成") {
            Toggle("Spotlight 索引", isOn: $enableSpotlight)
                .help("允许在 Spotlight 中搜索处理过的文档")
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Look 支持")
                    Text("支持空格键快速预览")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("拖拽支持")
                    Text("支持从 Finder 拖拽文件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
    
    private var advancedSection: some View {
        Section("高级设置") {
            Button("清除缓存") {
                clearCache()
            }
            .foregroundColor(.red)
            
            Button("重置设置") {
                resetSettings()
            }
            .foregroundColor(.red)
            
            HStack {
                Text("处理引擎:")
                Spacer()
                Text("Vision Framework")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("支持格式:")
                Spacer()
                Text("JPEG, PNG, HEIC, PDF")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var aboutSection: some View {
        Section("关于") {
            HStack {
                Text("版本:")
                Spacer()
                Text("2.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("构建:")
                Spacer()
                Text("2024.01.20")
                    .foregroundColor(.secondary)
            }
            
            Link("GitHub 仓库", destination: URL(string: "https://github.com/yourusername/ai-scan-enhance")!)
            
            Link("反馈问题", destination: URL(string: "https://github.com/yourusername/ai-scan-enhance/issues")!)
        }
    }
    
    // MARK: - 操作方法
    
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "选择输出目录"
        
        if panel.runModal() == .OK {
            outputDirectory = panel.url?.path ?? ""
        }
    }
    
    private func clearCache() {
        // 清除缓存逻辑
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "AIScanEnhance")
        
        if let cacheURL = cacheURL {
            try? FileManager.default.removeItem(at: cacheURL)
        }
    }
    
    private func resetSettings() {
        outputFormat = .jpeg
        imageQuality = 0.9
        autoProcessing = true
        enableSpotlight = true
        outputDirectory = ""
        uniformSize = false
        targetWidth = 2480
        targetHeight = 3508
    }
}

/// 输出格式枚举
enum OutputFormat: String, CaseIterable {
    case jpeg = "jpeg"
    case png = "png"
    case heic = "heic"
    
    var displayName: String {
        switch self {
        case .jpeg:
            return "JPEG"
        case .png:
            return "PNG"
        case .heic:
            return "HEIC"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        case .heic:
            return "heic"
        }
    }
}

#Preview {
    SettingsView()
}