## July 30, 2014

### Changes

  - bestair tonometry data checking and stats.sas
    - Improve data QC. Export permanent set with added vars.
  - import bestair tonometry for update and check outcome variables
    - Add formats and labels.
  - import bestair tonometry.sas
    - Reduce program to shell that calls other programs.


## September 6, 2013

### Changes

  - bestair tonometry data checking and stats.sas
    - Refactor "pwv_check" and "pwa_check" datasteps using arrays.
  - import bestair tonometry for update and check outcome variables.sas
    - Refactor age category determination.
    - Use do loop to check gender only once.
  - import bestair tonometry.sas
    - Use %include statement to replace identical coding with "import bestair tonometry for update and check outcome variables.sas" and "bestair tonometry data checking and stats.sas"
  -isolate pwv and augindex
    - Refactor "tonometry_scrub" step using array.

## August 27, 2013

### Changes

  - bestair tonometry data checking and stats.sas
    - Move header to README.md.
  - import bestair tonometry for update and check outcome variables
    - Move header to README.md.
  - import bestair tonometry.sas
    - Move header to README.md.
  - isolate pwv and augindex
    - Move header to README.md.
