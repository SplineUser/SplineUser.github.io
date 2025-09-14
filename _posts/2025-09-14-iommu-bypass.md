---
layout: post
title: "IOMMU Bypass: Finding Potential Misconfiguration"
date: 2025-09-14
categories: research kernel-exploitation
---

**<span class="mark">IOMMU Bypass: Finding potential
misconfigurations</span>**

<span class="mark">**Introduction:** IOMMU abbreviation for Input Output
Memory Management Unit is a hardware component present in the chipset
that helps with mapping the virtual memory address provided by a
peripheral device into the actual memory address. Our vulnerability
research has found out a driver that allows user-mode applications to
write into the PCI Configuration Space for Peripherals, The PCI
Configuration contains the Base Address Registers which we now can write
into to force the device to write onto those Addresses instead of their
default ones. This can lead to critical infrastructure memory
overwriting. However, IOMMU maps out the Direct Memory Accessible space
for these peripherals. Since IOMMU is hardware based such as Intel VT-d
and AMD-Vi and can only be enabled/disabled through the BIOS. We require
a way to instead look for misconfiguration</span>

<span class="mark">**Observation:** IOMMU status can be found out using
msinfo32 with the item name being “Kernel DMA Protection”. We looked at
10 different user personal computers and found that all of them had this
Item value to be “On”. Therefore, we can conclude almost **all the
personal computers** have IOMMU protection for hotplug/thunderbolt
devices to be true by default, a rate of **100%**. Since IOMMU is
incredibly common, we will have to look for misconfiguration in these
devices so that this could potentially be exploited.</span>

<img src="/assets/images/iommu-bypass/image2.png"
style="width:3.64583in;height:0.28125in" />

<span class="mark">**Problem:** Having a strong kernel-level primitive
like PCI Config space R/W for peripherals are heavily constrained due
this hardware based protection. Bypassing IOMMU could allow for
primitives greater than just DoS possibility. Fixing this issue could
grant us stronger primitives such as kernel memory overwrite and
corruption.</span>

<span class="mark">**Methodology:** Since IOMMU is turned on, we should
first try to look for the IOMMU mapping. Fortunately manufacturers use
ACPI (Advanced Configuration and Power Interface) for
Firmware–Hardware–OS communication. ACPI exposes certain tables in the
memory which the OS can use to look at the status of the hardware. The
table we are interested in is the DMAR table (DMA Remapping Table), The
DMAR tells us what memory ranges are allowed by the firmware for devices
to access via DMA. Therefore, we should first try to read the DMAR
table. Fortunately, we have an extremely useful tool called ACPIDMUP.EXE
which we will utilize for dumping every ACPI Table.</span>

<img src="/assets/images/iommu-bypass/image4.png"
style="width:5.03125in;height:6.71875in" />

<span class="mark">Through this, we were able to get the dmar.dat file
which we converted into the .dsl extension for reading.</span>

<img src="/assets/images/iommu-bypass/image5.png"
style="width:6.5in;height:0.75in" />

<span class="mark">The DMAR table consists of two types, The RMRR and
the DRHD. The RMRR is the Reserved Memory Region Reporting which tells
us what section of the memory has been reserved for certain devices.
From our dump, we can clearly see this:</span>

<img src="/assets/images/iommu-bypass/image7.png"
style="width:6.5in;height:1.34722in" />

<img src="/assets/images/iommu-bypass/image1.png"
style="width:6.5in;height:1.38889in" />

<span class="mark">These sections are interesting because they are
reserved by the firmware for these two devices so that they can DMA into
these sections without requiring the normal IOMMU translation. These two
ranges are device specific, therefore this range isn't the universal
IOMMU DMA Translation accessible range but rather just for the two
devices we see. This is still a very interesting option for us because
if any of these memory regions contain anything system critical then
that could allow for memory overwriting. Let's see if there exists some
sort of misconfiguration.</span>

<span class="mark">Our approach right now would be to use WinPmem.exe to
write the current memory into disk, we could then look through the raw
disk file for anything interesting inside those memory sections we
see.</span>

<img src="/assets/images/iommu-bypass/image6.png"
style="width:6.5in;height:0.97222in" />

<span class="mark">After we got the .raw disk file. We used a python
script to check for any interesting memory sections containing anything
which might be interesting however we didn't find anything in
there</span>

<img src="/assets/images/iommu-bypass/image3.png"
style="width:6.5in;height:1.11111in" />

<span class="mark">This output does make sense as these memory regions
have been reserved for the peripheral devices and it would be weird for
there to exist any PE files in there or literally anything that is not a
bunch of 00s.</span>

<span class="mark">**Conclusion:** Therefore for this particular
instance of the two peripherals we looked at, we can conclude that no
obvious misconfigurations exist there. However there might exist other
DMA capable devices that might be mapped into a critical kernel area
where we can control the BARs using our PCI R/W capabilities. This could
lead to memory overwriting. This was just a simple PoC approach for
looking for misconfigurations</span>

<span class="mark">**Future Work:** Looking at the memory range of other
devices and checking if those ranges contain anything critical and
sensitive would be the next approach.</span>

<span class="mark">**Security Disclosure:** All the work was performed
inside an isolated lab environment and on systems we control. Please
ensure that you follow proper security etiquette whilst performing such
research.</span>

<span class="mark">Thank you for reading :D :D :D :D :D :D :D :D</span>


