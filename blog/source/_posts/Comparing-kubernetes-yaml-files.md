---
title: Comparing kubernetes yaml files
date: 2024-12-06 23:41:37
tags:
---

Sometimes, I need to compare Kubernetes YAML files to understand changes, troubleshoot issues, or validate configurations. Whether it’s debugging deployments or reviewing updates, having a clear way to spot differences between files is essential for managing complex Kubernetes environments effectively.

kubectl diff is great for comparing local YAML files with the current state in the cluster, and it even supports Kustomize out of the box. It's the most useful tool. It has some shortcomings, it lack of syntax highlighting, often shows irrelevant details like resource revisions or lengthy outputs of last-applied configurations, but it's still unreplacable.

[dyff](https://github.com/homeport/dyff) on the other hand is an excellent tool for comparing YAML and JSON files, offering flexibility beyond just Kubernetes use cases. It shines with its ability to handle any two YAML files, whether they represent different configurations or versions of an application. One standout feature is its syntax highlighting and colorful output, which make differences easy to spot at a glance.

dyff support standard input and URLs, so you can easily compare like `dyff between <(kubectl get deployment my-deployment -o yaml) deployment.yaml` or `dyff between https://xxx.com/nginx-app-v1.1.yaml https://xxx.com/nginx-app-v2.yaml`.

If kubectl diff feels too noisy and dyff isn’t available, my tool at https://akarat-tools.xyz/k8s-yaml-diff.html might be just what you need. It’s designed to simplify YAML comparison with a clean interface and a navigation sidebar that lets you jump between resources effortlessly. The output is structured to be easy on the eyes, helping you quickly spot differences without getting overwhelmed by unnecessary details. While it’s not as feature-rich as other tools, it offers a lightweight and accessible alternative for quick comparisons.

The tool runs entirely in your browser, with no server-side processing or tracking involved. Your data stays completely private, and you can use it confidently without concerns about security or privacy. The code is open for you to modify, improve, or use in any way you like.
