//
//  ProcessingStatus.swift
//  AIScanEnhance
//
//  文档处理状态枚举
//

import Foundation
import SwiftUI

enum ProcessingStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case reviewing = "reviewing"
    
    var displayName: String {
        switch self {
        case .pending:
            return "等待处理"
        case .processing:
            return "处理中"
        case .completed:
            return "已完成"
        case .failed:
            return "处理失败"
        case .cancelled:
            return "已取消"
        case .reviewing:
            return "审核中"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending:
            return "clock"
        case .processing:
            return "gear"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "xmark.circle"
        case .cancelled:
            return "stop.circle"
        case .reviewing:
            return "eye.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        case .reviewing:
            return .purple
        }
    }
    
    var isCompleted: Bool {
        return self == .completed
    }
    
    var isFailed: Bool {
        return self == .failed
    }
    
    var isProcessing: Bool {
        return self == .processing
    }
}