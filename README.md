# cakemake
A CMake toolchain for C/C++ projects

## Goals
cakemake is intended for use as a bridge and bootstrap toolchain for my
projects while the [motomoto](https://github.com/Matthewacon/motomoto) build
system is under development. In order to fulfill the needs of my projects,
cakemake aims to provide:
 1. An easy-to-use mimimal overhead development toolkit, including:
    - Build configurations
    - SAST
    - Testing and test reporting
    - Benchmarks and profiling
    - Packaging
 2. Support for as many compilers as possible (within reason)
 3. Support for as many platformas as possible (within reason)
 5. Integration with CI platforms and reusable automated workflows
 6. Equivalent pipelines for local development

Currently I only plan to add and maintain support for C and C++ projects,
however, if the need arises I may add support for other languages

## Documentation
TBD

## Attributions
 - Thanks [meme](https://github.com/meme) for the project name!

## License
This project is licensed under the [M.I.T. License](./LICENSE).
