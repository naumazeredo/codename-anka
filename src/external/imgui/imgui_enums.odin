/*
 *  @Name:     imgui_enums
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    fyoucon@gmail.com
 *  @Creation: 02-09-2018 16:01:49 UTC+1
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 02-09-2018 18:13:55 UTC+1
 *  
 *  @Description:
 *  
 */

package imgui;

Window_Flags :: enum i32 {
    None                        = 0,
    No_Title_Bar                = 1 << 0,
    No_Resize                   = 1 << 1,
    No_Move                     = 1 << 2,
    No_Scrollbar                = 1 << 3,
    No_Scroll_With_Mouse        = 1 << 4,
    No_Collapse                 = 1 << 5,
    Always_Auto_Resize          = 1 << 6,
    No_Background               = 1 << 7,
    No_Saved_Settings           = 1 << 8,
    No_Mouse_Inputs             = 1 << 9,
    Menu_Bar                    = 1 << 10,
    Horizontal_Scrollbar        = 1 << 11,
    No_Focus_On_Appearing       = 1 << 12,
    No_Bring_To_Front_On_Focus  = 1 << 13,
    Always_Vertical_Scrollbar   = 1 << 14,
    Always_Horizontal_Scrollbar = 1<< 15,
    Always_Use_Window_Padding   = 1 << 16,
    No_Nav_Inputs               = 1 << 18,
    No_Nav_Focus                = 1 << 19,
    Unsaved_Document            = 1 << 20,
    No_Nav                      = No_Nav_Inputs | No_Nav_Focus,
    No_Decoration               = No_Title_Bar | No_Resize | No_Scrollbar | No_Collapse,
    No_Inputs                   = No_Mouse_Inputs | No_Nav_Inputs | No_Nav_Focus,

    Nav_Flattened               = 1 << 23,
    Child_Window                = 1 << 24,
    Tooltip                     = 1 << 25,
    Popup                       = 1 << 26,
    Modal                       = 1 << 27,
    Child_Menu                  = 1 << 28   // Don't use! For internal use by Begin_Menu()
}

Input_Text_Flags :: enum i32 {
    None                    = 0,
    Chars_Decimal           = 1 << 0,
    Chars_Hexadecimal       = 1 << 1,
    Chars_Uppercase         = 1 << 2,
    Chars_No_Blank          = 1 << 3,
    Auto_Select_All         = 1 << 4,
    Enter_Returns_True      = 1 << 5,
    Callback_Completion     = 1 << 6,
    Callback_History        = 1 << 7,
    Callback_Always         = 1 << 8,
    Callback_Char_Filter    = 1 << 9,
    Allow_Tab_Input         = 1 << 10,
    Ctrl_Enter_For_New_Line = 1 << 11,
    No_Horizontal_Scroll    = 1 << 12,
    Always_Insert_Mode      = 1 << 13,
    Read_Only               = 1 << 14,
    Password                = 1 << 15,
    No_Undo_Redo            = 1 << 16,
    Chars_Scientific        = 1 << 17,
    Callback_Resize         = 1 << 18,
    Multiline               = 1 << 20,
    No_Mark_Edited          = 1 << 21
}

Tree_Node_Flags :: enum i32 {
    None                     = 0,
    Selected                 = 1 << 0,
    Framed                   = 1 << 1,
    Allow_Item_Overlap       = 1 << 2,
    No_Tree_Push_On_Open     = 1 << 3,
    No_Auto_Open_On_Log      = 1 << 4,
    Default_Open             = 1 << 5,
    Open_On_Double_Click     = 1 << 6,
    Open_On_Arrow            = 1 << 7,
    Leaf                     = 1 << 8,
    Bullet                   = 1 << 9,
    Frame_Padding            = 1 << 10,
    Span_Avail_Width         = 1 << 11,
    Span_Full_Width          = 1 << 12,
    Nav_Left_Jumps_Back_Here = 1 << 13,
    //No_Scroll_On_Open        = 1 << 14,  // FIXME: TODO: Disable automatic scroll on Tree_Pop() if node got just open and contents is not visible
    Collapsing_Header        = Framed | No_Tree_Push_On_Open | No_Auto_Open_On_Log
}


Selectable_Flags :: enum i32 {
    None               = 0,
    Dont_Close_Popups  = 1 << 0,
    Span_All_Columns   = 1 << 1,
    Allow_Double_Click = 1 << 2,
    Disabled           = 1 << 3,
    Allow_Item_Overlap = 1 << 4    // (WIP) Hit testing to allow subsequent widgets to overlap this one
}

Combo_Flags :: enum i32 {
    None             = 0,
    Popup_Align_Left = 1 << 0,
    Height_Small     = 1 << 1,
    Height_Regular   = 1 << 2,
    Height_Large     = 1 << 3,
    Height_Largest   = 1 << 4,
    No_Arrow_Button  = 1 << 5,
    No_Preview       = 1 << 6,
    Height_Mask_     = Height_Small | Height_Regular | Height_Large | Height_Largest
}

Tab_Bar_Flags :: enum i32 {
    None                              = 0,
    Reorderable                       = 1 << 0,
    Auto_Select_New_Tabs              = 1 << 1,
    Tab_List_Popup_Button             = 1 << 2,
    No_Close_With_Middle_Mouse_Button = 1 << 3,
    No_Tab_List_Scrolling_Buttons     = 1 << 4,
    No_Tooltip                        = 1 << 5,
    Fitting_Policy_Resize_Down        = 1 << 6,
    Fitting_Policy_Scroll             = 1 << 7,
    Fitting_Policy_Mask_              = Fitting_Policy_Resize_Down | Fitting_Policy_Scroll,
    Fitting_Policy_Default_           = Fitting_Policy_Resize_Down
}

Tab_Item_Flags :: enum i32 {
    None                              = 0,
    Unsaved_Document                  = 1 << 0,
    Set_Selected                      = 1 << 1,
    No_Close_With_Middle_Mouse_Button = 1 << 2,
    No_Push_Id                        = 1 << 3
}

Focused_Flags :: enum i32 {
    None                   = 0,
    Child_Windows          = 1 << 0,
    Root_Window            = 1 << 1,
    Any_Window             = 1 << 2,
    Root_And_Child_Windows = Root_Window | Child_Windows
}

Hovered_Flags :: enum i32 {
    None                              = 0,
    Child_Windows                     = 1 << 0,
    Root_Window                       = 1 << 1,
    Any_Window                        = 1 << 2,
    Allow_When_Blocked_By_Popup       = 1 << 3,
    //Allow_When_Blocked_By_Modal     = 1 << 4,
    Allow_When_Blocked_By_Active_Item = 1 << 5,
    Allow_When_Overlapped             = 1 << 6,
    Allow_When_Disabled               = 1 << 7,
    Rect_Only                         = Allow_When_Blocked_By_Popup | Allow_When_Blocked_By_Active_Item | Allow_When_Overlapped,
    Root_And_Child_Windows            = Root_Window | Child_Windows
}

Drag_Drop_Flags :: enum i32 {
    None                          = 0,
    // Begin_Drag_Drop_Source() flags
    Source_No_Preview_Tooltip     = 1 << 0,
    Source_No_Disable_Hover       = 1 << 1,
    Source_No_Hold_To_Open_Others = 1 << 2,
    Source_Allow_Null_ID          = 1 << 3,
    Source_Extern                 = 1 << 4,
    Source_Auto_Expire_Payload    = 1 << 5,
    // Accept_Drag_Drop_Payload() flags
    Accept_Before_Delivery        = 1 << 10,
    Accept_No_Draw_Default_Rect   = 1 << 11,
    Accept_No_Preview_Tooltip     = 1 << 12,
    Accept_Peek_Only              = Accept_Before_Delivery | Accept_No_Draw_Default_Rect  // For peeking ahead and inspecting the payload before delivery.
}

Data_Type :: enum i32 {
    S8,
    U8,
    S16,
    U16,
    S32,
    U32,
    S64,
    U64,
    Float,
    Double,
    COUNT
}

Dir :: enum i32 {
    None  = -1,
    Left  = 0,
    Right = 1,
    Up    = 2,
    Down  = 3,
    COUNT,
}

Key :: enum i32 {
    Tab,
    Left_Arrow,
    Right_Arrow,
    Up_Arrow,
    Down_Arrow,
    Page_Up,
    Page_Down,
    Home,
    End,
    Insert,
    Delete,
    Backspace,
    Space,
    Enter,
    Escape,
    Key_Pad_Enter,
    A,
    C,
    V,
    X,
    Y,
    Z,
    COUNT,
}

Key_Mod_Flags :: enum i32 {
  None  = 0,
  Ctrl  = 1 << 0,
  Shift = 1 << 1,
  Alt   = 1 << 2,
  Super = 1 << 3,
}

Nav_Input :: enum i32 {
    Activate,
    Cancel,
    Input,
    Menu,
    Dpad_Left,
    Dpad_Right,
    Dpad_Up,
    Dpad_Down,
    LStick_Left,
    LStick_Right,
    LStick_Up,
    LStick_Down,
    Focus_Prev,
    Focus_Next,
    Tweak_Slow,
    Tweak_Fast,

    Key_Menu_,
    Key_Left_,
    Key_Right_,
    Key_Up_,
    Key_Down_,
    COUNT,
    Internal_Start_ = Key_Menu_
}

Config_Flags :: enum i32 {
    None                       = 0,
    Nav_Enable_Keyboard        = 1 << 0,
    Nav_Enable_Gamepad         = 1 << 1,
    Nav_Enable_Set_Mouse_Pos   = 1 << 2,
    Nav_No_Capture_Keyboard    = 1 << 3,
    No_Mouse                   = 1 << 4,
    No_Mouse_Cursor_Change     = 1 << 5,

    Is_SRGB                    = 1 << 20,
    Is_Touch_Screen            = 1 << 21
}

Backend_Flags :: enum i32 {
    None                    = 0,
    Has_Gamepad             = 1 << 0,
    Has_Mouse_Cursors       = 1 << 1,
    Has_Set_Mouse_Pos       = 1 << 2,
    Renderer_Has_Vtx_Offset = 1 << 3,
}

// @Refactor(naum): (script to generate dependency) change some names (in this case ImGuiCol_ to Style_Color)
Style_Color :: enum i32 {
    Text,
    Text_Disabled,
    Window_Bg,
    Child_Bg,
    Popup_Bg,
    Border,
    Border_Shadow,
    Frame_Bg,
    Frame_Bg_Hovered,
    Frame_Bg_Active,
    Title_Bg,
    Title_Bg_Active,
    Title_Bg_Collapsed,
    Menu_Bar_Bg,
    Scrollbar_Bg,
    Scrollbar_Grab,
    Scrollbar_Grab_Hovered,
    Scrollbar_Grab_Active,
    Check_Mark,
    Slider_Grab,
    Slider_Grab_Active,
    Button,
    Button_Hovered,
    Button_Active,
    Header,
    Header_Hovered,
    Header_Active,
    Separator,
    Separator_Hovered,
    Separator_Active,
    Resize_Grip,
    Resize_Grip_Hovered,
    Resize_Grip_Active,
    Tab,
    Tab_Hovered,
    Tab_Active,
    Tab_Unfocused,
    Tab_Unfocused_Active,
    Plot_Lines,
    Plot_Lines_Hovered,
    Plot_Histogram,
    Plot_Histogram_Hovered,
    Text_Selected_Bg,
    Drag_Drop_Target,
    Nav_Highlight,
    Nav_Windowing_Highlight,
    Nav_Windowing_Dim_Bg,
    Modal_Window_Dim_Bg,
    COUNT
}

Style_Var :: enum i32 {
    Alpha,
    Window_Padding,
    Window_Rounding,
    Window_Border_Size,
    Window_Min_Size,
    Window_Title_Align,
    Child_Rounding,
    Child_Border_Size,
    Popup_Rounding,
    Popup_Border_Size,
    Frame_Padding,
    Frame_Rounding,
    Frame_Border_Size,
    Item_Spacing,
    Item_Inner_Spacing,
    Indent_Spacing,
    Scrollbar_Size,
    Scrollbar_Rounding,
    Grab_Min_Size,
    Grab_Rounding,
    Tab_Rounding,
    Button_Text_Align,
    Selectable_Text_Align,
    COUNT
}

Color_Edit_Flags :: enum i32 {
    None               = 0,
    No_Alpha           = 1 << 1,
    No_Picker          = 1 << 2,
    No_Options         = 1 << 3,
    No_Small_Preview   = 1 << 4,
    No_Inputs          = 1 << 5,
    No_Tooltip         = 1 << 6,
    No_Label           = 1 << 7,
    No_Side_Preview    = 1 << 8,
    No_Drag_Drop       = 1 << 9,
    No_Border          = 1 << 10,

    // User Options (right-click on widget to change some of them).
    Alpha_Bar          = 1 << 16,
    Alpha_Preview      = 1 << 17,
    Alpha_Preview_Half = 1 << 18,
    HDR                = 1 << 19,
    Display_RGB        = 1 << 20,
    Display_HSV        = 1 << 21,
    Display_Hex        = 1 << 22,
    Uint8              = 1 << 23,
    Float              = 1 << 24,
    Picker_Hue_Bar     = 1 << 25,
    Picker_Hue_Wheel   = 1 << 26,
    Input_RGB          = 1 << 27,
    Input_HSV          = 1 << 28,

    // Defaults Options. You can set application defaults using Set_Color_EditOptions(). The intent is that you probably don't want to
    // override them in most of your calls. Let the user choose via the option menu and/or call Set_Color_EditOptions() once during startup.
    Options_Default    = Uint8|Display_RGB|Input_RGB|Picker_Hue_Bar,

    // [Internal] Masks
    Display_Mask       = Display_RGB|Display_HSV|Display_Hex,
    Data_Type_Mask     = Uint8|Float,
    Picker_Mask        = Picker_Hue_Wheel|Picker_Hue_Bar,
    Input_Mask         = Input_RGB|Input_HSV
}

Mouse_Button :: enum i32 {
  Left   = 0,
  Right  = 1,
  Middle = 2,
  COUNT  = 5
};

Mouse_Cursor :: enum i32 {
    None = -1,
    Arrow = 0,
    Text_Input,
    Resize_All,
    Resize_NS,
    Resize_EW,
    Resize_NESW,
    Resize_NWSE,
    Hand,
    Not_Allowed,
    COUNT
}

Set_Cond :: enum i32 {
    Always         = 1 << 0,
    Once           = 1 << 1,
    First_Use_Ever = 1 << 2,
    Appearing      = 1 << 3
}

Draw_Corner_Flags :: enum i32 {
    None      = 0,
    Top_Left  = 1 << 0,
    Top_Right = 1 << 1,
    Bot_Left  = 1 << 2,
    Bot_Right = 1 << 3,
    Top       = Top_Left  | Top_Right,
    Bot       = Bot_Left  | Bot_Right,
    Left      = Top_Left  | Bot_Left,
    Right     = Top_Right | Bot_Right,
    All       = 0xF
}

Draw_List_Flags :: enum i32 {
    None               = 0,
    Anti_Aliased_Lines = 1 << 0,
    Anti_Aliased_Fill  = 1 << 1,
    Allow_Vtx_Offset   = 1 << 2
}

Font_Atlas_Flags :: enum i32 {
    None                   = 0,
    No_Power_Of_Two_Height = 1 << 0,
    No_Mouse_Cursors       = 1 << 1
}

//////// Widgets support

Item_Flags :: enum i32 {
  None                     = 0,
  NoTabStop                = 1 << 0,
  ButtonRepeat             = 1 << 1,
  Disabled                 = 1 << 2,
  NoNav                    = 1 << 3,
  NoNavDefaultFocus        = 1 << 4,
  SelectableDontClosePopup = 1 << 5,
  MixedValue               = 1 << 6,
  Default                  = 0,
}
