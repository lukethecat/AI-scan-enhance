# AI Scan Enhance - 技术架构设计

## 项目概述
一个macOS Silicon原生应用，使用AI技术对扫描照片进行畸形矫正，支持拖拽操作和用户校准调整。

## 技术架构

### 前端架构 (Swift/SwiftUI)
- **框架**: SwiftUI + AppKit
- **最低系统要求**: macOS 12.0+ (支持Apple Silicon)
- **主要功能模块**:
  - 拖拽接收界面
  - 图片预览和编辑
  - 用户校准控制面板
  - 进度指示器

### AI处理后端
- **主要技术**: Python + OpenCV + NumPy
- **AI算法**:
  - 边缘检测 (Canny)
  - 轮廓检测和四边形拟合
  - 透视变换矫正
  - 图像增强 (可选)
- **通信方式**: Swift调用Python脚本

### 文件管理系统
- **输入**: 支持常见图片格式 (JPEG, PNG, HEIC等)
- **输出**: 自动创建"原文件名_AI_enhance"文件夹
- **命名规则**: 保持原文件名，添加"_corrected"后缀

## 项目结构
```
AI-Scan-Enhance/
├── AIScanEnhance.xcodeproj          # Xcode项目文件
├── AIScanEnhance/                   # Swift应用源码
│   ├── App/
│   │   ├── AIScanEnhanceApp.swift   # 应用入口
│   │   └── ContentView.swift        # 主界面
│   ├── Views/
│   │   ├── DropZoneView.swift       # 拖拽区域
│   │   ├── ImagePreviewView.swift   # 图片预览
│   │   └── CalibrationView.swift    # 校准界面
│   ├── Models/
│   │   ├── ImageProcessor.swift     # 图片处理逻辑
│   │   └── FileManager.swift        # 文件管理
│   └── Utils/
│       └── PythonBridge.swift       # Python脚本调用
├── python_backend/                  # Python AI处理脚本
│   ├── image_corrector.py          # 主处理脚本
│   ├── edge_detector.py            # 边缘检测
│   └── perspective_transform.py    # 透视变换
├── requirements.txt                 # Python依赖
└── README.md                       # 项目说明
```

## 核心工作流程

1. **文件接收**: 用户拖拽图片到应用界面
2. **预处理**: Swift读取图片，传递给Python后端
3. **AI分析**: Python检测文档边缘，计算透视变换矩阵
4. **用户校准**: 显示检测结果，允许用户调整四个角点
5. **图片矫正**: 应用透视变换，生成矫正后图片
6. **文件保存**: 在原文件目录创建新文件夹，保存结果

## 技术实现要点

### Swift端
- 使用`NSItemProvider`处理拖拽
- `Process`类调用Python脚本
- `NSImage`和`CIImage`进行图片处理
- `FileManager`处理文件操作

### Python端
- OpenCV进行图像处理
- NumPy处理数值计算
- JSON格式与Swift通信
- 命令行参数接收文件路径

### 性能优化
- 图片预处理降采样
- 异步处理避免UI阻塞
- 内存管理和缓存策略

## 部署方案
- 将Python环境打包到应用bundle
- 使用`py2app`或直接嵌入Python运行时
- 代码签名和公证支持

## 扩展功能 (未来版本)
- 批量处理支持
- 更多AI增强选项
- 云端处理选项
- 历史记录管理