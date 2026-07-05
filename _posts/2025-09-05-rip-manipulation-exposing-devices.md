---
layout: post
title: "Expanding the Hunting Horizons using RIP Manipulation"
date: 2025-09-05
categories: [Research, Windows Internals]
tags: [kernel, drivers, RIP, WinDBG, Ghidra, windows]
description: "Using RIP register manipulation via an MSR R/W vulnerability to force hidden drivers to expose their devices — methodology, observations, and findings."
---

## Introduction

When hunting for vulnerable Windows drivers, one of the first practical questions is simple: does the driver expose a reachable interface that user mode can talk to?

At a static level, this can look straightforward. If a driver references APIs such as IoCreateDevice and IoCreateSymbolicLink, it may appear to have the ingredients needed to expose a device object and a symbolic link for user-mode access. In practice, however, those references are only weak signals. Device exposure can depend on registry configuration, hardware presence, helper drivers, initialization order, or vendor-specific runtime checks. A driver can contain the relevant code and still never expose a usable interface in a normal lab environment.

This became a bottleneck during my driver-hunting pipeline. Across a corpus of 8,650 unique driver samples, only a very small number produced unique reachable device interfaces during dynamic testing. That raised a useful research question: if device-creation logic exists inside a driver but is not reached naturally, can controlled kernel-mode execution redirection be used to reach those hidden paths?

This post explores that question through a case study on RUSB3XHC.sys. Using a controlled lab primitive for RIP redirection, I attempted to redirect execution toward suspected device-creation code and then validate whether a new user-accessible interface appeared. The result was negative, but useful: simply redirecting RIP into a suspected function was not enough. The driver still expected specific calling context, register state, initialized structures, and dispatch-path behavior.

The main takeaway is that forced device exposure is not a generic “jump to IoCreateDevice” problem. It is a driver-specific reachability and state-reconstruction problem. This post walks through the corpus observation, the hypothesis, the failed attempts, and the lessons learned for future driver-hunting automation.

## Corpus Collection & Results

Before trying to force any hidden device-creation paths manually, we first wanted to understand how often drivers in our collection actually exposed reachable user-mode interfaces under normal testing.

We tested the drivers in bulk using our automated driver collection pipeline and a Python-based device enumeration script. In total, we collected 8,650 unique driver samples, deduplicated by SHA-256 hash.

From there, we looked for drivers that referenced the usual device-creation APIs, mainly IoCreateDevice and IoCreateSymbolicLink, and then compared those static signals against what actually became reachable after attempting to load the drivers in our lab environment.

The results looked like this:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image18.png' | relative_url }}" alt="image18">

</figure>

This shows the core problem clearly: out of 8,650 unique driver samples, only 10 unique device interfaces were useful for testing. That gives us a final yield of roughly 0.115%.

The low yield suggests that static references to IoCreateDevice and IoCreateSymbolicLink are not enough by themselves. A driver can contain the right APIs, be signed, and even be loadable, while still failing to expose a usable device interface at runtime.

Our assumption is that many of these drivers are gated behind some kind of prerequisite check. This could be a registry read (such as the ones made during installation with a .inf file), hardware presence check, dependency on another driver, initialization order requirement, or some other vendor-specific condition that prevents the device-creation path from being reached in a normal lab setup.

That gap between “the device-creation code exists” and “the device is actually reachable from user mode” is what motivated the next part of the research: can we use controlled kernel-mode RIP redirection to reach device-creation paths that are present in the driver, but not naturally reached during normal loading?

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image25.png' | relative_url }}" alt="Figure 1 — Driver collection summary.">

  <figcaption>Figure 1 — Driver collection summary.</figcaption>

</figure>

## Problem Statement

The corpus results show the core problem: even when a driver is signed, loadable, and contains references to device-creation APIs, it still may not expose a reachable user-mode device interface.

For driver vulnerability research, this creates a major bottleneck. If the device interface is never exposed, then the IOCTL surface cannot be reached through normal user-mode testing. This means that a large number of drivers may appear interesting during static analysis, but still produce no usable testing surface during dynamic analysis.

The important gap is between “the device-creation code exists” and “the device is actually reachable from user mode.” The rest of this post explores whether that gap can be tested manually by redirecting execution toward suspected device-creation paths.

## Research Hypothesis

The hypothesis is simple: if a driver contains a device-creation path that is present in the binary but not naturally reached during normal loading, controlled kernel-mode RIP redirection may allow us to reach that path manually.

The goal is not to claim that this technique works generically across every driver. The goal is to test whether RIP redirection can be used as a research primitive for device-exposure testing. If we can redirect execution toward a suspected IoCreateDevice / IoCreateSymbolicLink path and satisfy the expected runtime state, we may be able to expose device interfaces that would otherwise remain unreachable through normal user-mode testing.

The more important question is where this approach breaks. Is the problem simply that the target code path is not being reached, or does the driver require specific register values, initialized structures, hardware state, registry values, or helper-driver interaction before the device-creation path can execute successfully?

## Lab Setup and Constraints

For this experiment, we had two possible primitives available for controlling RIP in our lab environment.

The first was an MSR read/write primitive which, with HVCI disabled, allowed us to redirect execution through the IA32_LSTAR pointer. The second was a separate control-flow hijack primitive caused by a signed AMD driver passing a user-controlled IOCTL buffer into a function pointer call. For this writeup, we focus only on the MSR read/write path.

The idea was to use this primitive to redirect RIP toward a suspected device-creation path inside the target driver and then check whether a new device interface appeared through WinObj or our device enumeration script.

There are important limitations here. With the current primitive, user-controlled ROP chaining is not practical. SMEP prevents supervisor-mode execution from user pages, and in this setup we do not have clean control over a trusted kernel stack or a reliable stack pivot target. Because of that, this experiment focuses on direct RIP redirection into individual target locations rather than a full kernel ROP chain.

This limitation matters because reaching the target address is only one part of the problem. The target function may still expect a valid calling context. This could include specific register values, initialized structures, object pointers, or previous driver state. If those conditions are not satisfied, then the result is likely to be a crash rather than successful device exposure.

## Experimental Plan

The manual approach for testing this was straightforward:

- List the drivers in the signed, loadable, device-API overlap set.

- Use Ghidra to find functions that reference IoCreateDevice and, ideally, IoCreateSymbolicLink.

- Calculate the relevant RVA for the suspected device-creation path.

- Use WinDbg to find the loaded base address of the driver and resolve the runtime address.

- Redirect RIP toward the suspected path inside the lab environment.

- Use WinObj and our device enumeration script to check whether a new device interface appeared.

- If the attempt failed, debug whether the issue was reachability, register state, initialized structures, or some other driver-specific precondition.

At this stage, the approach was still theoretical. The main purpose of the first test was to see whether direct RIP redirection was enough to expose a hidden device interface, or whether the driver would require additional state reconstruction before the target path could execute correctly.

## Case Study: RUSB3XHC.sys

For the first manual test, we picked RUSB3XHC.sys as the target driver. The goal was to start with a simple case study: find the function that contains the IoCreateDevice call, resolve the runtime address, redirect RIP there, and then check whether the driver exposes a new device interface.

This section walks through the attempts, the crashes, the breakpoint analysis, and the final reason this specific driver did not expose a usable interface through our approach.

### Attempt 1: Direct RIP Redirection

The first attempt was supposed to be simple. We found the function in Ghidra that contained the IoCreateDevice call.

We then looked at the offset inside of Ghidra:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image22.png' | relative_url }}" alt="Figure 2 — IoCreateDevice reference in Ghidra.">

  <figcaption>Figure 2 — IoCreateDevice reference in Ghidra.</figcaption>

</figure>

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image15.png' | relative_url }}" alt="Figure 2 — IoCreateDevice reference in Ghidra.">

  <figcaption>Figure 2 — IoCreateDevice reference in Ghidra.</figcaption>

</figure>

From there, we calculated the relevant RVA for the target location. In this case, the offset came out to 0x3395b. To get the runtime address, we used WinDbg’s lmDvm command to get the loaded base address of the driver.

We confirmed that this was the correct address by using the following command and comparing the result with the Ghidra output:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image10.png' | relative_url }}" alt="Figure 3 — Runtime address validation in WinDbg.">

  <figcaption>Figure 3 — Runtime address validation in WinDbg.</figcaption>

</figure>

The output matched. So, for the first test, we set RIP to fffff802`54e1395b so execution would land at the suspected target location. We used the following command for that:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image9.png' | relative_url }}" alt="Figure 4 — RIP redirected to the suspected path.">

  <figcaption>Figure 4 — RIP redirected to the suspected path.</figcaption>

</figure>

As expected, this crashed the VM:

```text
Fatal System Error: 0x000000d1 (0xFFFFF80254E1395B, 0x000000000000000D, 0x0000000000000008, 0xFFFFF80254E1395B)
```

This was not too surprising. This was the first attempt, and the goal was mainly to see what would happen if we directly redirected execution into the suspected device-creation path. Since the expected register values and calling context were not properly configured, the function did not have the state it needed to execute safely.

The bugcheck was 0xD1, also known as DRIVER_IRQL_NOT_LESS_OR_EQUAL. In this case, the likely issue was not that the target address was wrong, but that directly landing inside the function without reconstructing the expected context caused the driver to access invalid state.

### Result 1: Calling Context Matters

The crash gave us the first useful result: reaching the target address is not enough.

If we redirect RIP into a function that expects specific register values, initialized structures, object pointers, or previous driver state, then the function may immediately fail. This means direct RIP redirection is only useful if the target path can tolerate the current context, or if we can reconstruct enough of the expected state before calling it.

So instead of continuing to blindly redirect RIP, the next step was to observe what the driver was naturally doing. Specifically, we wanted to know whether the normal load path ever reached IoCreateDevice, and if it did, what values were being passed around at runtime.

## Tracing the Natural IoCreateDevice Path

We found the function where the API call was present:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image1.png' | relative_url }}" alt="Figure 5 — Suspected IoCreateDevice callsite.">

  <figcaption>Figure 5 — Suspected IoCreateDevice callsite.</figcaption>

</figure>

From Ghidra, we also found the relevant offset to be 0x36a2e. We then set a breakpoint there and restarted the driver:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image24.png' | relative_url }}" alt="Figure 6 — Breakpoint on the suspected callsite.">

  <figcaption>Figure 6 — Breakpoint on the suspected callsite.</figcaption>

</figure>

The breakpoint was never hit. This told us that the function was not being called during the normal driver load path.

So the next question became: why is this device-creation path not being reached?

## Finding the Suspected IRP_MJ_CREATE Path

Looking further, we found a function involved in setting up what looked like the IRP dispatch flow:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image8.png' | relative_url }}" alt="Figure 7 — Dispatch setup routine.">

  <figcaption>Figure 7 — Dispatch setup routine.</figcaption>

</figure>

At this point, we wanted to understand what param_1 + 0x30 was actually pointing to. From WinDbg, we reached the relevant breakpoint and started inspecting the runtime state.

R12 was holding the param_1 value, so we dumped the registers to see what param_1 actually was:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image22.png' | relative_url }}" alt="Figure 8 — Register dump for param_1.">

  <figcaption>Figure 8 — Register dump for param_1.</figcaption>

</figure>

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image6.png' | relative_url }}" alt="Figure 8 — Register dump for param_1.">

  <figcaption>Figure 8 — Register dump for param_1.</figcaption>

</figure>

Then we looked at the address at param_1 + 0x30:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image12.png' | relative_url }}" alt="Figure 9 — Inspecting param_1 + 0x30.">

  <figcaption>Figure 9 — Inspecting param_1 + 0x30.</figcaption>

</figure>

This did not particularly look like a normal dispatch table at first. However, we also knew that ffff8c87`e756f950 would be stored inside RAX, and its +8 offset would be used next:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image21.png' | relative_url }}" alt="Figure 10 — Pointer assignment target.">

  <figcaption>Figure 10 — Pointer assignment target.</figcaption>

</figure>

From the assembly, we can see that the code stores the pointer to the IRP_CreateDevice function into ffff8c87’e756f958.

This made the path more interesting. The driver was not simply calling the device-creation function directly during initialization. Instead, it looked like IRP_CreateDevice was being placed into a dispatch-related structure, potentially as a create routine.

From here, we inspected the IRP_CreateDevice function itself. This looked like it could be an induced device-creation routine. If that was true, then we could try to trigger it through a user-mode open attempt using CreateFileW.

The immediate problem was that we did not know the correct device name. So, we went back into Ghidra and searched for hardcoded device-related strings.

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image19.png' | relative_url }}" alt="Figure 11 — Device strings in Ghidra.">

  <figcaption>Figure 11 — Device strings in Ghidra.</figcaption>

</figure>

Here, we saw references to DosDevices and DosDevices\\HCD. Interestingly enough, we also saw similar-looking entries inside WinObj:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image17.png' | relative_url }}" alt="Figure 12 &amp; 13 — Similar names in WinObj.">

  <figcaption>Figure 12 & 13 — Similar names in WinObj.</figcaption>

</figure>

However, these did not appear to be devices created by this driver. More importantly, we saw references to RENESAS inside the driver. There were potential device names such as RENESAS_USB3\\ROOT_HUB30&VID..., which suggested that the device name may start with something like Global\\RENESAS_USB3. We also saw a reference to \\DosDevices\\HCD.

### Attempt 2: Triggering the Path from User Mode

With these strings in mind, we attempted to trigger the suspected path from user mode.

Before:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image3.png' | relative_url }}" alt="Figure 14 — Device namespace before the trigger.">

  <figcaption>Figure 14 — Device namespace before the trigger.</figcaption>

</figure>

After:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image3.png' | relative_url }}" alt="Figure 15 — Device namespace after the trigger.">

  <figcaption>Figure 15 — Device namespace after the trigger.</figcaption>

</figure>

This was not successful. No new device interface appeared.

At this point, we needed to understand whether the failure was because of the device name, a missing prerequisite, or the wrong execution path entirely.

## Checking the Magic-Value Condition

Looking back at the code, we saw a conditional check that guarded the section where the IRP_CreateDevice function lived:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image2.png' | relative_url }}" alt="Figure 16 — Conditional check before setup.">

  <figcaption>Figure 16 — Conditional check before setup.</figcaption>

</figure>

From the decompiler output, it looked like the function expected a magic value inside param_3. Specifically, it appeared to check whether param_3 started with the bytes 0x94 0x03 0x00.

So the next question was: what is param_3, and is it actually under our control?

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image14.png' | relative_url }}" alt="image14">

</figure>

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image11.png' | relative_url }}" alt="Figure 17 — Inspecting param_3.">

  <figcaption>Figure 17 — Inspecting param_3.</figcaption>

</figure>

We can see that param_3 is locally initialized and does not appear to be directly controlled from user mode. We also see that local_b8 contains the expected magic bytes hardcoded inside the function. Therefore, the conditional check itself may not actually be the barrier.

To confirm this, we set a breakpoint on the conditional check and observed what happened at runtime.

We used sxe ld:rusb3xhc to break when the driver loaded. Then we used lmDvm rusb3xhc to find the loaded base address and set a breakpoint at the target location. In this case, the resolved address was fffff802`76c9830d.

The breakpoint hit, so we inspected the runtime state.

Inside WinDbg, we successfully hit the following location:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image7.png' | relative_url }}" alt="Figure 18 — Breakpoint hit before the check.">

  <figcaption>Figure 18 — Breakpoint hit before the check.</figcaption>

</figure>

Which corresponds to the following location in Ghidra:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image20.png' | relative_url }}" alt="image20">

</figure>

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image4.png' | relative_url }}" alt="Figure 19 — Matching Ghidra location.">

  <figcaption>Figure 19 — Matching Ghidra location.</figcaption>

</figure>

Therefore, we can be certain that param_3, or more specifically the locally initialized local_b8, passes this check.

In fact, after setting a breakpoint at the exact line where IRP_CreateDevice was being initialized:

```c
*(code **)(*(longlong *)(param_1 + 0x30) + 8) = IRP_CreateDevice;
```

We still saw the breakpoint being hit.

So the magic values were not the issue. The more likely issue was our approach to getting the driver to expose the device interface.

### Attempt 3: Breaking on IRP_CreateDevice

From the code, it looked like the function responsible for device creation, IRP_CreateDevice, was being attached to a dispatch path that appeared related to IRP_MJ_CREATE. In a normal user-mode flow, this kind of path would usually be triggered when a correct request is made through CreateFileW.

To test that, we set a breakpoint directly on the IRP_CreateDevice function and then ran our Python script to try to open the suspected device name.

We calculated the relevant offset as 0x32c50.

Then we set the breakpoint at the resolved runtime address:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image5.png' | relative_url }}" alt="Figure 20 — Breakpoint on IRP_CreateDevice.">

  <figcaption>Figure 20 — Breakpoint on IRP_CreateDevice.</figcaption>

</figure>

After that, we ran the Python script using CreateFileW to try to trigger the IRP_MJ_CREATE path:

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image23.png' | relative_url }}" alt="Figure 21 — User-mode trigger attempt.">

  <figcaption>Figure 21 — User-mode trigger attempt.</figcaption>

</figure>

<figure>
  <img src="{{ '/assets/images/rip-manipulation/media/image16.png' | relative_url }}" alt="Figure 21 — User-mode trigger attempt.">

  <figcaption>Figure 21 — User-mode trigger attempt.</figcaption>

</figure>

Although some candidate names returned valid handles, the breakpoint on IRP_CreateDevice was not hit. This suggests that these opens were not reaching the target routine we were trying to trigger.

### The Device Exposure Deadlock

At this point, we looked again at the symbolic link creation path.

There were only two instances of IoCreateSymbolicLink present. One of them was inside the IRP_CreateDevice function itself. This creates a chicken-and-egg problem: to reach the device from user mode, we need a symbolic link, but the symbolic link appears to be created inside a path that we cannot reach from user mode unless the device is already exposed.

In other words, this does not look like a simple user-mode CreateFileW trigger path.

The more likely explanation is that this routine is triggered by another kernel-mode component, possibly a helper driver or some kernel-mode equivalent create/open path. Since we do have RIP control, we could still attempt to redirect execution into this code manually. However, the first crash already showed the main problem: we would need the proper register values and expected runtime structures for the function to execute safely.

At this stage, we were unable to recover the full calling context required for a successful call into IRP_CreateDevice. So, for this driver, direct RIP redirection was not enough to expose the device interface.

### Takeaway from this Case Study

The important takeaway from this attempt is that the barrier was not simply the presence of a magic value or the existence of the device-creation function.

The target path existed. The magic-value check passed. The function pointer assignment happened. However, the path still was not reachable through our user-mode trigger attempt, and direct RIP redirection crashed without the correct runtime state.

So for RUSB3XHC.sys, the real problem was reachability and state reconstruction. Getting the driver to expose the device interface required more than just landing RIP at the right address. The driver expected a specific calling context, and without that context, the approach failed.

This does not invalidate the broader idea, but it does narrow it. Forced device exposure is not a generic “jump to IoCreateDevice” problem. It is a driver-specific problem involving control flow, initialized state, dispatch behavior, and the exact context expected by the target routine.

## Lessons Learned

The main lesson from this case study is that RIP redirection can get us to interesting code, but it does not automatically give us a valid execution context.

In the case of RUSB3XHC.sys, the device-creation path did exist. We found the relevant IoCreateDevice / IoCreateSymbolicLink related logic, we identified the suspected IRP_CreateDevice routine, and we confirmed that some of the conditional checks were not the actual barrier. However, directly redirecting RIP into the suspected path still crashed the VM because the expected register values and runtime structures were not properly configured.

This means the problem is not just “can we reach the code?” The more important problem is “can we reach the code with the state it expects?”

That distinction matters. A driver may contain the right device-creation code, but that code may depend on a very specific calling path. It may expect initialized structures, specific object pointers, helper-driver interaction, hardware state, registry values, or some other driver-specific setup. Without that context, the function may not behave correctly even if we land RIP at the right address.

So, for this driver, forced device exposure was not a simple “jump to IoCreateDevice” problem. It was a reachability and state-reconstruction problem.

## Limitations

This was a single-driver case study, not a generic proof that this method works across all drivers.

The test case, RUSB3XHC.sys, did not allow us to successfully expose a new user-mode device interface through direct RIP redirection. We were able to identify interesting device-creation logic and understand more about why the path was not naturally reachable, but we were not able to recover the full register and structure state needed for a successful call into IRP_CreateDevice.

The lab setup also used a controlled kernel-mode redirection primitive with HVCI disabled. This makes the experiment useful for research and methodology development, but it should not be treated as a claim that the same approach applies unchanged to fully hardened production environments.

Another limitation is automation. Even if this approach works against some drivers, the methodology is likely to be highly driver-dependent. Each target may require different register values, object pointers, initialization state, and triggering conditions. That makes generic automation difficult unless the device-creation patterns can first be classified.

## Future Work

The next step is to test this methodology against more drivers from the signed, loadable, device-API overlap set.

The RUSB3XHC.sys case showed that direct RIP redirection is not enough when the target function expects a specific calling context. However, other drivers may have simpler device-creation paths with fewer prerequisites. Those would be better candidates for a working proof of concept.

Future work will focus on:

- Testing more drivers that contain both IoCreateDevice and IoCreateSymbolicLink.

- Classifying the different patterns used for device creation.

- Identifying drivers where the device-creation function requires minimal external state.

- Automating the mapping between Ghidra-discovered callsites and WinDbg runtime breakpoints.

- Recovering the expected register and structure state for candidate device-creation routines.

- Comparing drivers that expose devices naturally against drivers that contain the APIs but fail to expose anything during normal loading.

The main goal is to understand which drivers are actually good candidates for forced device-exposure testing, and which ones are too dependent on driver-specific runtime state to be useful.

## Security Disclosure

All work was performed inside an isolated lab environment on systems under our control.

The goal of this research is to improve Windows driver research methodology and better understand why some drivers expose reachable device interfaces while others do not. This post does not target any third-party system, and the techniques discussed here should only be used in controlled environments where you have explicit permission to perform this kind of testing.

Please follow proper security etiquette while performing similar research.

## Conclusion

This research started with a simple problem: our driver-hunting pipeline had an extremely low yield. Even though many drivers contained references to IoCreateDevice and IoCreateSymbolicLink, very few actually exposed reachable user-mode device interfaces during normal testing.

To explore whether that yield could be improved, we tested whether controlled kernel-mode RIP redirection could be used to reach hidden or normally unreachable device-creation paths.

For RUSB3XHC.sys, the result was negative, but still useful. The target path existed, and parts of it were reachable during initialization, but directly redirecting execution into the suspected device-creation routine was not enough. The function expected a specific runtime context that we were not able to fully reconstruct.

The final takeaway is that forced device exposure is not a generic “jump to the right function” technique. It is a driver-specific reachability problem. RIP control may help us reach interesting code, but successful execution still depends on the correct register state, initialized structures, dispatch flow, and prerequisite conditions expected by the driver.

That makes the approach more limited, but also more interesting. If we can identify drivers with simpler creation paths and fewer state requirements, this technique may still help expand the reachable IOCTL surface available for future driver vulnerability research.
