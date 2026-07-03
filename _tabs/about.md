---
# the default layout is 'page'
icon: fas fa-info-circle
order: 4
---

# About — Priyan

I work on security research, Windows internals, binary analysis, and exploitability research. Most of my posts are lab notes: experiments, failures, debugging notes, and technical writeups from trying to understand security-relevant behavior.

---

## What I research

My work focuses on low-level systems behavior and practical security analysis. Areas I publish and experiment in include:

- **Windows internals** — driver behavior, kernel/user-mode boundaries, RPC interfaces, and WinAPI behavior.
- **Binary analysis & reverse engineering** — static and dynamic analysis with tools such as Ghidra, WinDbg, and Python automation.
- **Vulnerability research** — exploitability analysis, root-cause notes, proof-of-concept validation, and responsible disclosure.
- **Security experiments** — isolated lab work that tests assumptions, records failures, and explains what was learned.
- **Tooling** — small utilities and components that support repeatable research workflows.

> Note: My emphasis is hands-on, low-level research. I prefer small, reproducible experiments that illuminate why behavior occurs and what mitigations or defensive lessons follow from it.

---

## Selected projects & writeups

- **CVE-2025-60419** — driver-induced denial-of-service research notes around IOCTL handling.
- **RIP manipulation research** — using controlled register manipulation to study driver device exposure behavior.
- **Windows RPC research** — tracing RPC interfaces, dispatch tables, and security callbacks.
- **IOMMU misconfiguration notes** — investigating DMA remapping tables and configuration assumptions.
- **Physical Intrusion Detection System** — a hardware-based intrusion detection project using a weighted multi-model sensor approach.

---

## How I work

- I keep experiments reproducible and confined to isolated lab environments such as VMs, air-gapped hardware, and disposable images.
- I document methodology, environment, observations, artifacts, failures, and defensive takeaways.
- When research uncovers a real vulnerability that affects third parties, I follow coordinated disclosure best practices.

---

## Want to collaborate?

I’m open to:

- technical reviews,
- co-authoring research,
- responsible disclosure coordination,
- or discussing how low-level security research can lead to practical mitigations.

Email or open an issue on GitHub if you have a responsible collaboration proposal.

- GitHub: [@SplineUser](https://github.com/SplineUser)
- Email: `priyan29@pm.me`

---

## How to cite / use this research

If you reference my work in a paper, blog, or presentation, please cite the original post. If you distribute derived tools or proof-of-concept material, ensure they are used only for authorized research, validation, and defensive purposes.

Example citation:
> Priyan (2025). *Expanding the Hunting Horizons using RIP Manipulation.* Retrieved from `https://splineuser.github.io`

---

## Ethics & disclaimer

All content on this site is published for **educational and research purposes only**. Techniques described can be misused; do **not** apply them against systems you do not own or do not have explicit permission to test. I do not endorse unlawful or malicious activity. If you discover a vulnerability in third-party software, please follow responsible disclosure procedures.

---

## Quick facts

- Primary toolset: Ghidra, WinDbg, IDA/Ghidra scripting, Python automation, WinAPI reverse engineering
- Languages: C, C++, Python, and some low-level assembly

---

Thanks for stopping by. Feel free to browse the research posts, open an issue to discuss a technical detail, or drop me an email if you’d like to collaborate.
