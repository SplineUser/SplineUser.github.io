---
layout: post
title: "Expanding the Hunting Horizons using RIP Manipulation"
date: 2025-09-05
categories: research kernel-exploitation
---

**Expanding the Hunting Horizons using RIP manipulation for exposing
devices**

**Introduction:** Drivers expose devices using IoCreateDevice +
IoCreateSymbolicLink, However despite the presence of these APIs inside
of a driver, it doesn't necessarily mean that they are bound to expose
those drivers. There are many reasons why this might not work, It could
be a registry read fail that acts as some sort of check or maybe the
driver requires some other driver to be loaded and present for them to
expose their device

**Observation:** We tested the drivers in bulk using our automated
device enumeration python script and our driver collection script. In
total, we found 8650 different unique drivers based on signatures (refer
image 1). Of which we found 1226 drivers containing both of these API
calls at once. We found 1536 drivers that were signed and also had
either of the APIs in them. Over 509 drivers actually were loadable with
just 63 drivers exposing any devices, 36 of which were test devices we
accidently got drivers to expose through meeting up criteria, probably
loading a prerequisite driver. The remaining devices had a lot of
intersection as they were usually created by the same type of driver but
of different versions but had similar if not exactly the same IOCTL
function calls, making them duplicates for our hunting research. In
total, we found 10 unique devices of the total 8650 unique drivers we
had. That is just 0.115%, most of these drivers simply weren't signed
however. There existed the intersection of drivers which had both of the
API calls and drivers which were signed. Among which, most did not
expose the devices despite having the conditions to do so. Our
assumption is that they failed some pre-requisite check.  
  
Here is a clearer representation:

- **8650** Unique Drivers

- **1226** Contained both the API Calls

- **1536** Signed **AND** contained either of the APIs

- **509** Drivers loadable

- **63** Drivers exposing devices

- **36** were test devices

- **10** unique devices

- **0.115%** of the devices had unique devices for testing

<img src="{{'./assets/images/rip-manipulation/media/image25.png' | relative_url}}"
style="width:5.21875in;height:0.91667in" />

**Problem:** We clearly see the incredibly low yield of drivers that
actually end up exposing their devices. To increase our yield rate, we
are trying a new method to force these drivers to expose those hidden
devices in the intersection section as described above.

**Our methodology:** Since we can control the RIP pointer through our
MSR R/W vuln (A post will be published on this if not done yet), we will
attempt to utilize this primitive to point the RIP**\*** where we want
it to be.

**\*Note:** Since we are in kernel space, we cannot utilize ROP chaining
due to SMEP protection stopping any user-mode space stack to be read
from (which we control). More on this in a different post soon.

Since we are forced to only utilize ROP gadgets individually and no
chaining is permitted, our kernel CE capabilities are significantly
reduced. However, if we can expose these new drivers and test them out
for vulnerabilities, we could find 0-days that allow for Kernel Write.
Finally allowing us for greater kernel CE control.

Our approach consists of the following methods:

1.  List every driver in the intersection

2.  Find the offset where the device execution is set to be via
    IoCreateDevice shortly probably followed by IoCreateSymbolicLink

3.  Set the RIP in there using WinDBG for testing

4.  Use WinOBJ to check for any new devices

This approach is theoretical so far and will need to be tested to see if
this actually works or something like pre-conditions will block us, this
is also hugely dependent upon the drivers code and automating this could
be an issue however lets first try this manually to see if this even
works to begin with.

**  
The first attempt:** So the first attempt is supposed to be simple, we
found the function in Ghidra that has IoCreateDevice in it.

<img src="/assets/images/rip-manipulation/media/image4.png"
style="width:5.54167in;height:0.5in" />

We then looked at the offset inside of Ghidra:

<img src="/assets/images/rip-manipulation/media/image15.png"
style="width:3.34375in;height:0.46875in" />

We found the real offset by using the RVA - VA to get 0x3395b. To get
the base address of the driver, we utilized the lmDvm command to get the
information for our driver.

<img src="./assets/images/rip-manipulation/media/image19.png"
style="width:6.38542in;height:1.54167in" />

We confirmed if this was the right address by using the follow command
and comparing the result with the Ghidra output:

<img src="./assets/images/rip-manipulation/media/image1.png"
style="width:6.5in;height:0.52778in" />

They matched. So we set the RIP to
“<span class="mark">fffff802\`54e1395b” so it would call the function.
We used the following command for that:  
</span><img src="./assets/images/rip-manipulation/media/image18.png"
style="width:6.5in;height:0.95833in" /><span class="mark">  
  
As you can see, this approach crashed our VM \[Fatal System Error:
0x000000d1</span>

<span class="mark">(0xFFFFF80254E1395B,0x000000000000000D,0x0000000000000008,0xFFFFF80254E1395B)</span>

<span class="mark">\]</span>

<span class="mark">This clearly was just the first attempt to see what
would happen and as expected. Directly trying to execute this function
when our register values weren't properly configured would lead to this.
0xD1 is the “DRIVER_IRQL_NOT_LESS_OR_EQUAL” Error and was caused due to
bad register values. Lets try to observe what is actually happening
behind the scenes. Lets put a breakpoint on IoCreateDevice to see what
register values are passed in and whether we even reach that point or
not.  
  
We see the following function and where exactly the API call is present
at:  
</span><img src="./assets/images/rip-manipulation/media/image23.png"
style="width:6.5in;height:3.51389in" /><span class="mark">  
  
From Ghidra, we also discover the offset to be: 0x36a2eh. Lets set a
breakpoint there and restart the driver:  
</span>

<img src="./assets/images/rip-manipulation/media/image2.png"
style="width:6.5in;height:1.61111in" />

<span class="mark">We see that the function is never called to begin
with. Let's analyze the why:</span>

<span class="mark">  
We see the following function that are called in a step routine for
IRP_DISPATCH_TABLE:</span>

<img src="./assets/images/rip-manipulation/media/image14.png"
style="width:5.65625in;height:4.30208in" />

<span class="mark">Now we should confirm what param_1 + 0x30 actually
points to, from WinDBG we find the following at the breakpoint:</span>

<img src="./assets/images/rip-manipulation/media/image3.png"
style="width:6.5in;height:1.83333in" />

<span class="mark">R12 holds the param_1 value, lets dump the registers
to see what param_1 actually is:</span>

<img src="./assets/images/rip-manipulation/media/image22.png"
style="width:2.14583in;height:0.60417in" />

<span class="mark">Let's look at the address and its offset by
30:</span>

<img src="./assets/images/rip-manipulation/media/image16.png"
style="width:5.51042in;height:1.97917in" />

<span class="mark">This does not particularly look like a dispatch
table. Also we know “ffff8c87\`e756f950” will be stored inside RAX and
its +8 offset would be stored:</span>

<img src="./assets/images/rip-manipulation/media/image9.png"
style="width:5.69792in;height:0.46875in" />

<span class="mark">From the assembly code, we can see that the code
simply stores the pointer of the Function “IRP_CreateDevice” into
“ffff8c87\`e756f958”</span>

<span class="mark">From here, we see the IRP_CreateDevice function. This
could be an Induced Device Create routine. Therefore, we could attempt
to use the CreateFileW API call to make this driver expose the device.
The only problem is that we do not know what the device name is. Lets
use static analysis in Ghidra to possibly find it hardcoded.</span>

<img src="./assets/images/rip-manipulation/media/image20.png"
style="width:5.84375in;height:1.58333in" /><span class="mark">  
  
Here we see references to “DosDevices” and “DosDevices\\HCD”,
Interestingly enough, we see certain references to similar strings
inside of WinObj:  
</span><img src="./assets/images/rip-manipulation/media/image6.png"
style="width:6.5in;height:0.59722in" />

<span class="mark">However these are not the devices created by the
driver, more importantly, we see the mention of the string “RENESAS”
inside of the driver. We see potential device names such as
“RENESAS_USB3\\ROOT_HUB30&VID….” This indicates that the device name
potentially starts with “Global\\RENESAS_USB3”. We also see
“\\DosDevice\\HCD”  
  
Let’s attempt to force the creation of the device using the CreateFileW
API.</span>

<span class="mark">Before:  
</span><img src="./assets/images/rip-manipulation/media/image12.png"
style="width:1.85417in;height:0.27083in" /><span class="mark">  
After:</span>

<img src="./assets/images/rip-manipulation/media/image12.png"
style="width:1.85417in;height:0.27083in" /><span class="mark">  
  
Not a success. Let's analyze why this might be the case, from the code
section, we can see there is a conditional if statement that if
satisfied will trigger the section where the IRP_CreateDevice function
lives:  
</span><img src="./assets/images/rip-manipulation/media/image24.png"
style="width:5.14583in;height:0.40625in" /><span class="mark">  
From the looks of it, it seems to be looking for a magic value inside of
param_3. It wants param three to start with the following: “0x94 0x03
0x00”. Lets see what param_3 actually even is</span>

<img src="./assets/images/rip-manipulation/media/image7.png"
style="width:6.40625in;height:0.23958in" />

<img src="./assets/images/rip-manipulation/media/image5.png"
style="width:2.14583in;height:0.95833in" />

<span class="mark">We can see that param_3 is locally initialized and is
not under the control of the user. We also see that local_b8 has its
“magic numbers” hardcoded in there therefore, the actual if statement is
not really a barrier, we can confirm this by putting a breakpoint at the
if statement to see what it is actually doing at runtime.</span>

<span class="mark">Lets use “sxe ld:rusb3xhc” to set the breakpoint at
when our driver loads, we can then use “lmDvm rusb3xhc” to find its base
address and then set the breakpoint to the where we want it to go. For
our case, it will be at “fffff802\`76c9830d”. The breakpoint hit, so
let's see what's going on now.</span>

<span class="mark">From here we see that inside WinDBG, we successfully
hit:  
</span><img src="./assets/images/rip-manipulation/media/image17.png"
style="width:6.5in;height:0.375in" />

<span class="mark">Which corresponds to</span>

<img src="./assets/images/rip-manipulation/media/image11.png"
style="width:5.38542in;height:0.625in" />

<span class="mark">Therefore we can be certain that our param_3 aka the
local_b8 does pass this test. In fact after setting a breakpoint at the
exact line where IRP_CreateDevice is being initialized aka “\*(code
\*\*)(\*(longlong \*)(param_1 + 0x30) + 8) = IRP_CreateDevice;”, we
still see the breakpoint being hit. Therefore we can confirm that the
magic values are not the issues but instead it might be our approach to
having the driver expose the devices. From the code we know that the
function that exposes the devices aka IRP_CreateDevice is being hooked
to the Dispatch Table pointer of IRP_MJ_CREATE which is automatically
triggered by windows if we pass on a correct request with CreateFileW.
We can see if we can trigger the function by setting a breakpoint at
that offset.</span>

<img src="./assets/images/rip-manipulation/media/image21.png"
style="width:4.79167in;height:2.64583in" />

<span class="mark">We know the actual offset = RVA - VA → 0x32c50</span>

<span class="mark">Therefore, let’s setup a breakpoint at:</span>

<img src="./assets/images/rip-manipulation/media/image8.png"
style="width:3.10417in;height:0.58333in" />

<span class="mark">and run our python script using CreateFileW to
possibly call IRP_MJ_CREATE:</span>

<img src="./assets/images/rip-manipulation/media/image10.png"
style="width:6.11458in;height:1.57292in" />

<span class="mark">However we see no breakpoint being hit. Therefore we
can assume this function is not getting called through this approach.  
  
Lets see why that is:  
</span><img src="./assets/images/rip-manipulation/media/image25.png"
style="width:4.125in;height:1.51042in" /><span class="mark">  
We see there are only two instances of IoCreateSymbolicLink being
present, one of them being inside of the IRP_DeviceCreate Function,
therefore it does not expose the devices to user-mode. It's like a
chicken and egg situation, where to get the symbolicLink, we will need
to call the IRP_MJ_CREATE function which requires the device to be
exposed to usermode using IoCreateSymbolicLink.</span>

<span class="mark">Therefore to cause the driver to expose the device we
need something in the kernel using the CreateFileW API to get
IRP_MJ_CREATE to expose. This is probably done through a helper driver.
Considering we have RIP control. We could force execution of the code
however we require the proper register values that we are unable to dump
right now.</span>

<span class="mark">**Conclusion:** RIP Manipulation can allow us to
execute code that's usually hidden barriers like kernel callable only
IRP_MJ_CREATE which could allow for user-mode access to the IOCTL codes
however that requires careful manipulation of the registers so that they
store the appropriate values. While this could allow for forcing drivers
to expose devices. The success rate and even the methodology really
depends upon the driver itself.</span>

<span class="mark">**Future work:** Whilst the particular case of
**RUSB3XHC.sys** didn’t allow us to get the value of the registers
required for a successful call to the function “IRP_CreateDevice”.
Potentially looking at other drivers would allow us to provide a simple
PoC.</span>

<span class="mark">**Security Disclosure:** All the work was performed
inside an isolated lab environment and on systems we control. Please
ensure that you follow proper security etiquette whilst performing such
research.</span>

<span class="mark">Thank you for the read :DDDDDDDDDD</span>
