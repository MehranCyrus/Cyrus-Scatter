/* Optional second owned host run: repeats the complete non-render
   workflow and, only on success, writes four real Default Scanline images.
   This run's repeated checks are separate evidence, not additive coverage. */
global CA_IMPORTED_RENDER
CA_IMPORTED_RENDER=true
fileIn ((getFilenamePath (getSourceFileName()))+"arrange_imported_workflow_tests.ms")
