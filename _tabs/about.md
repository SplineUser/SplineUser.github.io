---
# the default layout is 'page'
icon: fas fa-info-circle
order: 4
---

# About — Priyan

Hi, I’m **Priyan**, a cybersecurity researcher focused on low-level offensive techniques and the defensive lessons that follow from them. I publish hands-on writeups, PoCs, and methodical research that explore how modern systems can be manipulated and how defenders can use that knowledge to build stronger protections.

---

## What I research
My work targets the intersection of exploitation craftsmanship and evasive engineering. Areas I publish and experiment in include:

- **Shellcode obfuscation & delivery** — novel encodings, in-memory transformation techniques, and covert transmission channels.  
- **Local Privilege Escalation (LPE)** — discovery and exploitation of privilege elevation vectors in modern OSes.  
- **Kernel exploitation & driver analysis** — reverse engineering drivers, examining IRP flows, and controlled kernel execution techniques.  
- **Antivirus evasion / evasion telemetry** — study of detection heuristics and practical evasion strategies (research only).  
- **BYOVD & covert channels** — exploring benign-appearing vessels and non-standard carriers for payload transport.  
- **API-hashing / stealth loading** — techniques for reducing forensic artifacts in PoC scenarios.

> Note: My emphasis is hands-on, low-level research and I prefer small, reproducible experiments that illuminate why a technique works and what mitigations are effective.

---

## Selected projects & writeups
- **Physical Intrusion Detection System** — Simple Hardware based Intrusion Detection System using a weighted multi-model sensor approach
- **Feeble Dream** — multi-stage evasive execution framework (research/in-lab PoC).  
- Shellcode-as-audio experiments, API hashing PoCs, and driver dispatch table analysis (see the blog for details and lab notes).

(You’ll find links to posts and PoCs in the **Research** section of the site.)

---

## How I work
- I keep experiments reproducible and confined to isolated lab environments (VMs, air-gapped hardware, disposable images).  
- I document the full methodology: hypothesis → environment → steps → artifacts → mitigations.  
- Responsible disclosure: when research uncovers a real vulnerability that affects third parties, I follow coordinated disclosure best practices.

---

## Want to collaborate?
I’m open to:
- technical reviews,
- co-authoring research,
- or discussing how offensive techniques reveal practical mitigations.

Email (preferred) or open an issue on GitHub if you have a responsible collaboration proposal.

- GitHub: [@SplineUser](https://github.com/SplineUser)  
- Email: `priyan29@pm.me`

---

## How to cite / use this research
If you reference my work in a paper, blog, or presentation, please cite the original post and, when distributing derived tools or PoCs, ensure they are used for research/defensive purposes only.

Example citation:
> Priyan (2025). *Expanding the Hunting Horizons using RIP Manipulation.* Retrieved from `https://splineuser.github.io`

---

## Ethics & disclaimer
All content on this site is published for **educational and research purposes only**. Techniques described are powerful and can be misused, please do **not** apply them against systems you do not own or have explicit permission to test. I do not endorse unlawful or malicious activity. If you discover a vulnerability in third-party software, please follow responsible disclosure procedures.

---

## Quick facts
- Primary toolset: Ghidra, WinDbg, IDA/Ghidra scripting, Python automation, WinAPI reverse engineering  
- Languages: C, C++, Python, some low-level assembly

---

Thanks for stopping by and feel free to browse the research posts, open an issue to discuss, or drop me an email if you’d like to collaborate.

