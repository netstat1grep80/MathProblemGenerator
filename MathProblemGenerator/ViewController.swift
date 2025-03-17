//
//  ViewController.swift
//  MathProblemGenerator
//
//  Created by laozhang on 2025/3/14.
//

import Cocoa
import Quartz

class ViewController: NSViewController {

    @IBOutlet weak var scrollableTextView: NSScrollView!
    
    @IBOutlet weak var textFontSizeField: NSTextField!
    
    @IBOutlet weak var textFontLineSpacingField: NSTextField!
    
    @IBOutlet weak var operationalRangeField: NSTextField!
    
    @IBOutlet weak var questionNumbersField: NSTextField!
    
    @IBOutlet weak var addSlider: NSSlider!
    
    @IBOutlet weak var addSliderLabed: NSTextField!
    
    @IBOutlet weak var btnGenerateProblems: NSButton!
    
    private var fontFamily:String = "Courier"
    
    
    var addSliderRate:Double = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        scrollableTextView.hasVerticalScroller = true
        scrollableTextView.hasHorizontalScroller = false
        scrollableTextView.autohidesScrollers = false // 滚动条始终显示
        
        addSlider.target = self
        addSlider.action = #selector(sliderValueChanged(_:))
        addSlider.isContinuous = true
        
    }
    
    override func viewWillAppear() {
            super.viewWillAppear()
            // 将焦点设置到 printButton
            view.window?.makeFirstResponder(btnGenerateProblems)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @objc func sliderValueChanged(_ sender: NSSlider) {
            self.addSliderRate  = sender.doubleValue // 获取当前滑块值
            let formattedString = String(format: "%.0f%%", self.addSliderRate * 100)
            self.addSliderLabed.stringValue = formattedString
            // 你可以在这里处理值的变化，例如更新 UI 或执行其他逻辑
    }
    
    @IBAction func printButtonClicked(_ sender: Any) {
        guard let textView = scrollableTextView.documentView as? NSTextView else {
                    showAlert(message: "错误：无法获取文本视图")
                    return
                }
                
                let textContent = textView.string
                if textContent.isEmpty {
                    showAlert(message: "错误：没有内容可打印")
                    return
                }
                
                // 创建打印操作
                let printInfo = NSPrintInfo.shared // 获取默认打印设置
                let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
                
                // 可选：自定义打印设置
                printInfo.horizontalPagination = .fit // 水平适应页面
                printInfo.verticalPagination = .automatic // 垂直自动分页
                printInfo.isHorizontallyCentered = true // 水平居中
                printInfo.isVerticallyCentered = false // 垂直不居中（从顶部开始）
                
                // 运行打印操作
                printOperation.run()
    }
    
    @IBAction func generateProblems(_ sender: Any) {
        // 生成 60 道题
        let problems = generateProblems(totalProblems: getQuestionNumbers(), maxNumber: getOperationalRange(), additionProbability: self.addSliderRate)
            
        print("题目数量：\(getQuestionNumbers()),运算范围:\(getOperationalRange()),加法题比例:\(self.addSliderRate),字体大小:\(getFontSize()),字体行距:\(getFontLineSpacing())")
            // 格式化题目
            let formattedText = formatProblems(problems: problems)
            
            // 更新 Scrollable Text View 的内容
            if let textView = scrollableTextView.documentView as? NSTextView {
                textView.string = formattedText
                
                
                let fontSize = self.getFontSize()
                // 设置字体大小
                textView.font = NSFont.systemFont(ofSize: fontSize)
                // 设置等宽字体
                if let textView = scrollableTextView.documentView as? NSTextView {
                    textView.font = NSFont(name: self.fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
                }
                
                
                // 设置行间距
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = self.getFontLineSpacing()
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: textView.font as Any,
                    .paragraphStyle: paragraphStyle
                ]
                
                if let currentText = textView.textStorage {
                    currentText.setAttributes(attributes, range: NSRange(location: 0, length: currentText.length))
                }
            }
    }
    

    @IBAction func savePDF(_ sender: Any) {
        guard let textView = self.scrollableTextView.documentView as? NSTextView else {
                showAlert(message: "错误：试卷上没有任何题目[1]")
                return
            }
            
            let textContent = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if textContent.isEmpty {
                showAlert(message: "错误：试卷上没有任何题目[2]")
                return
            }
        
        
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["pdf"]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        savePanel.nameFieldStringValue = "\(timestamp)"
        
        savePanel.canCreateDirectories = true
        
        savePanel.begin { (result) in
            if result == .OK, let url = savePanel.url {
                let pdfData = NSMutableData()
                guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData),
                      let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: nil, nil) else {
                    self.showAlert(message: "无法创建 PDF 上下文")
                    return
                }
                
                var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
                pdfContext.beginPage(mediaBox: &mediaBox)
                
                // 从 NSTextView 获取文本
                var pdfContent = "Test PDF 保存功能" // 默认文本
                if let textView = self.scrollableTextView.documentView as? NSTextView {
                    pdfContent = textView.string
                }
                
             
                let fontSize = self.getFontSize()
                let lineHeight = fontSize + self.getFontLineSpacing() // 总行高 = 字体大小 + 额外间距
                
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont(name: self.fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize),
                    .foregroundColor: NSColor.black
                ]
                
                // 按换行符分割文本
                let lines = pdfContent.components(separatedBy: .newlines)
                var yPosition = mediaBox.height - 50 // 从顶部开始
                
                // 逐行绘制
                for lineText in lines {
                    if !lineText.isEmpty { // 忽略空行
                        let attributedText = NSAttributedString(string: lineText, attributes: attributes)
                        let line = CTLineCreateWithAttributedString(attributedText)
                        
                        pdfContext.saveGState()
                        pdfContext.textPosition = CGPoint(x: 50, y: yPosition)
                        pdfContext.setTextDrawingMode(.fill)
                        CTLineDraw(line, pdfContext)
                        pdfContext.restoreGState()
                        
                        yPosition -= lineHeight // 每行向下移动 30 点，可以根据字体大小调整
                    } else {
                        yPosition -= lineHeight // 空行也占位
                    }
                }
                
                pdfContext.endPage()
                pdfContext.closePDF()
                
                do {
                    try pdfData.write(to: url)
                    print("PDF 已保存到: \(url.path)")
                    DispatchQueue.main.async {
                        self.showAlert(message: "PDF 已成功保存到 \(url.path)")
                    }
                } catch {
                    print("保存 PDF 失败: \(error)")
                    DispatchQueue.main.async {
                        self.showAlert(message: "保存 PDF 失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // 生成加减法题目
    func generateProblems(totalProblems: Int, maxNumber: Int, additionProbability: Double) -> [String] {
        
            var problems: [String] = []
            let totalAddition = Int(Double(totalProblems) * additionProbability)
            
            // 生成加法题目
            for _ in 0..<totalAddition {
                var a = Int.random(in: 2...9)
                var b = Int.random(in: 2...20 - a) // 确保 a + b >= 10
                
                // 确保 a 总是大于等于 b
                if a < b {
                   (a, b) = (b, a)
                }
                
                let formattedA = a.padded(toLength: 2, after: true) // 在数字后面添加空格
                let formattedB = b.padded(toLength: 2, after: true)
                
                // 使用制表符或空格分隔，根据需要选择
                let problemString = "\(formattedA) + \(formattedB) = "
                
                problems.append(problemString)
            }
            
            // 生成减法题目
            for _ in 0..<(totalProblems - totalAddition) {
                let a = Int.random(in: 11...20)
                let b = Int.random(in: 2...9) // 确保需要退位
                
                let formattedA = a.padded(toLength: 2, after: true) // 在数字后面添加空格
                let formattedB = b.padded(toLength: 2, after: true)
                
                // 使用制表符或空格分隔，根据需要选择
                let problemString = "\(formattedA) - \(formattedB) = "
                
                problems.append(problemString)
                
            }
            
            // 打乱题目顺序
            problems.shuffle()
            return problems
    }
        
    // 格式化题目为每行三道题
    func formatProblems(problems: [String]) -> String {
        var formattedText = ""
            for (index, problem) in problems.enumerated() {
                formattedText += problem
                
                // 每行显示三道题
                if (index + 1) % 3 == 0 && index != problems.count - 1 {
                    formattedText += "\n" // 换行
                } else if (index + 1) % 3 != 0 && index != problems.count - 1 {
                    formattedText += "   " // 题目之间用空格分隔
                }
            }
            return formattedText
    }
    
    
    

    // 辅助方法，用于显示提示框
    func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "提示"
        alert.informativeText = message
        alert.alertStyle = .informational // 修改这里
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    func getFontSize() -> CGFloat{
        // 获取 NSTextField 的字符串值
        let textSizeValue = self.textFontSizeField.stringValue
        var fontSize = CGFloat(12)
        // 将字符串转换为 CGFloat
        if let doubleValue = Double(textSizeValue) {
            fontSize = CGFloat(doubleValue)
        } else {
            print("FontSize Convert error:\(textSizeValue)")
        }
        return fontSize
    }
    
    func getFontLineSpacing() -> CGFloat{
        // 获取行间距
        let textLineValue = textFontLineSpacingField.stringValue
        var fontLineSpacing = CGFloat(24)
        // 将字符串转换为 CGFloat
        if let doubleLineValue = Double(textLineValue) {
            fontLineSpacing = CGFloat(doubleLineValue)
        } else {
            print("LineSpacing Convert error \(textLineValue)")
        }
        return fontLineSpacing
    }
    
    //获取运算范围，默认20
    func getOperationalRange() -> Int{
        // 获取行间距
        let strValue = operationalRangeField.stringValue
        var intValue = Int(20)
        // 将字符串转换为 CGFloat
        if Int(strValue) != nil {
            intValue = Int(strValue) ?? intValue
        } else {
            print("getOperationalRange Convert error \(strValue)")
        }
        return intValue
    }
    
    //获取运算范围，默认20
    func getQuestionNumbers() -> Int{
        // 获取行间距
        let strValue = questionNumbersField.stringValue
        var intValue = Int(60)
        // 将字符串转换为 CGFloat
        if Int(strValue) != nil {
            intValue = Int(strValue) ?? intValue
        } else {
            showAlert(message:"设置题目数量时发生错误：\(strValue)")
        }
        return intValue
    }
    
    func getAddSlider() -> Double{
        // 获取行间距
        let strValue = addSlider.stringValue
        var dbValue = Double(0.5)
        if Double(strValue) != nil {
            dbValue = Double(strValue) ?? dbValue
        } else {
            showAlert(message: "设置加法题比例时发生错误：\(strValue)")
        }
        return dbValue
    }


}
