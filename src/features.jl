#
# features.jl --
#
# Definitions of features for Andor cameras.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017, Éric Thiébaut.
#

module Features

import
    ..AbstractFeature,
    ..CommandFeature,
    ..BooleanFeature,
    ..EnumeratedFeature,
    ..IntegerFeature,
    ..FloatingPointFeature,
    ..StringFeature,
    ..@L_str,
    ..isavailable,
    ..isimplemented,
    ..widestring

# Export the following methods for those who `using AndorCameras.Features`
# (feature constants will be exported while being defined below):
export
    isavailable,
    isimplemented

for (sym, T) in ((:AccumulateCount, IntegerFeature),
                 (:AcquisitionStart, CommandFeature),
                 (:AcquisitionStop,  CommandFeature),
                 (:AOIBinning, EnumeratedFeature),
                 (:AOIHBin, IntegerFeature),
                 (:AOIHeight, IntegerFeature),
                 (:AOILeft, IntegerFeature),
                 (:AOIStride, IntegerFeature),
                 (:AOITop, IntegerFeature),
                 (:AOIVBin, IntegerFeature),
                 (:AOIWidth, IntegerFeature),
                 (:AuxiliaryOutSource, EnumeratedFeature),
                 (:BaselineLevel, IntegerFeature),
                 (:BitDepth, EnumeratedFeature),
                 (:BufferOverflowEvent, IntegerFeature),
                 (:BytesPerPixel, FloatingPointFeature),
                 (:CameraAcquiring, BooleanFeature),
                 (:CameraDump, CommandFeature),
                 (:CameraModel, StringFeature),
                 (:CameraName, StringFeature),
                 (:ControllerID, StringFeature),
                 (:CycleMode, EnumeratedFeature),
                 (:DeviceCount, IntegerFeature),
                 (:DeviceVideoIndex, IntegerFeature),
                 (:ElectronicShutteringMode, EnumeratedFeature),
                 (:EventEnable, BooleanFeature),
                 (:EventsMissedEvent, IntegerFeature),
                 (:EventSelector, EnumeratedFeature),
                 (:ExposureTime, FloatingPointFeature),
                 (:ExposureEndEvent, IntegerFeature),
                 (:ExposureStartEvent, IntegerFeature),
                 (:FanSpeed, EnumeratedFeature),
                 (:FirmwareVersion, StringFeature),
                 (:FrameCount, IntegerFeature),
                 (:FrameRate, FloatingPointFeature),
                 (:FullAOIControl, BooleanFeature),
                 (:ImageSizeBytes, IntegerFeature),
                 (:InterfaceType, StringFeature),
                 (:IOInvert, BooleanFeature),
                 (:IOSelector, EnumeratedFeature),
                 (:LUTIndex, IntegerFeature),
                 (:LUTValue, IntegerFeature),
                 (:MaxInterfaceTransferRate, FloatingPointFeature),
                 (:MetadataEnable, BooleanFeature),
                 (:MetadataFrame, BooleanFeature),
                 (:MetadataTimestamp, BooleanFeature),
                 (:Overlap, BooleanFeature),
                 (:PixelCorrection, EnumeratedFeature),
                 (:PixelEncoding, EnumeratedFeature),
                 (:PixelHeight, FloatingPointFeature),
                 (:PixelReadoutRate, EnumeratedFeature),
                 (:PixelWidth, FloatingPointFeature),
                 (:PreAmpGain, EnumeratedFeature),
                 (:PreAmpGainChannel, EnumeratedFeature),
                 (:PreAmpGainControl, EnumeratedFeature),
                 (:PreAmpGainSelector, EnumeratedFeature),
                 (:ReadoutTime, FloatingPointFeature),
                 (:RollingShutterGlobalClear, BooleanFeature),
                 (:RowNExposureEndEvent, IntegerFeature),
                 (:RowNExposureStartEvent, IntegerFeature),
                 (:SensorCooling, BooleanFeature),
                 (:SensorHeight, IntegerFeature),
                 (:SensorTemperature, FloatingPointFeature),
                 (:SensorWidth, IntegerFeature),
                 (:SerialNumber, StringFeature),
                 (:SimplePreAmpGainControl, EnumeratedFeature),
                 (:SoftwareTrigger, CommandFeature),
                 (:SoftwareVersion, StringFeature),
                 (:SpuriousNoiseFilter, BooleanFeature),
                 (:SynchronousTriggering, BooleanFeature),
                 (:TargetSensorTemperature, FloatingPointFeature),
                 (:TemperatureControl, EnumeratedFeature),
                 (:TemperatureStatus, EnumeratedFeature),
                 (:TimestampClock, IntegerFeature),
                 (:TimestampClockFrequency, IntegerFeature),
                 (:TimestampClockReset, CommandFeature),
                 (:TriggerMode, EnumeratedFeature),
                 (:VerticallyCenterAOI, BooleanFeature))
    @eval begin
        const $sym = $(T(sym))
        export $sym
    end
end

end # module Features
