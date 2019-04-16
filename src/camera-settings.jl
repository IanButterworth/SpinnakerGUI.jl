
Base.@kwdef mutable struct information
    modelName::String = ""
    deviceSerialNumber::String = ""
    deviceFirmwareVersion::String = ""
end

Base.@kwdef mutable struct settings
    acquisitionMode::Symbol = :continuous #[:continuous,:singleFrame,:multiFrame]
    acquisitionFramerate::AbstractFloat = 30.0
    exposureMode::Symbol = :timed #[:timed,:triggerWidth]
    exposureAuto::Symbol = :off #[:off,:once,:continuous]
    exposureTime::AbstractFloat = 100.00
    gainAuto::Symbol = :off #[:off,:once,:continuous]
    gain::AbstractFloat = 0.0
    gamma::AbstractFloat = 1.25
    blackLevel::AbstractFloat = 5.0
    deviceLinkThroughputLimit::Int64 = 383328000

    width::Int64 = 100
    height::Int64 = 30
    offsetX::Int64 = 0
    offsetY::Int64 = 0
    pixelFormat::String = ""
    binningHorizontal::Int64 = 1
    binningVertical::Int64 = 1
end

Base.@kwdef mutable struct settingsLimits
    acquisitionMode::Vector{Symbol} = [:continuous,:singleFrame,:multiFrame]
    acquisitionFramerate::Tuple{AbstractFloat,AbstractFloat} = (0.0,60.0)
    exposureMode::Vector{Symbol} = [:timed,:triggerWidth]
    exposureAuto::Vector{Symbol} = [:off,:once,:continuous]
    exposureTime::Tuple{AbstractFloat,AbstractFloat} = (0.0,100.0)
    gainAuto::Vector{Symbol} = [:off,:once,:continuous]
    gain::Tuple{AbstractFloat,AbstractFloat} = (0.0,10.0)
    gamma::Tuple{AbstractFloat,AbstractFloat} = (0.0,10.0)
    blackLevel::Tuple{AbstractFloat,AbstractFloat} = (0.0,4000.0)
    deviceLinkThroughputLimit::Tuple{Int64,Int64} = (0,383328000)

    width::Tuple{Int64,Int64} = (0,3000)
    height::Tuple{Int64,Int64} = (0,3000)
    offsetX::Tuple{Int64,Int64} = (0,3000)
    offsetY::Tuple{Int64,Int64} = (0,3000)
    binningHorizontal::Tuple{Int64,Int64} = (1,2)
    binningVertical::Tuple{Int64,Int64} = (1,2)
end

Base.@kwdef mutable struct GPIO
    triggerSelector::Symbol = :frameStart #[:frameStart,:exposureActive]
    triggerMode::Symbol = :off #[:off,:on]
    triggerSource::Symbol = :line0 #[:software,:line0,:line3,:line3]
    triggerActivation::Symbol = :fallingEdge #[:risingEdge,:fallingEdge]
    triggerOverlap::Symbol = :off #[:off,:readOut]
    triggerDelay::AbstractFloat = 0.0
    lineSelector::Symbol = :line0 #[:line0,:line1,:line2,:line3]
    lineMode::Symbol = :input #[:input]
    lineInverter::Bool = true
    lineSource::Symbol = :nothing #[:exposureActive,:externalTriggerActive,:userOutput1]
    userOutputSelector::Symbol = :UserOutputValue1 #[:UserOutputValue1,:UserOutputValue2,:UserOutputValue3]
    userOutputValue::Bool = true
end


Base.@kwdef mutable struct GPIOLimits
    triggerSelector::Vector{Symbol} = [:frameStart,:exposureActive]
    triggerMode::Vector{Symbol} = [:off,:on]
    triggerSource::Vector{Symbol} = [:software,:line0,:line3,:line3]
    triggerActivation::Vector{Symbol} = [:risingEdge,:fallingEdge]
    triggerOverlap::Vector{Symbol} = [:off,:readOut]
    triggerDelay::Tuple{AbstractFloat,AbstractFloat} = (0.0,typemax(1.0))
    lineSelector::Vector{Symbol} = [:line0,:line1,:line2,:line3]
    lineMode::Vector{Symbol} = [:input]
    lineSource::Vector{Symbol} = [:exposureActive,:externalTriggerActive,:userOutput1]
    userOutputSelector::Vector{Symbol} = [:UserOutputValue1,:UserOutputValue2,:UserOutputValue3]
end

function camSettingsUpdater(;timerInterval::AbstractFloat=1/10)
    global camSettings, camSettingsLimits, camRunning
    global camGPIO, camGPIOLimits

    updateTimer = Timer(0,interval=timerInterval)
    lastCamSettings = deepcopy(camSettings)
    lastCamGPIO = deepcopy(camGPIO)
    while gui_open
        t_before = time()
        if camRunning
            # FRAMERATE
            if (camSettings.acquisitionFramerate != lastCamSettings.acquisitionFramerate)
                framerate!(cam,camSettings.acquisitionFramerate)
                camSettingsLimits.exposureTime = (0.0,1000/camSettings.acquisitionFramerate)
                lastCamSettings.acquisitionFramerate = camSettings.acquisitionFramerate
                camSettingsLimitsUpdater!(cam,camSettingsLimits)
            end

            # EXPOSURE
            if (camSettings.exposureAuto != lastCamSettings.exposureAuto) || (camSettings.exposureTime != lastCamSettings.exposureTime)
                if camSettings.exposureAuto == :off
                    exposure!(cam,camSettings.exposureTime*1000)
                elseif camSettings.exposureAuto == :once
                    exposure!(cam)
                    ex,mode = exposure(cam)
                    camSettings.exposureTime = ex/1000
                    exposure!(cam,ex) # Required to set cam back to fixed exposure
                    camSettings.exposureAuto = :off
                elseif camSettings.exposureAuto == :continuous
                    exposure!(cam)
                    ex,mode = exposure(cam)
                    camSettings.exposureTime = ex/1000
                end
                lastCamSettings.exposureAuto = camSettings.exposureAuto
                lastCamSettings.exposureTime = camSettings.exposureTime
            end

            # GAIN
            if (camSettings.gainAuto != lastCamSettings.gainAuto) || (camSettings.gain != lastCamSettings.gain)
                if camSettings.gainAuto == :off
                    gain!(cam,camSettings.gain)
                elseif camSettings.gainAuto == :once
                    gain!(cam)
                    g,mode = gain(cam)
                    camSettings.gain = g
                    gain!(cam,g) # Required to set cam back to fixed gain
                    camSettings.gainAuto = :off
                elseif camSettings.gainAuto == :continuous
                    gain!(cam)
                    g,mode = gain(cam)
                    camSettings.gain = g
                end
                lastCamSettings.gainAuto = camSettings.gainAuto
                lastCamSettings.gain = camSettings.gain
            end

            # IMAGE SIZE
            if (camSettings.width != lastCamSettings.width) || (camSettings.height != lastCamSettings.height)
                stop!(cam)
                camrunning = false
                imagedims!(cam,(camSettings.width,camSettings.height))
                start!(cam)
                camrunning = true
                lastCamSettings.width = camSettings.width
                lastCamSettings.height = camSettings.height
                camSettingsLimitsUpdater!(cam,camSettingsLimits)
            end

            # IMAGE OFFSET
            if (camSettings.offsetX != lastCamSettings.offsetX) || (camSettings.offsetY != lastCamSettings.offsetY)
                offsetdims!(cam,(camSettings.offsetX,camSettings.offsetY))
                lastCamSettings.offsetX = camSettings.offsetX
                lastCamSettings.offsetY = camSettings.offsetY
            end
        end
        if time()-t_before < timerInterval
            wait(updateTimer)
        else
            yield()
        end

    end
    close(updateTimer)
    updateTimer = nothing
end

function camSettingsLimitsUpdater!(cam,camSettingsLimits::settingsLimits)
    # General Settings
    camSettingsLimits.acquisitionFramerate = framerate_limits(cam)
    camSettingsLimits.exposureTime = exposure_limits(cam)./1000
    camSettingsLimits.gain = gain_limits(cam)

    # Image size
    camSettingsLimits.width,camSettingsLimits.height = imagedims_limits(cam)
    camSettingsLimits.offsetX,camSettingsLimits.offsetY = offsetdims_limits(cam)
end

function camGPIOLimitsUpdater!(camGPIOLimits::GPIOLimits)

end
