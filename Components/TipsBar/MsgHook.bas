Attribute VB_Name = "MsgHook"
Option Explicit

Public Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long)

Private Declare Function SetWindowsHookEx Lib "user32" Alias "SetWindowsHookExA" (ByVal idHook As Long, ByVal lpfn As Long, ByVal hMod As Long, ByVal dwThreadId As Long) As Long
Private Declare Function UnhookWindowsHookEx Lib "user32" (ByVal hHook As Long) As Long

Private Declare Function CallNextHookEx Lib "user32" (ByVal hHook As Long, ByVal nCode As Long, ByVal wParam As Long, lParam As Any) As Long

Private Declare Function GetCurrentThreadId Lib "kernel32" () As Long

Private Type POINTAPI
        x As Long
        y As Long
End Type

Private Type Msg
    hWnd As Long
    Message As Long
    wParam As Long
    lParam As Long
    Time As Long
    PT As POINTAPI
End Type

Private Type CWPSTRUCT
    lParam As Long
    wParam As Long
    Message As Long
    hWnd As Long
End Type

Private Const WH_GETMESSAGE = 3
Private Const WH_CALLWNDPROC = 4
Private Const WH_CALLWNDPROCRET = 12

Private Const HC_ACTION = 0
Private Const PM_REMOVE = &H1

Private Const lGetMsg As Boolean = False
Private Const lCallWndProc As Boolean = True
Private Const lCallWndProcProtect As Boolean = False

Private lngGetMsgProc As Long, lngCallWndRetProc As Long, lngCallWndProc As Long

Public Const WM_KEYUP = &H101
Public Const WM_LBUTTONUP = &H202

Public Const WM_MOVE = &H3
Public Const WM_SIZE = &H5
Public Const WM_SETFOCUS = &H7
Public Const WM_DESTROY = &H2
Public Const WM_SHOWWINDOW = &H18
Public Const WM_KILLFOCUS = &H8

Public Const WM_MDIACTIVATE = &H222
Public Const WM_MDIDESTROY = &H221


Public IDELoadUp As Boolean

Public Sub iMsgProc(ByVal hWnd As Long, ByVal Msg As Long, ByVal wParam As Long, ByVal lParam As Long)
    
    
    Select Case Msg
    
    Case WM_SIZE
        If TBH Is Nothing Then Exit Sub
        If hWnd = TBH.hMDIClient Then TBH.Msg_WM_SIZE_If_MDIClient
        
    Case WM_MDIDESTROY
        If TBH Is Nothing Then Exit Sub
        If hWnd = TBH.hMDIClient Then
            TBH.Msg_WM_MDIDESTROY_If_IDEWindow wParam
        End If
    
    Case WM_MDIACTIVATE
        If TBH Is Nothing Then Exit Sub
        If hWnd = lParam Then TBH.Msg_WM_MDIACTIVATE_If_IDEWindow hWnd
    
    End Select
    
End Sub

Private Sub iMsgProtectProc(ByVal hWnd As Long, ByVal Msg As Long, ByVal wParam As Long, ByVal lParam As Long)
    
End Sub

Public Function Hook_GetMsgProc(ByVal nCode As Long, ByVal wParam As Long, ByVal lParam As Long) As Long

    Hook_GetMsgProc = CallNextHookEx(lngGetMsgProc, nCode, wParam, lParam)
    
    If nCode = HC_ACTION And wParam = PM_REMOVE Then
        Dim P As Msg
        CopyMemory P, ByVal lParam, Len(P)
        
        Call iMsgProc(P.hWnd, P.Message, P.wParam, P.lParam)
    End If
    
End Function

Public Function Hook_CallWndProc(ByVal nCode As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
    
    Hook_CallWndProc = CallNextHookEx(lngCallWndProc, nCode, wParam, lParam)
    
    If nCode = HC_ACTION Then
    
        Dim P As CWPSTRUCT
        CopyMemory P, ByVal lParam, Len(P)
        
        Call iMsgProc(P.hWnd, P.Message, P.wParam, P.lParam)
        
    End If
    
    
End Function

Public Function Hook_CallWndRetProc(ByVal nCode As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
    
    Hook_CallWndRetProc = CallNextHookEx(lngCallWndProc, nCode, wParam, lParam)
    
    If nCode = HC_ACTION Then
        
        Dim P As CWPSTRUCT
        CopyMemory P, ByVal lParam, Len(P)
        
        iMsgProtectProc P.hWnd, P.Message, P.wParam, P.lParam
        
    End If
    
End Function

Public Sub SetMsgHooks()
    
    Dim hIns As Long, TID As Long
        
    hIns = 0
    TID = GetCurrentThreadId
        
    If lGetMsg Then
        lngGetMsgProc = SetWindowsHookEx(WH_GETMESSAGE, AddressOf Hook_GetMsgProc, hIns, TID)
        DBPrint "lngGetMsgProc = " & lngGetMsgProc
    End If
        
    If lCallWndProc Then
        lngCallWndProc = SetWindowsHookEx(WH_CALLWNDPROC, AddressOf Hook_CallWndProc, hIns, TID)
        DBPrint "lngCallWndProc = " & lngCallWndProc
    End If
        
    If lCallWndProcProtect Then
        lngCallWndRetProc = SetWindowsHookEx(WH_CALLWNDPROCRET, AddressOf Hook_CallWndRetProc, hIns, TID)
        DBPrint "lngCallWndRetProc = " & lngCallWndRetProc
    End If
    
End Sub

Public Sub UnSetMsgHooks()
    If lGetMsg Then UnhookWindowsHookEx lngGetMsgProc
    If lCallWndProc Then UnhookWindowsHookEx lngCallWndProc
    If lCallWndProcProtect Then UnhookWindowsHookEx lngCallWndRetProc
End Sub

