**<span class="mark">Working on the Feeble Dream Update (v3.0)</span>**

**<span class="mark">A. Logging System</span>**

<span class="mark">**Introduction:** For debugging and information
gathering, we will introduce a logging system that can be initialized by
a global flag. The logging system will log the result of every major
step in the execution of the code. The logging result could be shared to
the attacker optionally. The main aim is for debugging the code and
actually seeing what's going on.</span>

<span class="mark">**Problem:** Currently we utilize simple msgbox API
calls for our logging in case of errors however, this is obviously
suboptimal and only for test purposes. Therefore to improve this. We
shall introduce a much better system for logging.</span>

**<span class="mark">Engineering:</span>** We will use modulization and
create LogStrategy.cpp and LogStrategy.h

<img src="./assets/images/FeebleDreamUpdateWork/media/image6.png"
style="width:2.17708in;height:0.75in" />

Next, we will define the variables and functions inside the
LogStrategy.h file, we will use OOP encapsulation for public/private
methods.

<img src="./assets/images/FeebleDreamUpdateWork/media/image2.png"
style="width:6.5in;height:1.33333in" />

From here, we will create the logic of these functions inside of the
LogStrategy.CPP. Let's go through all these functions, one by one.
*EnableLogging* Function simply set the global Function IsLogEnabled to
True, it will take in an input and set that as the value of
IsLogEnabled.

<img src="./assets/images/FeebleDreamUpdateWork/media/image3.png"
style="width:2.95833in;height:0.86458in" />

Next up will be the CreateLogFile Function, which simply will create the
log file for us to write in. Well, at least right now, perhaps later on,
we will change this to send the log to the attacker without writing
anything to the disk.

<img src="./assets/images/FeebleDreamUpdateWork/media/image9.png"
style="width:6.5in;height:1.61111in" />

It has the optional name value for the log file name. The default would
be DFT.log (DFT → Default)

And at last, we have the Log Function that will actually append the the
log values into the log file we created:

<img src="./assets/images/FeebleDreamUpdateWork/media/image5.png"
style="width:6.5in;height:2.47222in" />

**Note:** Forgot to add the Logger::FunctionName in the screenshots.

**<span class="mark">B. Driver Loading Logic</span>**

<span class="mark">**Introduction:** One of the biggest updates in
Feeble Dream v3.0 is that it now supports Ring-0 Primitives for
attackers. Our main strategy is through BYOVD and loading drivers.
Therefore, we now require a working system that can load drivers based
on the name. It has to be able to deal with already loaded drivers,
existing services and errors that may occur. The driver loading logic
should be resilient and take weird cases into consideration.</span>

<span class="mark">**Problem:** Feeble Dream v2.0 was at SYSTEM
Integrity, We require Kernel primitives for more stronger capabilities
such as Disabling AVs and EDRs. Therefore, we set out to find 0-days
that can give us such primitives. We couldn’t really find Kernel CE
however we managed to find a couple of 0-days along the way. Therefore,
we will integrate these 0-days (and rediscoveries that still work) into
FDv3, this wont give us full kernel CE as of 14th September 2025 but
will allow for greater primitives and could be a “Semi Kernel Privilege
Escalation” (sKPE). We do want full KPE however currently sKPE is what
we have going.</span>

<span class="mark">**Engineering:** We will use a similar approach as
the last one, we will create DLStrategy.cpp and DLStrategy.h. This time,
we will have a simple approach, which goes something along the line of
“check if a driver is loaded, if it is then we can just move on
otherwise, it will check for the equivalent service, if it exists then
it will simply use that service, if it doesn't exist then it will make
one and run the driver.“</span>

<img src="./assets/images/FeebleDreamUpdateWork/media/image4.png"
style="width:5.61458in;height:1.66667in" /><span class="mark">  
  
Fortunately I had some previous code with me for loading the MSR R/W
primitive driver. So I was able to reuse that code without much
issues.</span>

<span class="mark">CreateDriverService:</span>

<img src="./assets/images/FeebleDreamUpdateWork/media/image1.png"
style="width:3.72917in;height:5.5in" />

<span class="mark">DriverLoad:</span>

<img src="./assets/images/FeebleDreamUpdateWork/media/image8.png"
style="width:4.30208in;height:5.52083in" />

<span class="mark">CheckDriverLoaded:</span>

<img src="./assets/images/FeebleDreamUpdateWork/media/image7.png"
style="width:6.5in;height:2.56944in" />

<span class="mark">**Future work:** Now that we have introduced a new
logging system along with the code that can load drivers. We will work
on the primitives that we have. We will add in the driver logic along
with an easy way to send the vulnerable IOCTL codes with the malicious
IRP buffer.</span>

<span class="mark">**Security Disclosure:** All the work was performed
inside an isolated lab environment and on systems we control. Please
ensure that you follow proper security etiquette whilst performing such
research.</span>
