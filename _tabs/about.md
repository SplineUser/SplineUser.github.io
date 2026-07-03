---
# the default layout is 'page'
icon: fas fa-info-circle
order: 4
---


# About — Priyan

Hi, I’m Priyan, a cybersecurity researcher interested in Windows internals, binary analysis, vulnerability research, and exploitability analysis.

Most of my work starts with an unclear technical question: a crash, a strange interface, an old technique, a suspicious primitive, or a security boundary worth investigating. I build a lab around it, trace behavior with tools like Ghidra and WinDBG, test assumptions, compare static analysis with runtime behavior, and document what actually happens.

This blog is my research notebook. Some posts are polished writeups. Others are lab notes from experiments that worked, failed, or produced partial results.

## What I research

My main areas of interest are:

- **Windows internals** — APIs, kernel/user boundaries, system behavior, and debugging.
- **Binary reverse engineering** — understanding program behavior through static and dynamic analysis.
- **Vulnerability research** — identifying security-relevant behavior, trust-boundary issues, and bug classes.
- **Exploitability analysis** — reasoning about whether a bug or primitive can lead to meaningful security impact.
- **Security research tooling** — small scripts, harnesses, and workflows that make research easier.
- **Technique reproduction** — testing public techniques in controlled lab environments and documenting what still works, what breaks, and why.

I prefer small, reproducible experiments that explain why something behaves the way it does.

## Selected work

- **CVE-2025-60419** — Realtek driver vulnerability research.
- **Demystifying Driver Research** — Nullcon Goa 2026 talk.
- **RIP Manipulation Research** — exploring device exposure, reachability, and runtime control-flow manipulation.
- **Windows RPC research** — investigating exposed interfaces, callbacks, dispatch behavior, and failure cases.
- **Acoustic Shellcodes** — research into audio-based shellcode transformation.
- **Windows driver and binary analysis notes** — experiments around IOCTL handling, primitives, and exploitability conditions.

## How I work

My usual workflow is:

1. Define the technical question.
2. Build a controlled lab.
3. Reproduce or observe the behavior.
4. Trace it with static and dynamic tools.
5. Test hypotheses.
6. Document the result, limitations, and open questions.

I care about documenting failures as much as successes. A failed experiment often still explains something useful.

## Work and collaboration

I’m open to research work where the job is to investigate, test, document, and turn messy technical material into something clear and useful.

Useful areas include:

- vulnerability research support,
- technique reproduction,
- lab validation,
- binary analysis notes,
- technical reports and writeups,
- security research tooling,
- research assistant-style work.

Website: [splineuser.com](https://www.splineuser.com)  
GitHub: [@SplineUser](https://github.com/SplineUser)  
Email: contact@splineuser.com

## Citation

If you reference my work in a paper, blog, or presentation, please cite the original post.

Example:

> Priyan. “Expanding the Hunting Horizons using RIP Manipulation.” Retrieved from https://splineuser.github.io

## Disclaimer

The content on this site is published for educational and research purposes. Please do not test techniques against systems you do not own or do not have permission to assess. If research uncovers an issue affecting third-party software, follow coordinated disclosure practices.
