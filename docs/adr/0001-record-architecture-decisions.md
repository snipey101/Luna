# 1. Record architecture decisions

Date: 2026-10-12

## Status
Accepted

## Context
Luna is built step by step, often with an AI assistant. Without written reasons, later changes can undo choices made on purpose (for example, the custom pathfinding in ADR 0007).

## Decision
We record significant decisions as Architecture Decision Records in `docs/adr/`, using Michael Nygard's format: Context, Decision, Consequences. Files are numbered (`NNNN-short-title.md`), and each one is listed in `docs/adr/README.md`. When a decision changes, add a new ADR that supersedes the old one rather than rewriting history.

## Consequences
- Anyone can see why things are the way they are before changing them.
- Each significant change takes a small amount of extra writing.
