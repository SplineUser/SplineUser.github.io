---
layout: post
title: "Component Engineering: Automatic Evasive API Hashing"
date: 2026-04-14
categories: [MalwareDevelopment, FeebleDream]
tags: [malware, C++, API-hashing, evasion, VirusTotal, XP, software-engineering, Windows]
description: "Building an automated API hashing tool as a sub-component of the APT simulation framework — using Extreme Programming to iterate from JSON config parsing through stub generation, compilation, and VirusTotal submission."
---

**Introduction:** This is a sub-component of the APT simulation tool, this part is responsible for minimizing VT score via the usage of API Hashing to remove different APIs present in the import table of the PE. The goal is to automatically hash APIs from a given list, compile it and test it against VT.

**Software Engineering utilization:** This mini-project will utilize software engineering principles for efficiently developing the program and to ensure that it will be of higher quality. The software engineering methodology is derived from my general big picture understanding of the subject.

**Process Model and its selection:** The process model is the software engineering approach we are going to conduct for improving efficiency and quality of our product. It could just be a sequence of software engineering principles that we can think of and derive manually; however, there already exist models that you could simply choose from based on the project. Since this is a research-based project where the requirements are unclear and is very exploratively in nature. We will choose a model that is more iterative as-to fine tune our engineering solution as we go about developing it. Since I am working alone without a team, we will not choose models such as RAD, concurrent and scrub. Instead we will use a hybrid model consisting of principles from the Xtreme Programming and Prototyping model. We will follow the core values of effective communication (which by the nature of working individually is followed to its most ideal possibility), simplicity, feedback via testing, courage to throw everything away if needed and respect. The major pillars here that we need to follow are feedback and simplicity. Additionally, we will follow the XP planning game, Test-Driven Development, Refactoring, Continuous Integration, Initial Requirement collection and requirement refinement.

**Step 1 – Iteration Initialization:** First we need to identify the goal for this iteration followed by stories and finally finding the feature lists that need to be built.

**Step 2 – Quick Design:** The design will be the next step where we will create an UML Diagram.

**Step 3 – Creating the Test:** The test will be written as per XD TDD

**Step 4 – Developing the solution:** Based on the test, we build the simplistic solution that passes this test.

**Step 5 – Conduct analysis/test:** We will look at the program and ensure it follows the test and requirements.

**Step 6 – Refractor:** Simplification of the code-base.

**Step 7 – Requirement Updating + Next iteration**

**Requirement Engineering:** Usually the Requirement engineering consists of requirement gathering and creation of the SRS document however for our scenario where there exists only a single decision maker, the requirement engineering step will only consist of a couple of steps including: 1\. Self-Questionnaire for Requirement Gathering, 2\. Quality Function Deployment from these requirements and 3\. Use-case diagram generation. Therefore, we need to start with Requirement Gathering

**Question 1 Problem Definition – What is the purpose of the software?** The aim of the software is to conduct automatic API Hashing from a given API list.

**Question 2 Functional Requirements:** Input: C/CPP Program, Process: 1\. Parse Input File, 2\. Apply every API Hashing, 3\. Send result to VT, 4\. Display the result.

**Question 3 Non-Function Requirements – What should the speed be?** Speed is not the primary concern. The usability is through CLI.

**Question 4 Constraints – What constraints exist?** It is dependent upon Virustotal and an external compiler.

**Question 5 Risks –** **What sort of Risks exist?** API Limitations, Network issues and Compiler Errors.

**Use Case Development:**

**Actor →** User

**Secondary Actor →** Virustotal API

**Use Cases →** Provide Input Program, Generate API-Hashed Variant, Compile and Test Variants, Submit Variants to VirusTotal, Receive VT Result.

<img src="{{ '/assets/images/api-hashing/image1.png' | relative_url }}" alt="image1" style="max-width:100%;" />

For our program, the use-case diagram is a bit redundant as this is just a way to showcase relationships and provide a high level of abstraction, since our program is solo and also comparatively not that complex. This did not really help us much apart from following the formalities.

**Quality Function Deployment:** QFD is used to move from the requirements to the technical specifications and using a matrix to showcase priorities and relations. The following are the technical specifications:

1. Module that will parse external files for r/w operations  
2. Module that will make the API Hashing stubs  
3. Module that will compile the c/cpp file  
4. Module that will upload the file to VT

Usually, a matrix will be used to prioritize one of these Technical specifications; however, for our use case, we can simply start working in that order. Additionally, we will be doing component based design aswell to make our system modular and more importantly, to learn how to make tools that follow industry-level patterns. 

Stories for XP based on Technical Specification \#1 –

1. As a user I want the system to accept external JSON configure files through which it will conduct API Hashing  
2. As a user I want to be able to give it my C/CPP Code as input and expect them to find the APIs mentioned in the JSON File.  
3. As a user, I expect the program to parse these files and operate on them  
   

**XP Iteration \#1**

**Story:** As a user I want the system to accept external JSON configure files through which it will conduct API Hashing

**Component-Level/UML class diagram Design:** In XP, the design process is story specific and not a full system-level design, therefore, we will now make the design for this particular component whilst practicing the OOD (Object Oriented Design) principles:

<img src="{{ '/assets/images/api-hashing/image2.png' | relative_url }}" alt="image2" style="max-width:100%;" />

**TDD For the code based on the component(JSONComponent:JsonConfigManager):** We use the Given-When-Then format

**TC01 –** 

Success Given: A JSON File path; When: LoadConfig() is called, Then: The code must successfully verify the JSON and then internally parse and load it

Failure: Otherwise

**TC02 –** 

Success Given: A JSON File is loaded; When: getAPIList(), Then: The code must return all API from the JSON in a list.

Failure: Otherwise

**TC03 –** 

Success Given: Valid API Name; When: getStruct(), Then: The code must return the structure for the API name given.

Failure: Otherwise

**Coding:** We have coded the first iteration and there were just some minor deviations from our original component design. However, for the most part, it remained perfectly accurate. The code is available at the github: “[https://github.com/SplineUser/AutoAPIHash](https://github.com/SplineUser/AutoAPIHash)”. Next, we will conduct the tests.

**Test Result:**

<img src="{{ '/assets/images/api-hashing/image3.png' | relative_url }}" alt="image3" style="max-width:100%;" />

We are successful with TC01, TC02 and TC03, therefore this iteration is perfectly valid. Now, we are supposed to conduct analysis and take feedback; however, since we have passed the test, we can move on. 

**Refactoring:** The JSONVerifier class had the “IsValid” boolean value which did nothing, therefore that was removed.

**Requirement Updates:** Change APIList into a Name, Rename set list

Therefore, we have completed the first iteration of our process mode. We will repeat these iterations for different user-stories until we have built the full working system.

**XP Iteration \#2:** As a user I want to be able to give it my C/CPP Code as input and expect them to find the APIs mentioned in the JSON File and rename it.

**Component-Level UML Class diagram:**

<img src="{{ '/assets/images/api-hashing/image4.png' | relative_url }}" alt="image4" style="max-width:100%;" />

**TDD For the component (SourceComponent):**

**TC01:** 

Success Given: FilePath, APIList\_set, When: RenameAPI() Called, Then: Renames every API to via the set.

Failure: Otherwise

**Test Result:**

<img src="{{ '/assets/images/api-hashing/image5.png' | relative_url }}" alt="image5" style="max-width:100%;" />

**Refactoring:** No Major Refactoring required.

**Requirement Updates:** User-story 3 is now redundant since the operations have already been performed. We also require an API\_Found list which we will use making the stubs.

**Technical Specification \#2:** Module that will make the API Hashing stubs

**User Stories:**

1. As a user, I want the tool to write the stubs for API detected from the JSON File.  
2. As a user, I expect the tool to integrate the stubs in my program.  
3. As a user, I want the tool to output all the API it has stubbed onto the console.

**XP Iteration \#3:** As a user, I want the tool to write the stubs for API detected from the JSON File.

**Component + UML Class diagram:**

<img src="{{ '/assets/images/api-hashing/image6.png' | relative_url }}" alt="image6" style="max-width:100%;" />

**TDD For component:**

**TC01 –** 

**Success:** Given: sourcePath and APIList and external headerfile; When: CreateStubs() is called, Then: Write the stub in the external file.

**Failure:** Otherwise

**Result:**

<img src="{{ '/assets/images/api-hashing/image7.png' | relative_url }}" alt="image7" style="max-width:100%;" />

**Refactoring:** No major Refactoring required.

**Requirement Updates:** None.

**XP Iteration \#4:** As a user, I expect the tool to integrate these stubs in my program using an external header file import.

**Component/UML Class diagram:** This part was just the introduction of a new function and changing the file paths for achieving this. Therefore we did not need a component with an interface. 

**TDD For function:**

**Success:** Given: A pre-built header file and a source file is included; When: The PrependSourceHeader is called; Then: Write the include header file at the top of the source file and redirect the API Hashing to the header file

**Result:**

<img src="{{ '/assets/images/api-hashing/image8.png' | relative_url }}" alt="image8" style="max-width:100%;" />

With this we have created what I would call a big part of the project which was the API Hashing part, we require slight Refactoring to not clutter the main file. Then we can move onto the compiling logic and give our program a nice CLI.

**Refactoring:** The main file is getting cluttered therefore, we added another layer of abstraction which executes all the code yet (Part A)

**Requirement changes:** Removing user story 3 as it was only a single line change, just had to add a single cout line and we got it displaying on console

**Technical Specification \#3:** Module that will compile the c/cpp file

**User story:** As a user, I want my resulting cpp file alongside its header file to be compiled as an executable.

**User story:** As a user, I expect the executable file to be stored in a separate folder alongside the file name being different for each iteration.

**User story:** As a user, I want the program to accept user arguments and have a nice CLI

**XP Iteration \#5 –** As a user, I want the program to accept user arguments and have a nice CLI

**Component/UML Diagram:**

<img src="{{ '/assets/images/api-hashing/image9.png' | relative_url }}" alt="image9" style="max-width:100%;" />

**TDD For component:**

**Success:** Given: Correct Arguments; When: The program is executed; Then: Execute the program.

**Success:** Given: Incorrect Arguments; When: The program is executed; Then: Showcase help screen.

**Result:**

<img src="{{ '/assets/images/api-hashing/image10.png' | relative_url }}" alt="image10" style="max-width:100%;" />

**Refactoring:** CLI implementation abstraction again to get away from main!

**Requirement Changes:** None!

**XP Iteration \#6 –** As a user, I want my resulting cpp file alongside its header file to be compiled as an executable.

**Component Design:** Skipped since we are using MinGW and only need to execute a cmd command

**TDD:**

**Success:** Given: Successful stub integration and API hashing; When: API hashing is done; then: Compile the cpp file using minGW.

**Failure:** Otherwise

**Result:**

<img src="{{ '/assets/images/api-hashing/image11.png' | relative_url }}" alt="image11" style="max-width:100%;" />

**Refactoring:** Minor code Refactoring occurred to remove testing elements we added.

**Requirement Change:** XP user story 3 removed due to simplicity.

**Technical Specification \#3 –** Module that will upload the file to VT

**User story:** As a user, I wish the program would use my API key

**User story:** As a user, I want the program to send the executable to Virustotal and display the results on the CLI.

**XP Iteration \#7 –** As a user, I wish the program would use my API key.

**UML diagram:**

<img src="{{ '/assets/images/api-hashing/image12.png' | relative_url }}" alt="image12" style="max-width:100%;" />

**TDD:**

**TC01 –** 

**Success:** Given: A config file; when: APILoad is called; Then: Store the API Key

**Failure:** Otherwise;

**Result:**

<img src="{{ '/assets/images/api-hashing/image13.png' | relative_url }}" alt="image13" style="max-width:100%;" />

**Refactoring:** None

**Requirement Changes:** None

**XP iteration \#8 –** As a user, I want the program to send the executable to Virustotal and display the results on the CLI.

**(Fortunately, I was able to find a script online that did exactly this – Eventual Result)**

<img src="{{ '/assets/images/api-hashing/image14.png' | relative_url }}" alt="image14" style="max-width:100%;" />

**Conclusion:** The purpose of this was to understand how using simple software engineering principles can allow for more efficient development of cybersecurity tools. Using a process model which made us do requirement engineering, designing the components, conducting tests and more allowed for better development of this tool.
