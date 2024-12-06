---
title: I made a static page to visualize tailscale ACL
date: 2024-11-22 18:48:23
tags:
- tailscale
---

Understanding Tailscale ACL files can be frustrating, especially when managing access rules. I’ve often forgotten to enable SSH in the ssh section after allowing port 22 in ACLs, leading to confusion. This struggle inspired me to create a static page to simplify and visualize ACL configurations.

Initially, my goal was to generate a graph directly from the Tailscale ACL file, hoping to map out resource access visually. However, I quickly realized that this approach was both complicated and arbitrary, as translating the ACL rules into a coherent graph required significant interpretation. That’s when I discovered Mermaid.js—a lightweight library that renders diagrams directly in the browser. Its simplicity and ability to work without a server made it a perfect fit for this project, allowing me to focus on creating an intuitive visualization tool.

The static page is live at https://akarat-tools.xyz/tailscale-acl-viz.html. While it’s still a work in progress, the page currently focuses on visualizing the acls, ssh, and groups fields from Tailscale ACL files. Since my primary interest lies in the acls field, I’ve added color coding to differentiate between applications based on their ports—for example, distinct colors for databases, SSH, and HTTP/HTTPS traffic. This makes it easier to interpret access rules at a glance and spot patterns or potential misconfigurations.

The page may still have bugs, so I apologize for any issues. Please give it a try, and feel free to improve or modify the code as you wish. Your feedback or contributions would be greatly appreciated to make it better.
