# Mock Models

This folder contains bundled USDZ files used by `SampleModelSeeder`.

The two original object-capture samples remain here. The architectural mockups
are generated in-repo as compact USDZ packages after reviewing public USDZ and
glTF sample sources. Apple's Quick Look gallery provides useful USDZ examples,
but its terms do not allow republishing those assets in this app bundle.

At runtime, `SampleModelSeeder` copies these resources into
`Documents/Imports/Sample-*` and creates imported `Models` records so they appear
in the Home library without mixing them into the captured-model filesystem
contract.
