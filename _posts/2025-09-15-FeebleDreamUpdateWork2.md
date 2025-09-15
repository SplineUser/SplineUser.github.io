---
layout: post
title: "Adding Kernel Primitves and Information Gathering: FeebleDream development PT-2"
date: 2025-09-15
categories: MalwareDevelopment FeebleDream
---

**<span class="mark">Making THE Malware:Working on the Feeble Dream Update (v3.0)</span>**

**<span class="mark">C. Kernel primitives (sKPE)</span>**

<span class="mark">**Introduction:** Our research has led us to discover
multiple drivers that could allow for kernel primitives. While it is not
the ultimate Kernel CE primitives. The primitives we found can still
allow for greater control and semi kernel level access. We will make a
driver-exec module that will use the IOCTLs and IRP for our sKPE. This
system should be adaptive so that even in case of new drivers being
used, It should still work just fine.</span>

<span class="mark">**Problem:** Currently our system only loads the
driver but doesn't allow users to send IRP to the vulnerable drivers.
Therefore, we need to develop a system that allows the user to send
IOCTL/IRP requests.</span>

<span class="mark">**Engineering:** We will use a similar strategy
except all we are creating is just a simple wrapper for the
DeviceIoControl API. Therefore, we will just make a header file with the
logic inside of it itself. We know for us to access a device, we need to
use the CreateFile API. Therefore, the first step would be to take the
input for the Device Name, convert that into an appropriate device name
and use the CreateFileA API for that.</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image9.png" alt="VisualStudioCode"
style="width:6.5in;height:0.59722in" />

<span class="mark">Next up will be the destructive IRP function that
will simply close the Handle once we are done with the IRP.</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image1.png" alt="VisualStudioCode"
style="width:6.35417in;height:1.17708in" />

<span class="mark">Now that we have our logic that will automatically
get the Handle to the device. We will now use the DeviceIoControl API
for sending our IOCTL code along with that user controllable buffer that
goes into the IRP at offset 0x18.</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image11.png" alt="VisualStudioCode"
style="width:6.5in;height:1.66667in" />

<span class="mark">Fortunately, Windows API takes care of the
complicated part of making the IRP kernel object and putting the user
input in that. We can just focus on creating the logic for our APT
tool.</span>

<span class="mark">**Testing:** So we are going to test the logic we
have created so far. Let's start with trying A and B first. Here is the
main
code:</span><img src="/assets/images/FeebleDreamUpdateWork2/image15.png" alt="VisualStudioCode"
style="width:5.44792in;height:1.59375in" />

<span class="mark">And this is the output:</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image8.png" alt="VisualStudioCode"
style="width:5.29167in;height:0.32292in" />

<span class="mark">We see that the Log function does work, now we just
need to fix this issue. 1060 means that the code wasn't able to find the
service. Which does make sense considering we didn’t really use the
CreateDriverService Function, Lets add that inside of the DriverLoad
function.</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image7.png" alt="VisualStudioCode"
style="width:6.5in;height:1.54167in" />

<span class="mark">This code will now try to create the service if it
doesn't exist. After running the code:</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image2.png" alt="VisualStudioCode"
style="width:6.36458in;height:0.57292in" />

<span class="mark">We see our issue got fixed but now we are getting the
error 2 i.e. windows cant find the path. Therefore lets add the
following code which will make the proper path and also check if the
file exists to begin with:</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image6.png" alt="VisualStudioCode"
style="width:6.5in;height:1.79167in" />

<img src="/assets/images/FeebleDreamUpdateWork2/image10.png" alt="VisualStudioCode"
style="width:5.29167in;height:1.17708in" />

<span class="mark">Lets try and run this now:</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image5.png" alt="VisualStudioCode"
style="width:6.5in;height:0.79167in" /><span class="mark">  
</span><img src="/assets/images/FeebleDreamUpdateWork2/image13.png" alt="VisualStudioCode"
style="width:5.8125in;height:1.58333in" />

<span class="mark">It's successful! Therefore, both A and B seem to be
working just fine right now. Now, we can move to the IOCTL logic and
check if that seems to be working aswell. Okay lets see what happens
when we try the following code. Okay, there seems to be no errors. We
can even confirm the following inside of WinDBG since the IOCTL is a
kernel write primitive therefore we can observe the actual output of
this however I am pretty certain that this did in fact work. So to
quickly recap, we have made a system that can load a driver and send it
IOCTL based DeviceIoControl input which goes into the IRP buffer and
allows us to exploit the vulnerable code.</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image12.png" alt="VisualStudioCode"
style="width:6.5in;height:2.04167in" />

<img src="/assets/images/FeebleDreamUpdateWork2/image4.png" alt="VisualStudioCode"
style="width:6.29167in;height:0.79167in" />

**<span class="mark">D. System Info Gathering Logic</span>**

<span class="mark">**Introduction:** FDv1 had basic capabilities for
information gathering, it found information such as whether the user was
privileged and the OS version. FDv2 didn’t have any information
gathering capabilities. However, FDv3 does require info gathering
capabilities because it aims for further privilege escalation and
information such as PCI Device present, the base address of NtOsKrnl, OS
version, presence of softwares and bios settings like DMA protection and
secure boots will all be incredibly helpful. There is the additional
benefit of making things user friendly. A simple method for gathering
basic information such as IP Address, Hostname etc could be useful. This
isn't necessarily an info stealer, which will be a separate module just
like the cryptominer. A working automatic method for attaining and then
transferring sensitive information to the C2, that is something that
will be worked on in the future however currently, we just require a
system that will send necessary information to the C2.</span>

<span class="mark">**Problem:** Our APT simulation tool currently lacks
a Info gathering module which could be used for further privilege
escalation. Therefore we need to create a system that can gather key
information silently and relay that to the C2 and/or take actions based
on the information given.</span>

<span class="mark">**Engineering:** Interestingly, almost all the
information we need is present inside of msinfo32.exe. Therefore we can
probably use COM to gather system information similar to how
msinfo32.exe does it. We are going to use a similar approach to what we
were doing. Lets create the header file first:</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image14.png" alt="VisualStudioCode"
style="width:4.3125in;height:2.51042in" />

<span class="mark">This will be the structure that we will utilize for
the GSI (Get System Information) class with the cpp file containing the
logic:</span>

<img src="/assets/images/FeebleDreamUpdateWork2/image3.png" alt="VisualStudioCode"
style="width:6.5in;height:2.84722in" />

<span class="mark">**Conclusion:** We were able to finish the driver
loading + IOCTL logic, now we can actually use our own 0-day drivers for
sKPE and also have equipped the driver for gathering system information
that could be necessary for us for further LPE.</span>

<span class="mark">**Future Work:** In terms of capabilities, we could
work on a plugin system using DLLs and then make an infostealer module.
Besides that, we could carry out code cleanup for the back.cpp file
which is a mess right now. The UI/UX for the client side needs to also
be developed along with making the shellcode system for proper bitwise
flags.</span>

<span class="mark">**Security Disclosure:** All the work was performed
inside an isolated lab environment and on systems we control. Please
ensure that you follow proper security etiquette whilst performing such
research.</span>
