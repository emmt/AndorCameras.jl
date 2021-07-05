- Field `lastimg` in `Camera` is not type-stable.

- Deal with PreAmpGain options.

- Correctly initialize/finalize SDK in case code is included more than once.

- Write an image server which uses shared memory to continuously acquire
  images and provide them to clients.  A mechanism must be found to indicate
  which image is the last one and to detect overwriting.
