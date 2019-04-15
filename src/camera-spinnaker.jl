# SpinnakerGUI.jl

using Spinnaker

function cam_init(;framerate::AbstractFloat=60.0,exposure::Union{AbstractFloat,Symbol}=:auto,camid::Int64=0)
    camlist = Spinnaker.CameraList()
    if length(camlist) == 0
        error("No camera found")
    elseif length(camlist) > 1
        error("Multiple cameras found. Choice ambiguous.")
    else
        cam = camlist[camid]
        Spinnaker.framerate!(cam, framerate)

        Spinnaker.start!(cam)

        if exposure == :auto
            Spinnaker.exposure!(cam)
        else
            Spinnaker.exposure!(cam,exposure)
        end

        return cam
    end
end
