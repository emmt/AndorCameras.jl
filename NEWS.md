
- Installation on Windows can be done without other tools than Julia (no `make`
  and no C compiler needed) to parse Andor SDK header file `<atcore.h>`.

- Add new features from version 3.12 of the SDK, these are needed for the
  *Apogee* and *iStar-SCMOS* cameras.

- `wait` throws `ScientificCameras.TimeoutError` and use metadata to retrieve a
  time stamp.

- Some methods are provided to convert pixel formats.
