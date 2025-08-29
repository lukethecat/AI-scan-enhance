//
//  ProcessingStatus.swift
//  AIScanEnhance
//
//  Created by AI Assistant on 2024-01-20.
//

import Foundation
import SwiftUI

/// 文档处理状态枚举
enum ProcessingStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    /// 状态显示名称
    var displayName: String {
        switch self {
        case .pending:
            return "等待处理"
        case .processing:
            return "正在处理"
        case .completed:
            return "处理完成"
        case .failed:
            return "处理失败"
        case .cancelled:
            return "已取消"
        }
    }
    
    /// 状态图标
    var iconName: String {
        switch self {
        case .pending:
            return "clock"
        case .processing:
            return "gear"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "stop.circle.fill"
        }
    }
    
    /// 状态颜色
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
        }
    }
    
    /// 是否为最终状态
    var isFinalState: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .pending, .processing:
            return false
        }
    }
    
    /// 是否可以重试
    var canRetry: Bool {
        switch self {
        case .failed, .cancelled:
            return true
        case .pending, .processing, .completed:
            return false
        }
    }
}

/// 处理状态扩展 - 用于动画和UI
extension ProcessingStatus {
    /// 获取状态对应的SF Symbol动画
    var animatedIcon: String {
        switch self {
        case .processing:
            return "gear.badge.questionmark"
        default:
            return iconName
        }
    }
    
    /// 状态变化动画持续时间
    var animationDuration: Double {
        switch self {
        case .processing:
            return 1.0
        default:
            return 0.3
        }
    }
}