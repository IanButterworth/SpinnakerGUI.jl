using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic

# demonstrate the various window flags. typically you would just use the default!
control_no_titlebar = false
control_no_scrollbar = true
control_no_menu = true
control_no_move = false
control_no_resize = true
control_no_collapse = false
control_no_close = true
control_no_nav = true
control_no_background = false
control_no_bring_to_front = false

"""
    ShowControlWindow(p_open::Ref{Bool})

Show control window with camera info and controls.
"""
function ShowControlWindow(p_open::Ref{Bool})
    global cam, camImage, camRunning
    global camSettings, camGPIO

    # Control window
    # demonstrate the various window flags. typically you would just use the default!
    window_flags = CImGui.ImGuiWindowFlags(0)
    control_no_titlebar       && (window_flags |= CImGui.ImGuiWindowFlags_NoTitleBar;)
    control_no_scrollbar      && (window_flags |= CImGui.ImGuiWindowFlags_NoScrollbar;)
    !control_no_menu          && (window_flags |= CImGui.ImGuiWindowFlags_MenuBar;)
    control_no_move           && (window_flags |= CImGui.ImGuiWindowFlags_NoMove;)
    control_no_resize         && (window_flags |= CImGui.ImGuiWindowFlags_NoResize;)
    control_no_collapse       && (window_flags |= CImGui.ImGuiWindowFlags_NoCollapse;)
    control_no_nav            && (window_flags |= CImGui.ImGuiWindowFlags_NoNav;)
    control_no_background     && (window_flags |= CImGui.ImGuiWindowFlags_NoBackground;)
    control_no_bring_to_front && (window_flags |= CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus;)
    control_no_close && (p_open = C_NULL;) # don't pass our bool* to Begin

    # specify a default position/size in case there's no data in the .ini file.
    # typically this isn't required! we only do it to make the Demo applications a little more welcoming.
    CImGui.SetNextWindowPos((650, 20), CImGui.ImGuiCond_FirstUseEver)
    CImGui.SetNextWindowSize((550, 680), CImGui.ImGuiCond_FirstUseEver)

    CImGui.Begin("Control", p_open, window_flags) || (CImGui.End(); return)
    CImGui.Text("ImGui $(CImGui.IMGUI_VERSION)")

    # most "big" widgets share a common width settings by default.
    # CImGui.PushItemWidth(CImGui.GetWindowWidth() * 0.65)    # use 2/3 of the space for widgets and 1/3 for labels (default)
    CImGui.PushItemWidth(CImGui.GetFontSize() * -12)        # use fixed width for labels (by passing a negative value), the rest goes to widgets. We choose a width proportional to our font size.

    CImGui.Text(@sprintf("Display: %.2f ms/frame (%.1f FPS)", 1000 / CImGui.GetIO().Framerate, CImGui.GetIO().Framerate))
    CImGui.Text(@sprintf("Framegrab: %.2f ms/frame (%.1f FPS)", 1000 / perfGrabFramerate, perfGrabFramerate))
    CImGui.Text(@sprintf("Camera: %.1f FPS. Exposure %.1f ms", camSettings.acquisitionFramerate, camSettings.exposureTime))

    @cstatic ctrl_framerate=Cfloat(12.00) begin
        ctrl_framerate = Cfloat(camSettings.acquisitionFramerate)
        CImGui.PushItemWidth(200)
        @c CImGui.SliderFloat("Framerate (fps)", &ctrl_framerate,
            camSettingsLimits.acquisitionFramerate[1],
            camSettingsLimits.acquisitionFramerate[2], "%.3f")
        camSettings.acquisitionFramerate = ctrl_framerate
    end
    @cstatic ctrl_exposure=Cfloat(12.00) ctrl_auto=false begin
        ctrl_exposure = Cfloat(camSettings.exposureTime)
        ctrl_auto = camSettings.exposureAuto == :continuous
        CImGui.PushItemWidth(200)
        @c CImGui.SliderFloat("Exposure (ms)", &ctrl_exposure,
            camSettingsLimits.exposureTime[1],
            camSettingsLimits.exposureTime[2], "%.3f")
        CImGui.SameLine()
        @c CImGui.Checkbox("Auto", &ctrl_auto)
        CImGui.SameLine()
        once = CImGui.Button("Auto once")
        if once || (camSettings.exposureAuto == :once) # Keep `once` if pending
            camSettings.exposureAuto = :once
        elseif ctrl_auto
            camSettings.exposureAuto = :continuous
        elseif !ctrl_auto
            camSettings.exposureAuto = :off
            camSettings.exposureTime = ctrl_exposure
        end
    end
    @cstatic ctrl_playing=true begin
        if ctrl_playing
            if CImGui.Button("Pause",(100,100))
                stop!(cam)
                ctrl_playing = false
                camRunning = false
            end
        else
            if CImGui.Button("Run",(100,100))
                start!(cam)
                ctrl_playing = true
                camRunning = true
            end
        end
    end


    CImGui.End() # demo
end
