//
//  AIScanEnhanceApp.swift
//  AIScanEnhance
//
//  AI扫描增强应用 - 主入口
//

import SwiftUI
import CoreSpotlight

@main
struct AIScanEnhanceApp: App {
    @StateObject private var documentProcessor = DocumentProcessor()
    
    var body: some Scene {
        WindowGroup(content: {
            ContentView()
                .environmentObject(documentProcessor)
                .frame(minWidth: 1000, minHeight: 700)
                .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                    handleSpotlightSelection(userActivity: userActivity)
                }
        })
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("添加图片...") {
                    documentProcessor.showFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("索引所有文档到Spotlight") {
                    documentProcessor.indexAllDocumentsToSpotlight()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .help) {
                Button("清除Spotlight索引") {
                    SpotlightIndexer.shared.clearAllIndexes()
                }
            }
        }
    }
    
    /// 处理从Spotlight搜索结果打开文档
    private func handleSpotlightSelection(userActivity: NSUserActivity) {
        guard let documentId = SpotlightIndexer.shared.handleSpotlightSelection(userActivity: userActivity) else {
            return
        }
        
        // 查找对应的文档并选中
        if let document = documentProcessor.documents.first(where: { $0.id == documentId }) {
            documentProcessor.selectedDocument = document
        }
    }
}