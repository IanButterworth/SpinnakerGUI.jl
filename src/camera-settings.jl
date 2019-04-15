

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
    exposureTime::Tuple{AbstractFloat,AbstractFloat} = (0.0,2000.0)
    gainAuto::Vector{Symbol} = [:off,:once,:continuous]
    gain::Tuple{AbstractFloat,AbstractFloat} = (0.0,10.0)
    gamma::Tuple{AbstractFloat,AbstractFloat} = (0.0,10.0)
    blackLevel::Tuple{AbstractFloat,AbstractFloat} = (0.0,4000.0)
    deviceLinkThroughputLimit::Tuple{Int64,Int64} = (0,383328000)

    width::Tuple{Int64,Int64} = (0,typemax(1))
    height::Tuple{Int64,Int64} = (0,typemax(1))
    offsetX::Tuple{Int64,Int64} = (0,typemax(1))
    offsetY::Tuple{Int64,Int64} = (0,typemax(1))
    binningHorizontal::Tuple{Int64,Int64} = (1,typemax(1))
    binningVertical::Tuple{Int64,Int64} = (1,typemax(1))
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
    global camSettings, camGPIO
    update_timer = Timer(0,interval=timerInterval)
    lastCamSettings = nothing
    lastCamGPIO = nothing
    while gui_open
        t_before = time()
        if camSettings != lastCamSettings
            @show "Updating camsettings"
            #Update camSettings
            if camSettings.exposureMode == :off
                exposure!(cam,camSettings.exposureTime)
            elseif camSettings.exposureMode == :once
                ex = exposure!(cam)
                camSettings.exposureTime = ex
                exposure!(cam,ex)
            elseif camSettings.exposureMode == :continuous
                ex = exposure!(cam)
                camSettings.exposureTime = ex
            end

            lastCamSettings = camSettings
        end
        if camGPIO != lastCamGPIO
            #Update camGPIO

            lastCamGPIO = camGPIO
        end
        if time()-t_before < timerInterval
            wait(update_timer)
        else
            yield()
        end
    end
end

function camSettingsLimitsUpdater!(camSettingsLimits::settingsLimits)

end

function camGPIOLimitsUpdater!(camGPIOLimits::GPIOLimits)

end
