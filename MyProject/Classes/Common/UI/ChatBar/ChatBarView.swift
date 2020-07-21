//
//  ChatBarView.swift
//  MyProject
//
//  Created by huhsx on 2020/7/21.
//  Copyright © 2020 胡浩三雄. All rights reserved.
//

import UIKit
import RxSwift

public enum ChatFunctionViewShowType: Int {
    /** 不显示functionView */
    case none                   = 1000
    /** 显示键盘 */
    case keyboard               = 1001
    /** 显示表情View */
    case emoji                  = 1002
    /** 显示更多view */
    case more                   = 1003
}

//功能键盘高度
public let FunctionViewHeight: CGFloat = 240.0
//输入框bar高度
public let ChatBarHeight: CGFloat = 54.0

class ChatBarView: UIView {

    public var textView: UITextView!
    
    private var emojiButton: UIButton!
    
    private var moreButton: UIButton!
    
    private var emojiBoardView: ChatBarFaceView!
    
    private var moreBoardView: ChatBarMoreView!
    
    private var textLineHeight: CGFloat = 0.0
    
    private var primeTextHeight: CGFloat = 40.0
    
    private var space: CGFloat = 7.0
    
    private let maxLineCount = 3
    
    private var keyboardFrame: CGRect = .zero
    
    private let disposeBag = DisposeBag()
    
    private let manager = ChatBarDataManager.shared
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = ColorHex("#EFF4F5")
        
        configSubviews()
        
        addNotification()
    }
    
    private func configSubviews() {
        
        // textview
        textView = UITextView()
        textView.backgroundColor = .white
        textView.tintColor = ColorHex("#00CC67")
        textView.textColor = .black
        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.returnKeyType = .send
        textView.enablesReturnKeyAutomatically = true
        textLineHeight = textView.font!.lineHeight
        let height = getStringRectInTextView(string: "Hello", textView: textView).height
        DLog("height = \(height)")
        DLog("textView.textContainerInset = \(textView.textContainerInset)")
        let inset = (40 - height) / 2.0 + 8
        textView.textContainerInset = UIEdgeInsets(top: inset, left: 5, bottom: inset, right: 5)
        textView.frame = CGRect(x: space, y: space, width: bounds.width - space * 3 - 2 * 40, height: 40)
        textView.layer.cornerRadius = 3.0
        textView.layer.masksToBounds = true
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.isScrollEnabled = false
        
        //emojiButton
        emojiButton = UIButton()
        emojiButton.setImage(UIImage(named: "message_expression_n"), for: .normal)
        emojiButton.setImage(UIImage(named: "message_expression_s"), for: .highlighted)
        emojiButton.setImage(UIImage(named: "message_keyboard_n"), for: .selected)
        emojiButton.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        emojiButton.tag = ChatFunctionViewShowType.emoji.rawValue
        
        //moreButton
        moreButton = UIButton()
        moreButton.setImage(UIImage(named: "message_add_n"), for: .normal)
        moreButton.setImage(UIImage(named: "message_add_s"), for: .highlighted)
        moreButton.setImage(UIImage(named: "message_keyboard_n"), for: .selected)
        moreButton.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        moreButton.tag = ChatFunctionViewShowType.more.rawValue
        
        addSubview(textView)
        addSubview(emojiButton)
        addSubview(moreButton)
        
        moreButton.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview().offset(-space)
            make.width.height.equalTo(40)
        }

        emojiButton.snp.makeConstraints { make in
            make.right.equalTo(moreButton.snp.left)
            make.bottom.equalToSuperview().offset(-space)
            make.width.height.equalTo(40)
        }

        //表情键盘
        emojiBoardView = ChatBarFaceView(frame: CGRect(x: 0, y: SCREEN_HEIGHT - FunctionViewHeight, width: SCREEN_WIDTH, height: FunctionViewHeight))
        emojiBoardView.emojiDataArray = manager.emojiDataArray

        //更多view
        moreBoardView = ChatBarMoreView(frame: CGRect(x: 0, y: SCREEN_HEIGHT - FunctionViewHeight, width: SCREEN_WIDTH, height: FunctionViewHeight))

    }

    
    @objc func buttonAction(sender: UIButton) {
        
        var showType: ChatFunctionViewShowType = ChatFunctionViewShowType(rawValue: sender.tag) ?? .none
        
        if sender == emojiButton {
            // 点击emoji
            moreButton.isSelected = false
            emojiButton.isSelected = !emojiButton.isSelected
            
            emojiBoardView.setSendButtonEnable(enable: textView.text.count > 0)
            
        }else if sender == moreButton {
            
            emojiButton.isSelected = false
            moreButton.isSelected = !moreButton.isSelected
        }
        
        if !sender.isSelected {
            showType = ChatFunctionViewShowType.keyboard
        }
        
        showViewWithType(showType: showType)
    }
    
    private func showViewWithType(showType: ChatFunctionViewShowType) {
        
        showFunctionView(view: emojiBoardView, show: showType == .emoji && emojiButton.isSelected)
        showFunctionView(view: moreBoardView, show: showType == .more && moreButton.isSelected)
        
        switch showType {
        case .emoji, .more:
            setViewFrame(frame: CGRect(x: 0, y: SCREEN_HEIGHT - FunctionViewHeight - bounds.height, width: SCREEN_WIDTH, height: bounds.height))
            textView.resignFirstResponder()
        case .keyboard:
            textView.becomeFirstResponder()
        default:
            break
        }
    }
    
    private func showFunctionView(view: UIView, show: Bool) {
        
        if show {
            superview?.addSubview(view)
            view.frame = CGRect(x: 0, y: SCREEN_HEIGHT - FunctionViewHeight, width: SCREEN_WIDTH, height: FunctionViewHeight)
        }else {
            view.removeFromSuperview()
        }
    }
    
    public func setViewFrame(frame: CGRect) {
        
        self.frame = frame
        
        //回调
        //...
    }
    
    /**
    *  根据输入文字计算textView的大小 刷新textview 和 view；
    *  回调改变聊天主界面的tableView 大小。
    */
    private func refreshTextViewSize(textView: UITextView) {
        
        let size = getStringRectInTextView(string: textView.text, textView: textView)
        let maxHeight = primeTextHeight + CGFloat(maxLineCount - 1) * textLineHeight
        
        //复制文字时的处理，先直接改textview
        if size.height > maxHeight {
            
            let frame = textView.frame
            textView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: maxHeight)
            
            let chatBarHeight = textView.bounds.height + 2 * space
            
            if emojiButton.isSelected {
                //如果是点击表情键盘输入的情况下
                self.frame = CGRect(x: 0, y: SCREEN_HEIGHT - FunctionViewHeight - chatBarHeight, width: SCREEN_WIDTH, height: chatBarHeight)
            }else {
                self.frame = CGRect(x: 0, y: SCREEN_HEIGHT - keyboardFrame.size.height - chatBarHeight, width: SCREEN_WIDTH, height: chatBarHeight)
            }
            
            textView.isScrollEnabled = true
            
            setNeedsLayout()
            layoutIfNeeded()
            
            //回调
            //...
        }
        
        DLog("textView.bounds.height = \(textView.bounds.height)")
        DLog("size.height = \(size.height)")
        
        if size.height > textView.bounds.height {
            // 文字的实际高度已经超过了输入框，需要变大
            if size.height < maxHeight {
                //如果还没到达最大行数
                textView.isScrollEnabled = false
                DLog("高度改变 刷新")
                
                UIView.animate(withDuration: 0.25, animations: {
                    
                    self.frame = CGRect(x: self.frame.origin.x,
                                        y: self.frame.origin.y - size.height + textView.bounds.height,
                                        width: self.bounds.width,
                                        height: size.height + 2 * self.space)
                    let frame = textView.frame
                    textView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: size.height)
                    
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                    
                }) { _ in
                    //回调
                    //...
                }
            }else {
                //已经到达最大行数
                textView.isScrollEnabled = true
            }
            
        }else if textView.frame.size.height > size.height {
            
            UIView.animate(withDuration: 0.25, animations: {
                
                self.frame = CGRect(x: self.frame.origin.x,
                                    y: self.frame.origin.y - size.height + textView.bounds.height,
                                    width: self.bounds.width,
                                    height: size.height + 2 * self.space)
                let frame = textView.frame
                textView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: size.height)
                
                self.setNeedsLayout()
                self.layoutIfNeeded()
                
            }) { _ in
                //回调
                //...
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - UITextViewDelegate
extension ChatBarView: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        emojiButton.isSelected = false
        moreButton.isSelected = false
        
        showFunctionView(view: emojiBoardView, show: false)
        showFunctionView(view: moreBoardView, show: false)
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let selectedRange = textView.markedTextRange
        //获取高亮部分
        let pos = textView.position(from: selectedRange?.start ?? UITextPosition(), offset: 0)
        
        if selectedRange != nil && pos != nil {
            return
        }
        
        refreshTextViewSize(textView: textView)
        
        emojiBoardView.setSendButtonEnable(enable: textView.text.count > 0)
    }
}

// MARK: - Private
extension ChatBarView {
    
    /// 键盘通知
    private func addNotification() {
        
        NotificationCenter
            .default
            .rx
            .notification(UIResponder.keyboardWillShowNotification)
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: { [weak self] (notification) in
                
                guard let s = self else { return }
                
                guard let userInfo = notification.userInfo else { return }
                guard var keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                s.keyboardFrame = keyboardRect
                
                guard let superview = s.superview else { return }
                keyboardRect = superview.convert(keyboardRect, from: nil)
                
                //根据老的 frame 设定新的 frame
                var newTextViewFrame = s.frame
                newTextViewFrame.origin.y = keyboardRect.origin.y - s.frame.size.height
                
                //键盘的动画时间，设定与其完全保持一致
                let animationDurationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSValue
                var animationDuration: TimeInterval = 0
                animationDurationValue?.getValue(&animationDuration)
                
                //键盘的动画是变速的，设定与其完全保持一致
                let animationCurveObjectValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSValue
                var animationCurve: Int = 0
                animationCurveObjectValue?.getValue(&animationCurve)
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: animationCurve)!)
                
                s.setViewFrame(frame: newTextViewFrame)
                
                UIView.commitAnimations()
                
            }).disposed(by: disposeBag)
        
        NotificationCenter
            .default
            .rx
            .notification(UIResponder.keyboardWillHideNotification)
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: { [weak self] (notification) in
                
                guard let s = self else { return }
                
                guard let userInfo = notification.userInfo else { return }
                s.keyboardFrame = .zero
                
                //键盘的动画时间，设定与其完全保持一致
                let animationDurationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSValue
                var animationDuration: TimeInterval = 0
                animationDurationValue?.getValue(&animationDuration)
                
                //键盘的动画是变速的，设定与其完全保持一致
                let animationCurveObjectValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSValue
                var animationCurve: Int = 0
                animationCurveObjectValue?.getValue(&animationCurve)
                
                var newTextViewFrame = s.frame
                
                if s.emojiButton.isSelected || s.moreButton.isSelected {
                    newTextViewFrame.origin.y = SCREEN_HEIGHT - FunctionViewHeight - s.bounds.height
                }else {
                    newTextViewFrame.origin.y = SCREEN_HEIGHT - s.bounds.height
                }
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: animationCurve)!)
                
                s.setViewFrame(frame: newTextViewFrame)
                
                UIView.commitAnimations()
                
            }).disposed(by: disposeBag)
        
    }
    
    /// 计算textView size
    /// - Parameters:
    ///   - string: 字符串
    ///   - textView: textView
    /// - Returns: size
    func getStringRectInTextView(string: String = "", textView: UITextView) -> CGSize {
        
        //实际textView显示时我们设定的宽
        var contentWidth = textView.frame.width
        //但事实上内容需要除去显示的边框值
        let broadWidth = (textView.contentInset.left + textView.contentInset.right
            + textView.textContainerInset.left
            + textView.textContainerInset.right
            + textView.textContainer.lineFragmentPadding/*左边距*/
            + textView.textContainer.lineFragmentPadding/*右边距*/)
        
        let broadHeight = (textView.contentInset.top
            + textView.contentInset.bottom
            + textView.textContainerInset.top
            + textView.textContainerInset.bottom)
        
        //由于求的是普通字符串产生的Rect来适应textView的宽
        contentWidth -= broadWidth
        
        let inSize = CGSize(width: contentWidth, height: CGFloat(MAXFLOAT))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = textView.textContainer.lineBreakMode
        let dic = [NSAttributedString.Key.font: textView.font!, NSAttributedString.Key.paragraphStyle: paragraphStyle.copy()]
        
        let calculatedSize = NSString(string: string).boundingRect(with: inSize, options: [NSStringDrawingOptions.usesLineFragmentOrigin, NSStringDrawingOptions.usesFontLeading], attributes: dic, context: nil).size
        
        let adjustSize = CGSize(width: CGFloat(ceil(Double(calculatedSize.width))), height: calculatedSize.height + broadHeight)
        
        return adjustSize
    }
    
    
}
