/****************************************************************************
 Copyright (c) 2010-2012 cocos2d-x.org
 Copyright (c) 2012 James Chen
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/
#include "UIEditBoxImpl-ios.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)

#define kLabelZOrder  9999
#include "cocos2d.h"
#include "UIEditBox.h"
#include "base/CCDirector.h"
#include "2d/CCLabel.h"
#import "platform/ios/CCEAGLView-ios.h"

#define getEditBoxImplIOS() ((cocos2d::ui::EditBoxImplIOS*)editBox_)

@implementation UIView (LQXkeyboard)
- (void)setX:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)setY:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)x
{
    return self.frame.origin.x;
}

- (CGFloat)y
{
    return self.frame.origin.y;
}

- (void)setCenterX:(CGFloat)centerX
{
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

- (CGFloat)centerX
{
    return self.center.x;
}

- (void)setCenterY:(CGFloat)centerY
{
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setSize:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGSize)size
{
    return self.frame.size;
}

- (void)setOrigin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGPoint)origin
{
    return self.frame.origin;
}

@end

static const int CC_EDIT_BOX_PADDING = 5;

@implementation UICustomUITextField
- (CGRect)textRectForBounds:(CGRect)bounds
{
    auto glview = cocos2d::Director::getInstance()->getOpenGLView();

    float padding = CC_EDIT_BOX_PADDING * glview->getScaleX() / glview->getContentScaleFactor();
    return CGRectMake(bounds.origin.x + padding, bounds.origin.y + padding,
                      bounds.size.width - padding*2, bounds.size.height - padding*2);
}
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}
@end


@implementation UIEditBoxImplIOS_objc

@synthesize textField = textField_;
@synthesize editState = editState_;
@synthesize editBox = editBox_;
@synthesize critiqueView = critiqueView_;
- (void)dealloc
{
    [textField_ resignFirstResponder];
//    [textField_ removeFromSuperview];
    [critiqueView_ removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    self.textField = NULL;
    self.critiqueView = NULL;
    [super dealloc];
}

-(id) initWithFrame: (CGRect) frameRect editBox: (void*) editBox
{
    self = [super init];
    
    if (self)
    {
        editState_ = NO;
        cocos2d::Size size = cocos2d::Director::getInstance()->getVisibleSize();
        auto view = cocos2d::Director::getInstance()->getOpenGLView();
        CGRect rect = CGRectMake(0, 0, size.width * view->getScaleX(),size.height * view->getScaleY());
        
        CCEAGLView *eaglview = static_cast<CCEAGLView *>(view->getEAGLView());
        float factor = eaglview.contentScaleFactor;
        rect.size.width /= factor;
        rect.size.height /= factor;
        
        self.critiqueView = [[UIView alloc] initWithFrame:CGRectMake(0, rect.size.height - 40, rect.size.width, 40)];
        self.critiqueView.backgroundColor =[UIColor colorWithRed:1 green:1 blue:1 alpha:0.85];
//        [self.view addSubview:self.critiqueView];
        
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 5, rect.size.width - 70, 30)];
        self.textField.borderStyle = UITextBorderStyleRoundedRect;
        self.textField.backgroundColor = [UIColor whiteColor];
        self.textField.placeholder = @"Auther:ArcherPeng";
        self.textField.font = [UIFont fontWithName:@"Arial" size:13.0f];
        self.textField.clearButtonMode = UITextFieldViewModeAlways;
        self.textField.returnKeyType = UIReturnKeyGo;
        self.textField.delegate = self;
        [textField_ addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];
        [self.critiqueView addSubview:self.textField];
        self.editBox = editBox;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(rect.size.width - 50, 5, 40, 30);
        [button setTitle:@"Done" forState:0];
        [button setTitleColor:[UIColor colorWithRed:254/255.0 green:124/255.0 blue:148/255.0 alpha:1] forState:0];
        [self.critiqueView  addSubview:button];
        button.titleLabel.font = [UIFont  fontWithName : @"Helvetica-Bold" size:14];
        [button addTarget:self action:@selector(sendMess) forControlEvents:UIControlEventTouchUpInside];
        
        
        
        [[NSNotificationCenter
          defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:)
         name:UIKeyboardWillChangeFrameNotification object:nil];//在这里注册通知
    }
    
    return self;
}
- (void)sendMess
{
//    NSLog(@"Send");
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
    [self.critiqueView removeFromSuperview];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    //    if (self.picking) return;
    /**
     notification.userInfo = @{
     // 键盘弹出\隐藏后的frame
     UIKeyboardFrameEndUserInfoKey = NSRect: {{0, 352}, {320, 216}},
     // 键盘弹出\隐藏所耗费的时间
     UIKeyboardAnimationDurationUserInfoKey = 0.25,
     // 键盘弹出\隐藏动画的执行节奏（先快后慢，匀速）
     UIKeyboardAnimationCurveUserInfoKey = 7
     }
     */
    
    NSDictionary *userInfo = notification.userInfo;
    
    // 动画的持续时间
    double duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // 键盘的frame
    CGRect keyboardF = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // 执行动画
    [UIView animateWithDuration:duration animations:^{
        // 工具条的Y值 == 键盘的Y值 - 工具条的高度
        cocos2d::Size size = cocos2d::Director::getInstance()->getVisibleSize();
        auto view = cocos2d::Director::getInstance()->getOpenGLView();
        CGRect rect = CGRectMake(0, 0, size.width * view->getScaleX(),size.height * view->getScaleY());
        
        CCEAGLView *eaglview = static_cast<CCEAGLView *>(view->getEAGLView());
        float factor = eaglview.contentScaleFactor;
        rect.size.width /= factor;
        rect.size.height /= factor;
        
        if (keyboardF.origin.y >rect.size.height) { // 键盘的Y值已经远远超过了控制器view的高度
        
            critiqueView_.y = rect.size.height - critiqueView_.height;//这里的<span style="background-color: rgb(240, 240, 240);">self.toolbar就是我的输入框。</span>
            
        } else {
            critiqueView_.y = keyboardF.origin.y - critiqueView_.height;
        }
    }];
}


-(void) doAnimationWhenKeyboardMoveWithDuration:(float)duration distance:(float)distance
{
    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    CCEAGLView *eaglview = (CCEAGLView *) view->getEAGLView();

    [eaglview doAnimationWhenKeyboardMoveWithDuration:duration distance:distance];
}

-(void) setPosition:(CGPoint) pos
{
//    CGRect frame = [textField_ frame];
//    frame.origin = pos;
//    [textField_ setFrame:frame];
}

-(void) setContentSize:(CGSize) size
{
//    CGRect frame = [textField_ frame];
//    frame.size = size;
//    [textField_ setFrame:frame];
}

-(void) visit
{
    
}

-(void) openKeyboard
{
    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    CCEAGLView *eaglview = (CCEAGLView *) view->getEAGLView();

    [eaglview addSubview:critiqueView_];
    [textField_ becomeFirstResponder];
}

-(void) closeKeyboard
{
    [textField_ resignFirstResponder];
    [critiqueView_ removeFromSuperview];
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    if (sender == textField_) {
        [sender resignFirstResponder];
        [critiqueView_ removeFromSuperview];
    }
    return NO;
}

-(void)animationSelector
{
    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    CCEAGLView *eaglview = (CCEAGLView *) view->getEAGLView();

    [eaglview doAnimationWhenAnotherEditBeClicked];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)sender        // return NO to disallow editing.
{
    editState_ = YES;

    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    CCEAGLView *eaglview = (CCEAGLView *) view->getEAGLView();

    if ([eaglview isKeyboardShown])
    {
        [self performSelector:@selector(animationSelector) withObject:nil afterDelay:0.0f];
    }
    cocos2d::ui::EditBoxDelegate* pDelegate = getEditBoxImplIOS()->getDelegate();
    if (pDelegate != NULL)
    {
        pDelegate->editBoxEditingDidBegin(getEditBoxImplIOS()->getEditBox());
    }
    
#if CC_ENABLE_SCRIPT_BINDING
    cocos2d::ui::EditBox*  pEditBox= getEditBoxImplIOS()->getEditBox();
    if (NULL != pEditBox && 0 != pEditBox->getScriptEditBoxHandler())
    {        
        cocos2d::CommonScriptData data(pEditBox->getScriptEditBoxHandler(), "began",pEditBox);
        cocos2d::ScriptEvent event(cocos2d::kCommonEvent,(void*)&data);
        cocos2d::ScriptEngineManager::getInstance()->getScriptEngine()->sendEvent(&event);
    }
#endif
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)sender
{
    editState_ = NO;
    getEditBoxImplIOS()->refreshInactiveText();
    
    cocos2d::ui::EditBoxDelegate* pDelegate = getEditBoxImplIOS()->getDelegate();
    if (pDelegate != NULL)
    {
        pDelegate->editBoxEditingDidEnd(getEditBoxImplIOS()->getEditBox());
        pDelegate->editBoxReturn(getEditBoxImplIOS()->getEditBox());
    }
    
#if CC_ENABLE_SCRIPT_BINDING
    cocos2d::ui::EditBox*  pEditBox= getEditBoxImplIOS()->getEditBox();
    if (NULL != pEditBox && 0 != pEditBox->getScriptEditBoxHandler())
    {
        cocos2d::CommonScriptData data(pEditBox->getScriptEditBoxHandler(), "ended",pEditBox);
        cocos2d::ScriptEvent event(cocos2d::kCommonEvent,(void*)&data);
        cocos2d::ScriptEngineManager::getInstance()->getScriptEngine()->sendEvent(&event);
        memset(data.eventName, 0, sizeof(data.eventName));
        strncpy(data.eventName, "return", sizeof(data.eventName));
        event.data = (void*)&data;
        cocos2d::ScriptEngineManager::getInstance()->getScriptEngine()->sendEvent(&event);
    }
#endif
    
	if(editBox_ != nil)
	{
		getEditBoxImplIOS()->onEndEditing();
	}
    return YES;
}

/**
 * Delegate method called before the text has been changed.
 * @param textField The text field containing the text.
 * @param range The range of characters to be replaced.
 * @param string The replacement string.
 * @return YES if the specified text range should be replaced; otherwise, NO to keep the old text.
 */
- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (getEditBoxImplIOS()->getMaxLength() < 0)
    {
        return YES;
    }
    
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    return newLength <= getEditBoxImplIOS()->getMaxLength();
}

/**
 * Called each time when the text field's text has changed.
 */
- (void) textChanged
{
    // NSLog(@"text is %@", self.textField.text);
    cocos2d::ui::EditBoxDelegate* pDelegate = getEditBoxImplIOS()->getDelegate();
    if (pDelegate != NULL)
    {
        pDelegate->editBoxTextChanged(getEditBoxImplIOS()->getEditBox(), getEditBoxImplIOS()->getText());
    }
    
#if CC_ENABLE_SCRIPT_BINDING
    cocos2d::ui::EditBox*  pEditBox= getEditBoxImplIOS()->getEditBox();
    if (NULL != pEditBox && 0 != pEditBox->getScriptEditBoxHandler())
    {
        cocos2d::CommonScriptData data(pEditBox->getScriptEditBoxHandler(), "changed",pEditBox);
        cocos2d::ScriptEvent event(cocos2d::kCommonEvent,(void*)&data);
        cocos2d::ScriptEngineManager::getInstance()->getScriptEngine()->sendEvent(&event);
    }
#endif
}

@end


NS_CC_BEGIN

namespace ui {

EditBoxImpl* __createSystemEditBox(EditBox* pEditBox)
{
    return new EditBoxImplIOS(pEditBox);
}

EditBoxImplIOS::EditBoxImplIOS(EditBox* pEditText)
: EditBoxImpl(pEditText)
, _label(nullptr)
, _labelPlaceHolder(nullptr)
, _anchorPoint(Vec2(0.5f, 0.5f))
, _systemControl(nullptr)
, _maxTextLength(-1)
{
}

EditBoxImplIOS::~EditBoxImplIOS()
{
    [_systemControl release];
}

void EditBoxImplIOS::doAnimationWhenKeyboardMove(float duration, float distance)
{
    //目前显示效果，不需要在移动画面了
//    if ([_systemControl isEditState] || distance < 0.0f)
//    {
//        [_systemControl doAnimationWhenKeyboardMoveWithDuration:duration distance:distance];
//    }
}

bool EditBoxImplIOS::initWithSize(const Size& size)
{
    do 
    {
        auto glview = cocos2d::Director::getInstance()->getOpenGLView();

        CGRect rect = CGRectMake(0, 0, size.width * glview->getScaleX(),size.height * glview->getScaleY());

        CCEAGLView *eaglview = static_cast<CCEAGLView *>(glview->getEAGLView());
        float factor = eaglview.contentScaleFactor;
        rect.size.width /= factor;
        rect.size.height /= factor;
        
        _systemControl = [[UIEditBoxImplIOS_objc alloc] initWithFrame:rect editBox:this];
        if (!_systemControl) break;
        
		initInactiveLabels(size);
        setContentSize(size);
		
        return true;
    }while (0);
    
    return false;
}

void EditBoxImplIOS::initInactiveLabels(const Size& size)
{
	const char* pDefaultFontName = [[_systemControl.textField.font fontName] UTF8String];

	_label = Label::create();
    _label->setAnchorPoint(Vec2(0, 0.5f));
    _label->setColor(Color3B::WHITE);
    _label->setVisible(false);
    _editBox->addChild(_label, kLabelZOrder);
	
    _labelPlaceHolder = Label::create();
	// align the text vertically center
    _labelPlaceHolder->setAnchorPoint(Vec2(0, 0.5f));
    _labelPlaceHolder->setColor(Color3B::GRAY);
    _editBox->addChild(_labelPlaceHolder, kLabelZOrder);
    
    setFont(pDefaultFontName, size.height*2/3);
    setPlaceholderFont(pDefaultFontName, size.height*2/3);
}

void EditBoxImplIOS::placeInactiveLabels()
{
    _label->setPosition(CC_EDIT_BOX_PADDING, _contentSize.height / 2.0f);
    _labelPlaceHolder->setPosition(CC_EDIT_BOX_PADDING, _contentSize.height / 2.0f);
}

void EditBoxImplIOS::setInactiveText(const char* pText)
{
    if(_systemControl.textField.secureTextEntry == YES)
    {
        std::string passwordString;
        for(int i = 0; i < strlen(pText); ++i)
            passwordString.append("\u25CF");
        _label->setString(passwordString.c_str());
    }
    else
        _label->setString(getText());

    // Clip the text width to fit to the text box
    float fMaxWidth = _editBox->getContentSize().width - CC_EDIT_BOX_PADDING * 2;
    Size labelSize = _label->getContentSize();
    if(labelSize.width > fMaxWidth) {
        _label->setDimensions(fMaxWidth,labelSize.height);
    }
}

void EditBoxImplIOS::setFont(const char* pFontName, int fontSize)
{
    bool isValidFontName = true;
	if(pFontName == NULL || strlen(pFontName) == 0) {
        isValidFontName = false;
    }

    CCEAGLView *eaglview = static_cast<CCEAGLView *>(cocos2d::Director::getInstance()->getOpenGLView()->getEAGLView());
    float retinaFactor = eaglview.contentScaleFactor;
	NSString * fntName = [NSString stringWithUTF8String:pFontName];

    auto glview = cocos2d::Director::getInstance()->getOpenGLView();

    float scaleFactor = glview->getScaleX();
    UIFont *textFont = nil;
    if (isValidFontName) {
        textFont = [UIFont fontWithName:fntName size:fontSize * scaleFactor / retinaFactor];
    }
    
    if (!isValidFontName || textFont == nil){
        textFont = [UIFont systemFontOfSize:fontSize * scaleFactor / retinaFactor];
    }

//	if(textFont != nil) {
//		[_systemControl.textField setFont:textFont];
//    }

	_label->setSystemFontName(pFontName);
	_label->setSystemFontSize(fontSize);
}

void EditBoxImplIOS::setFontColor(const Color4B& color)
{
//    _systemControl.textField.textColor = [UIColor colorWithRed:color.r / 255.0f green:color.g / 255.0f blue:color.b / 255.0f alpha:color.a / 255.f];
	_label->setTextColor(color);
}

void EditBoxImplIOS::setPlaceholderFont(const char* pFontName, int fontSize)
{
	_labelPlaceHolder->setSystemFontName(pFontName);
	_labelPlaceHolder->setSystemFontSize(fontSize);
}
    
void EditBoxImplIOS::setPlaceholderFontColor(const Color4B &color)
{
    _labelPlaceHolder->setTextColor(color);
}

void EditBoxImplIOS::setInputMode(EditBox::InputMode inputMode)
{
    switch (inputMode)
    {
        case EditBox::InputMode::EMAIL_ADDRESS:
            _systemControl.textField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        case EditBox::InputMode::NUMERIC:
            _systemControl.textField.keyboardType = UIKeyboardTypeDecimalPad;
            break;
        case EditBox::InputMode::PHONE_NUMBER:
            _systemControl.textField.keyboardType = UIKeyboardTypePhonePad;
            break;
        case EditBox::InputMode::URL:
            _systemControl.textField.keyboardType = UIKeyboardTypeURL;
            break;
        case EditBox::InputMode::DECIMAL:
            _systemControl.textField.keyboardType = UIKeyboardTypeDecimalPad;
            break;
        case EditBox::InputMode::SINGLE_LINE:
            _systemControl.textField.keyboardType = UIKeyboardTypeDefault;
            break;
        default:
            _systemControl.textField.keyboardType = UIKeyboardTypeDefault;
            break;
    }
}

void EditBoxImplIOS::setMaxLength(int maxLength)
{
    _maxTextLength = maxLength;
}

int EditBoxImplIOS::getMaxLength()
{
    return _maxTextLength;
}

void EditBoxImplIOS::setInputFlag(EditBox::InputFlag inputFlag)
{
    switch (inputFlag)
    {
        case EditBox::InputFlag::PASSWORD:
            _systemControl.textField.secureTextEntry = YES;
            break;
        case EditBox::InputFlag::INITIAL_CAPS_WORD:
            _systemControl.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            break;
        case EditBox::InputFlag::INITIAL_CAPS_SENTENCE:
            _systemControl.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            break;
        case EditBox::InputFlag::INTIAL_CAPS_ALL_CHARACTERS:
            _systemControl.textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            break;
        case EditBox::InputFlag::SENSITIVE:
            _systemControl.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            break;
        default:
            break;
    }
    setText([_systemControl.textField.text UTF8String]);
}

void EditBoxImplIOS::setReturnType(EditBox::KeyboardReturnType returnType)
{
    switch (returnType) {
        case EditBox::KeyboardReturnType::DEFAULT:
            _systemControl.textField.returnKeyType = UIReturnKeyDefault;
            break;
        case EditBox::KeyboardReturnType::DONE:
            _systemControl.textField.returnKeyType = UIReturnKeyDone;
            break;
        case EditBox::KeyboardReturnType::SEND:
            _systemControl.textField.returnKeyType = UIReturnKeySend;
            break;
        case EditBox::KeyboardReturnType::SEARCH:
            _systemControl.textField.returnKeyType = UIReturnKeySearch;
            break;
        case EditBox::KeyboardReturnType::GO:
            _systemControl.textField.returnKeyType = UIReturnKeyGo;
            break;
        default:
            _systemControl.textField.returnKeyType = UIReturnKeyDefault;
            break;
    }
}

bool EditBoxImplIOS::isEditing()
{
    return [_systemControl isEditState] ? true : false;
}

void EditBoxImplIOS::refreshInactiveText()
{
    const char* text = getText();
    if(_systemControl.textField.hidden == YES)
    {
		setInactiveText(text);
		if(strlen(text) == 0)
		{
//            _label->setString("");
			_label->setVisible(false);
			_labelPlaceHolder->setVisible(true);
		}
		else
		{
			_label->setVisible(true);
			_labelPlaceHolder->setVisible(false);
		}
	}
}

void EditBoxImplIOS::setText(const char* text)
{
    NSString* nsText =[NSString stringWithUTF8String:text];
    if ([nsText compare:_systemControl.textField.text] != NSOrderedSame)
    {
        _systemControl.textField.text = nsText;
        if(_systemControl.textField.secureTextEntry == YES)
        {
            std::string passwordString;
            for(int i = 0; i < strlen([nsText UTF8String]); ++i)
                passwordString.append("\u25CF");
            _label->setString(passwordString.c_str());
        }
        else
        {
            _label->setString([nsText UTF8String]);
        }
        _label->setVisible(true);
    }
    
    refreshInactiveText();
}

NSString* removeSiriString(NSString* str)
{
    NSString* siriString = @"\xef\xbf\xbc";
    return [str stringByReplacingOccurrencesOfString:siriString withString:@""];
}

const char*  EditBoxImplIOS::getText(void)
{
    return [removeSiriString(_systemControl.textField.text) UTF8String];
}

void EditBoxImplIOS::setPlaceHolder(const char* pText)
{
    _systemControl.textField.placeholder = [NSString stringWithUTF8String:pText];
	_labelPlaceHolder->setString(pText);
}

static CGPoint convertDesignCoordToScreenCoord(const Vec2& designCoord)
{
    auto glview = cocos2d::Director::getInstance()->getOpenGLView();
    CCEAGLView *eaglview = (CCEAGLView *) glview->getEAGLView();

    float viewH = (float)[eaglview getHeight];
    
    Vec2 visiblePos = Vec2(designCoord.x * glview->getScaleX(), designCoord.y * glview->getScaleY());
    Vec2 screenGLPos = visiblePos + glview->getViewPortRect().origin;
    
    CGPoint screenPos = CGPointMake(screenGLPos.x, viewH - screenGLPos.y);
    
    float factor = eaglview.contentScaleFactor;
    screenPos.x = screenPos.x / factor;
    screenPos.y = screenPos.y / factor;

    CCLOGINFO("[EditBox] pos x = %f, y = %f", screenGLPos.x, screenGLPos.y);
    return screenPos;
}

void EditBoxImplIOS::setPosition(const Vec2& pos)
{
	_position = pos;
	adjustTextFieldPosition();
}

void EditBoxImplIOS::setVisible(bool visible)
{
//    _systemControl.textField.hidden = !visible;
}

void EditBoxImplIOS::setContentSize(const Size& size)
{
    _contentSize = size;
    CCLOG("[Edit text] content size = (%f, %f)", size.width, size.height);
    placeInactiveLabels();
    auto glview = cocos2d::Director::getInstance()->getOpenGLView();
    CGSize controlSize = CGSizeMake(size.width * glview->getScaleX(),size.height * glview->getScaleY());
    
    CCEAGLView *eaglview = static_cast<CCEAGLView *>(glview->getEAGLView());
    float factor = eaglview.contentScaleFactor;
    controlSize.width /= factor;
    controlSize.height /= factor;
    
    [_systemControl setContentSize:controlSize];
}

void EditBoxImplIOS::setAnchorPoint(const Vec2& anchorPoint)
{
    CCLOG("[Edit text] anchor point = (%f, %f)", anchorPoint.x, anchorPoint.y);
	_anchorPoint = anchorPoint;
	setPosition(_position);
}

void EditBoxImplIOS::visit(void)
{
}

void EditBoxImplIOS::onEnter(void)
{
    adjustTextFieldPosition();
    const char* pText = getText();
    if (pText) {
        setInactiveText(pText);
    }
}

void EditBoxImplIOS::updatePosition(float dt)
{
    if (nullptr != _systemControl) {
        this->adjustTextFieldPosition();
    }
}



void EditBoxImplIOS::adjustTextFieldPosition()
{
	Size contentSize = _editBox->getContentSize();
	Rect rect = Rect(0, 0, contentSize.width, contentSize.height);
    rect = RectApplyAffineTransform(rect, _editBox->nodeToWorldTransform());
	
	Vec2 designCoord = Vec2(rect.origin.x, rect.origin.y + rect.size.height);
    [_systemControl setPosition:convertDesignCoordToScreenCoord(designCoord)];
}

void EditBoxImplIOS::openKeyboard()
{
//	_label->setVisible(false);
    auto shuLabel = Label::createWithSystemFont("|", "Arial", _label->getSystemFontSize());
    shuLabel->setAnchorPoint(Vec2(0.1f, 0.45f));
    shuLabel->setColor(_label->getColor());
    if(_label->isVisible())
    {
        shuLabel->setPosition(Vec2(_label->getPositionX()+_label->getContentSize().width,_label->getPositionY()));
    }
    else
    {
        shuLabel->setPosition(Vec2(_label->getPositionX(),_label->getPositionY()));
    }
    
    shuLabel->setName("_shuLabel");
    shuLabel->setOpacity(0);
    shuLabel->runAction(cocos2d::RepeatForever::create(cocos2d::Sequence::create(cocos2d::FadeIn::create(0),cocos2d::DelayTime::create(0.2),cocos2d::FadeOut::create(0.5),cocos2d::DelayTime::create(0.5), nil)));
    _label->getParent()->addChild(shuLabel,_label->getLocalZOrder()+1);
    
    
	_labelPlaceHolder->setVisible(false);
	_systemControl.critiqueView.hidden = NO;
    [_systemControl openKeyboard];


    
}

void EditBoxImplIOS::closeKeyboard()
{
    [_systemControl closeKeyboard];
}

void EditBoxImplIOS::onEndEditing()
{
    _systemControl.critiqueView.hidden = YES;
    if ([_systemControl.textField isFirstResponder]) {
        [_systemControl.textField resignFirstResponder];
    }
//    [_systemControl.critiqueView removeFromSuperview];
    _label->getParent()->getChildByName("_shuLabel")->removeFromParentAndCleanup(true);
	if(strlen(getText()) == 0)
	{
		_label->setVisible(false);
		_labelPlaceHolder->setVisible(true);
	}
	else
	{
		_label->setVisible(true);
		_labelPlaceHolder->setVisible(false);
		setInactiveText(getText());
	}
}

}

NS_CC_END

#endif /* #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS) */


