# AI Scan Enhance

一个专为macOS设计的AI驱动扫描图片畸形矫正应用。使用先进的计算机视觉技术自动检测和矫正文档扫描中的透视畸变。

## 功能特性

- 🖱️ **拖拽操作**: 简单的拖拽界面，支持多种图片格式
- 🤖 **AI自动检测**: 智能识别文档边缘和角点
- ✋ **手动校准**: 用户可手动调整检测结果
- 📐 **透视矫正**: 高质量的透视变换算法
- 🎨 **图像增强**: 自动优化对比度和清晰度
- 📁 **智能文件管理**: 自动创建输出文件夹
- ⚡ **原生性能**: 纯Swift实现，性能优异
- 🔒 **隐私保护**: 所有处理在本地完成，无需网络连接

## 系统要求

- macOS 13.0+ (Ventura或更高版本)
- Apple Silicon (M1/M2/M3/M4) 或 Intel处理器
- 至少1GB可用存储空间

## 安装指南

### 1. 克隆项目

```bash
git clone https://github.com/your-username/AI-scan-enhance.git
cd AI-scan-enhance
```

### 2. 构建macOS应用

使用Xcode打开项目：

```bash
open AIScanEnhance.xcodeproj
```

在Xcode中：
1. 选择目标设备（Mac）
2. 点击运行按钮或按 `Cmd+R`
3. 或者使用命令行构建：

```bash
xcodebuild -project AIScanEnhance.xcodeproj -scheme AIScanEnhance -configuration Release build
```

## 使用方法

### 基本操作

1. **启动应用**: 运行编译后的应用程序
2. **添加文件**: 点击"添加文件"按钮选择图片文件
3. **开始处理**: 点击"开始处理"按钮进行AI矫正
4. **查看结果**: 在处理结果列表中查看矫正后的图片
5. **保存结果**: 处理完成后，图片自动保存到指定文件夹

### 支持的文件格式

- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC (.heic) - iOS照片格式
- TIFF (.tiff, .tif)

### 输出文件组织

```
原始文件目录/
├── document.jpg                    # 原始文件
└── document_AI_enhance/            # 自动创建的输出文件夹
    └── document_corrected.jpg      # 矫正后的文件
```

## 技术架构

### 应用架构 (Swift/SwiftUI)
- **AIScanEnhanceApp.swift**: 应用程序入口
- **ContentView.swift**: 主界面和导航
- **ImagePreviewView.swift**: 图片预览组件
- **CalibrationView.swift**: 手动校准界面
- **CurrentProcessingView.swift**: 当前处理状态视图
- **QueueView.swift**: 处理队列管理
- **RefinementView.swift**: 图片精修界面

### 核心模块
- **ImageProcessor.swift**: 图像处理核心逻辑
- **QueueManager.swift**: 任务队列管理
- **SwiftDocumentProcessor.swift**: 文档处理工具

### 核心算法

1. **边缘检测**: 基于Core Image的边缘检测
2. **轮廓检测**: 智能文档边界识别
3. **角点检测**: 自动角点定位算法
4. **透视变换**: Core Image透视校正
5. **图像增强**: 自适应对比度和清晰度优化

## 开发指南

### 项目结构

```
AI-scan-enhance/
├── AIScanEnhance/              # Swift应用源码
│   ├── App/                    # 应用程序文件
│   │   ├── AIScanEnhanceApp.swift
│   │   └── ContentView.swift
│   ├── Views/                  # 用户界面组件
│   │   ├── CalibrationView.swift
│   │   ├── CurrentProcessingView.swift
│   │   ├── ImagePreviewView.swift
│   │   ├── QueueView.swift
│   │   └── RefinementView.swift
│   ├── Models/                 # 数据模型和处理逻辑
│   │   ├── ImageProcessor.swift
│   │   └── QueueManager.swift
│   ├── Utils/                  # 工具类
│   │   └── SwiftDocumentProcessor.swift
│   ├── AIScanEnhance.entitlements  # 应用权限配置
│   └── PrivacyInfo.xcprivacy   # 隐私清单
├── AIScanEnhance.xcodeproj/    # Xcode项目文件
├── ARCHITECTURE.md            # 技术架构文档
└── README.md                  # 项目说明
```

### 添加新功能

1. **UI组件**: 在Views目录添加新的SwiftUI视图
2. **处理逻辑**: 在Models目录扩展ImageProcessor或QueueManager
3. **工具函数**: 在Utils目录添加辅助工具类

### 调试技巧

```bash
# 在Xcode中启用调试模式
# Product -> Scheme -> Edit Scheme -> Run -> Arguments -> Environment Variables
# 添加: DEBUG_MODE = 1

# 查看应用日志
log show --predicate 'subsystem == "com.aiscanenhance.app"' --last 1h
```

## 性能优化

- **图片预处理**: 大图片自动降采样
- **异步处理**: UI操作不阻塞主线程
- **内存管理**: 及时释放图片资源
- **缓存策略**: 避免重复计算

## 故障排除

### 常见问题

**Q: 应用无法启动**
A: 检查系统要求和权限设置：
- 确保macOS版本为13.0或更高
- 检查应用是否有文件访问权限
- 重新构建项目

**Q: 角点检测不准确**
A: 尝试以下方法：
- 确保图片光照均匀
- 使用手动校准模式
- 调整图片对比度
- 确保文档边缘清晰可见

**Q: 构建失败**
A: 检查以下设置：
- Xcode版本是否支持macOS 13.0+
- 开发者账户和代码签名设置
- 项目依赖是否完整

### 日志查看

```bash
# 查看应用日志
log show --predicate 'subsystem == "com.aiscanenhance.app"' --last 1h

# 查看构建日志
xcodebuild -project AIScanEnhance.xcodeproj -scheme AIScanEnhance build 2>&1 | tee build.log
```

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 致谢

- OpenCV 社区提供的优秀计算机视觉库
- Apple 提供的 SwiftUI 框架
- 所有贡献者和测试用户

## 版本历史

- **v1.0.0**: 初始版本，支持基本的文档扫描和透视矫正
- **v1.1.0**: 添加手动校准功能和批量处理
- **v1.2.0**: 优化UI界面，符合Apple设计规范
- **v1.3.0**: 添加App Store合规性支持，纯Swift实现

## 联系方式

- 项目主页: [GitHub Repository](https://github.com/your-username/AI-scan-enhance)
- 问题反馈: [Issues](https://github.com/your-username/AI-scan-enhance/issues)

---

**注意**: 这是一个开源项目，仅供学习和研究使用。商业使用请遵循相关许可证条款。
