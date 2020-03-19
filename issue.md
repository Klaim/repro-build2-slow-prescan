# Context

So far I only tested on Windows 10 because the issue I initially was attempting to reproduce was on Windows 10. I suspect it to be more difficult or even impossible to reproduce on other platforms because it involves performance/speed.
I was reproduced the error on a Microsoft Surface Book but didn't attempt to reproduce it elsewhere for the moment.

I'm using git bash so the commands are the same than on linux.

```
$ b --version
build2 0.12.0
libbutl 0.12.0
host x86_64-microsoft-win32-msvc14.2
Copyright (c) 2014-2019 Code Synthesis Ltd
This is free software released under the MIT license.
```

When I reproduce the error I was using
```
"C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview\VC\Tools\MSVC\14.26.28619\bin\Hostx64\x64\cl"
```
But I think it's probably not related to the compilation tools.


Beware: it seems to be a concurrency issue and pretty rare, the conditions explained below are not easy to reproduce and I'm not sure how to better reproduce this one.

How To Reproduce
----------------

0. You will need two separate consoles to run 2 builds of different projects in parallel.

1. Repro sources setup:
```
# CONSOLE A
git clone https://github.com/Klaim/repro-build2-slow-prescan.git mynodes
cd mynodes
git switch bug/build2-assertion-failure
./repro.sh
```

The `repro.sh` scripts will loop on `b clean udpate` 20 times and the output will be written in `output.txt`. (Note that the issue is reproductible with or without initializing the project in a separate configuration directory, so I skipped this step for simplicity.)

A this point, there is no visible problem, it's as fast as expected and there is no assertion failure (that I could trigger by doing this for a long time).

2. To trigger the issue, we need to have another project with a long pre-scan phase (everything before starting compilation) being built at the same time than our repro script.
At the moment the `master` branch fo the same repo have this property:
```
# CONSOLE B
git clone https://github.com/Klaim/repro-build2-slow-prescan.git longprescan
cd longprescan
git switch master
bdep init -C ../build-msvc cc
```

3. We are ready to reproduce the issue. Run these commands **in parallel** on the same computer:
```
# CONSOLE A
./repro.sh

#CONSOLE B
b
```

If you don't see the issue, before re-trying you need to `bdep deinit && bdep init` the `longprescan`, or change something in `node.in.hxx` to reproduce the long pre-scan. You can also just `b clean update` to go faster, the window to trigger the issue will just be shorter.

For me the issue appears about 1 time per 8 attempts.

Observed
--------

In `output.txt` (coming from the repro branch):
```
Assertion failed: !good_error, file C:\Users\jlamotte\Documents\build2\build2-toolchain-0.12\build2-0.12.0\libbuild2\cc\compile-rule.cxx, line 3717
```

Because it stops the build but the script keep retrying to build, I often see several occurences of this assertion failure once I manage to get it.

Observations
------------

- Beware: it obviously depends on the speed of the computer. I had time to try only on one computer and it's a Surface Book, which is pretty powerful but not as much as my other computers.
- Because of the random nature of the issue, you might need several attempts before seeing the assertion. On that machine I see it systematically at least once (often twice) in the output file each time I use the specified parametters.
- The "long pre-scan" build might just be impacting the processing speed. Although so far I managed to trigger the issue only when two builds of separate projects were ongoing.
- It seems that the issue only appear when the long-prescan project is still in the pre-scan (pre-compilation) phases.
- As this is very complex setup and random, many of my observations/assumptions might be totally wrong and I didn't look at what that failing assertion is checking.

