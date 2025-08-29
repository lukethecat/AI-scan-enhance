# AI Scan Enhance

一个专为macOS设计的AI驱动扫描图片增强应用。使用先进的计算机视觉技术和机器学习算法，自动检测和矫正文档扫描中的各种问题，包括透视畸变、反光、色彩失真等。

## 功能特性

### 核心功能
- 🖱️ **拖拽操作**: 现代化的拖拽界面，支持多种图片格式
- 🤖 **AI智能处理**: 基于Vision框架的文档检测和图像增强
- 📐 **透视矫正**: 自动检测文档边缘并进行透视校正
- ✨ **反光去除**: 智能识别并消除扫描图片中的反光
- 🎨 **色彩增强**: 自动优化对比度、亮度和色彩平衡
- 📊 **倾斜校正**: 自动检测并校正文档倾斜角度

### macOS原生特性
- 🔍 **Spotlight集成**: 处理后的文档自动索引到系统搜索
- 👁️ **快速预览**: 支持macOS原生的Quick Look预览
- 📁 **拖拽支持**: 完整的文件拖拽操作体验
- 📱 **现代UI**: 符合macOS设计规范的SwiftUI界面

### 批处理功能
- 📦 **批量处理**: 支持同时处理多个文档
- 📄 **PDF导出**: 将处理后的图片合并为PDF文档
- 📏 **统一尺寸**: 自动调整文档到统一尺寸和对齐
- ⚡ **高性能**: 优化的处理流程，支持大批量文档

### 技术特性
- 🏗️ **MVVM架构**: 采用现代化的架构模式
- 🔄 **响应式编程**: 基于Combine框架的数据流
- 🔒 **隐私保护**: 所有处理在本地完成，无需网络连接
- ⚡ **原生性能**: 纯Swift实现，充分利用Apple硬件优势

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
2. **拖拽文件**: 直接将图片文件拖拽到应用窗口中
3. **自动处理**: 应用会自动开始AI增强处理
4. **查看进度**: 在处理列表中实时查看处理进度
5. **预览结果**: 点击处理完成的文档查看前后对比
6. **导出结果**: 支持单独保存或批量导出为PDF

### 高级功能

- **批量处理**: 同时拖拽多个文件进行批量处理
- **Spotlight搜索**: 处理后的文档自动索引，可通过系统搜索找到
- **快速预览**: 在Finder中按空格键快速预览处理结果
- **统一尺寸**: 批量处理时自动调整到统一的文档尺寸

### 支持的文件格式

- **输入格式**: JPEG (.jpg, .jpeg), PNG (.png), HEIC (.heic), TIFF (.tiff, .tif)
- **输出格式**: JPEG (高质量), PNG (无损), PDF (批量导出)

### 输出文件组织

```
用户文档目录/
├── AIScanEnhance_Output/           # 统一输出目录
│   ├── 2024-01-20/                # 按日期组织
│   │   ├── document_001_enhanced.jpg
│   │   ├── document_002_enhanced.jpg
│   │   └── batch_export.pdf        # 批量导出的PDF
│   └── Spotlight_Index/            # Spotlight索引文件
└── 原始文件保持不变
```

## 技术架构

### 应用架构 (MVVM + SwiftUI)
- **AIScanEnhanceApp.swift**: 应用程序入口和配置
- **ContentView.swift**: 主界面，支持拖拽和文件管理
- **DocumentProcessor.swift**: 核心文档处理器，管理处理流程
- **DocumentItem.swift**: 文档数据模型
- **ProcessingStatus.swift**: 处理状态枚举

### 图像处理模块
- **AdvancedImageProcessor.swift**: 高级图像处理算法
- **ImageEnhancer.swift**: 图像增强和优化
- **VisionDocumentDetector.swift**: 基于Vision框架的文档检测

### macOS集成模块
- **SpotlightIndexer.swift**: Spotlight搜索集成
- **QuickLookPreview.swift**: 快速预览支持
- **DragDropHandler.swift**: 拖拽操作处理

### 核心技术栈

1. **SwiftUI + Combine**: 现代化的UI框架和响应式编程
2. **Vision Framework**: Apple的计算机视觉框架，用于文档检测
3. **Core Image**: 高性能图像处理和滤镜
4. **Core Spotlight**: 系统搜索集成
5. **Quick Look**: 原生预览支持
6. **MVVM架构**: 清晰的数据流和状态管理

## 开发指南

### 项目结构

```
AI-scan-enhance/
├── AIScanEnhance/              # Swift应用源码
│   ├── AIScanEnhanceApp.swift  # 应用程序入口
│   ├── ContentView.swift       # 主界面视图
│   ├── Models/                 # 数据模型
│   │   ├── DocumentItem.swift  # 文档数据模型
│   │   ├── ProcessingStatus.swift # 处理状态枚举
│   │   ├── DocumentProcessor.swift # 核心文档处理器
│   │   └── AdvancedImageProcessor.swift # 高级图像处理
│   ├── Views/                  # 用户界面组件
│   │   ├── DocumentListView.swift # 文档列表视图
│   │   ├── ProcessingView.swift   # 处理进度视图
│   │   └── ResultView.swift       # 结果展示视图
│   ├── Utils/                  # 工具类和扩展
│   │   ├── SpotlightIndexer.swift # Spotlight集成
│   │   ├── QuickLookPreview.swift # 快速预览
│   │   └── DragDropHandler.swift  # 拖拽处理
│   ├── Resources/              # 资源文件
│   │   ├── Assets.xcassets     # 图标和图片资源
│   │   └── Localizable.strings # 本地化字符串
│   ├── AIScanEnhance.entitlements # 应用权限配置
│   └── PrivacyInfo.xcprivacy   # 隐私清单
├── AIScanEnhance.xcodeproj/    # Xcode项目文件
├── ARCHITECTURE.md            # 技术架构文档
├── Scripts/                   # 构建和部署脚本
│   ├── build.sh              # 构建脚本
│   ├── test.sh               # 测试脚本
│   └── deploy.sh             # 部署脚本
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

- **v2.0.0** (当前版本): 全面重构，采用MVVM架构
  - 🏗️ 重新设计应用架构，采用SwiftUI + Combine
  - 🤖 集成Vision框架，提升AI处理能力
  - 🔍 添加Spotlight集成和Quick Look支持
  - 📦 实现高效的批处理和PDF导出功能
  - ✨ 新增反光去除和高级色彩增强
  - 🎨 现代化UI设计，符合macOS设计规范

- **v1.3.0**: 添加App Store合规性支持，纯Swift实现
- **v1.2.0**: 优化UI界面，符合Apple设计规范
- **v1.1.0**: 添加手动校准功能和批量处理
- **v1.0.0**: 初始版本，支持基本的文档扫描和透视矫正

## 联系方式

- 项目主页: [GitHub Repository](https://github.com/your-username/AI-scan-enhance)
- 问题反馈: [Issues](https://github.com/your-username/AI-scan-enhance/issues)

---

**注意**: 这是一个开源项目，仅供学习和研究使用。商业使用请遵循相关许可证条款。
