#!/usr/bin/env python3
"""Partition a large GoldSrc/Sven Co-op reference SMD into runtime-safe $body pieces.

Keeps every triangle, bone, normal, UV and material row unchanged. It only groups the
existing triangles into separate SMD files, then creates a build-only QC with one $body
per piece. Vertex and normal limits are counted using the float32 values StudioMDL reads.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass(frozen=True)
class Triangle:
    material: str
    rows: tuple[str, str, str]
    vertex_keys: frozenset[tuple[int, bytes]]
    normal_keys: frozenset[tuple[int, bytes]]


def _pack3(fields: list[str]) -> bytes:
    return struct.pack("<3f", float(fields[0]), float(fields[1]), float(fields[2]))


def _keys_for_row(row: str) -> tuple[tuple[int, bytes], tuple[int, bytes]]:
    fields = row.split()
    if len(fields) != 9:
        raise ValueError(f"SMD vertex must have 9 fields, got {len(fields)}: {row[:120]}")
    try:
        bone = int(fields[0])
        position = _pack3(fields[1:4])
        normal = _pack3(fields[4:7])
    except (ValueError, struct.error) as exc:
        raise ValueError(f"invalid SMD vertex row: {row[:120]}") from exc
    return (bone, position), (bone, normal)


def _parse_smd(path: Path) -> tuple[list[str], list[Triangle], int]:
    lines = path.read_text(encoding="utf-8-sig", errors="strict").splitlines()
    indices = [i for i, line in enumerate(lines) if line.strip().lower() == "triangles"]
    if len(indices) != 1:
        raise ValueError(f"{path}: expected exactly one 'triangles' section, found {len(indices)}")
    tri_index = indices[0]
    prefix = lines[: tri_index + 1]
    triangles: list[Triangle] = []
    i = tri_index + 1
    while i < len(lines):
        material = lines[i].strip()
        i += 1
        if not material:
            continue
        if material.lower() == "end":
            break
        if i + 3 > len(lines):
            raise ValueError(f"{path}: incomplete triangle after material {material!r}")
        rows = (lines[i].strip(), lines[i + 1].strip(), lines[i + 2].strip())
        i += 3
        vkeys: set[tuple[int, bytes]] = set()
        nkeys: set[tuple[int, bytes]] = set()
        for row in rows:
            vkey, nkey = _keys_for_row(row)
            vkeys.add(vkey)
            nkeys.add(nkey)
        triangles.append(Triangle(material, rows, frozenset(vkeys), frozenset(nkeys)))
    else:
        raise ValueError(f"{path}: missing terminal 'end' for triangles section")
    if not triangles:
        raise ValueError(f"{path}: triangles section is empty")
    return prefix, triangles, lines.index("triangles")


def _partition(triangles: list[Triangle], max_vertices: int, max_normals: int, max_triangles: int):
    if min(max_vertices, max_normals, max_triangles) < 1:
        raise ValueError("all partition limits must be positive")
    parts: list[tuple[list[Triangle], set[tuple[int, bytes]], set[tuple[int, bytes]]]] = []
    current: list[Triangle] = []
    vertices: set[tuple[int, bytes]] = set()
    normals: set[tuple[int, bytes]] = set()

    for tri in triangles:
        new_vertices = vertices | set(tri.vertex_keys)
        new_normals = normals | set(tri.normal_keys)
        full = bool(current) and (
            len(new_vertices) > max_vertices
            or len(new_normals) > max_normals
            or len(current) >= max_triangles
        )
        if full:
            parts.append((current, vertices, normals))
            current, vertices, normals = [], set(), set()
            new_vertices, new_normals = set(tri.vertex_keys), set(tri.normal_keys)
        if len(new_vertices) > max_vertices or len(new_normals) > max_normals:
            raise ValueError("a single triangle exceeds the configured vertex/normal budget")
        current.append(tri)
        vertices = new_vertices
        normals = new_normals
    if current:
        parts.append((current, vertices, normals))
    return parts


def build_sven_compatible_split(
    source_smd: Path,
    source_qc: Path,
    output_dir: Path,
    output_qc: Path,
    report_path: Path,
    *,
    root: Path,
    max_vertices: int = 2048,
    max_normals: int = 2048,
    max_triangles: int = 4080,
    max_parts: int = 64,
) -> dict:
    root = root.resolve()
    source_smd = source_smd.resolve()
    source_qc = source_qc.resolve()
    output_dir = output_dir.resolve()
    output_qc = output_qc.resolve()
    report_path = report_path.resolve()
    try:
        output_rel = output_dir.relative_to(root).as_posix()
    except ValueError as exc:
        raise ValueError("output directory must be inside the repository root") from exc
    prefix, triangles, _ = _parse_smd(source_smd)
    parts = _partition(triangles, max_vertices, max_normals, max_triangles)
    if len(parts) > max_parts:
        raise ValueError(
            f"safe split requires {len(parts)} bodyparts, exceeding the Sven/FunnkyHD limit {max_parts}; "
            "do not raise per-piece runtime limits to force a compile"
        )

    output_dir.mkdir(parents=True, exist_ok=True)
    reports = []
    for idx, (part, vertices, normals) in enumerate(parts):
        base = f"y{idx:03d}"
        dest = output_dir / f"{base}.smd"
        text_lines = prefix[:]
        for tri in part:
            text_lines.append(tri.material)
            text_lines.extend(tri.rows)
        text_lines.append("end")
        payload = "\n".join(text_lines) + "\n"
        dest.write_text(payload, encoding="utf-8", newline="\n")
        reports.append({
            "index": idx,
            "body_name": f"yorha_part_{idx:03d}",
            "smd": dest.relative_to(root).as_posix(),
            "triangles": len(part),
            "unique_vertices": len(vertices),
            "unique_normals": len(normals),
            "sha256": hashlib.sha256(dest.read_bytes()).hexdigest(),
        })

    qc_text = source_qc.read_text(encoding="utf-8-sig", errors="strict")
    body_pattern = re.compile(
        r'(?im)^\s*\$body\s+"body"\s+"mesh/custom_player_highpoly_windows"\s*$'
    )
    matches = list(body_pattern.finditer(qc_text))
    if len(matches) != 1:
        raise ValueError(f"source QC must contain exactly one original Yorha $body, found {len(matches)}")
    body_lines = []
    for item in reports:
        body_path = f"{output_rel}/{Path(item['smd']).name[:-4]}"
        if len(body_path) > 60:
            raise ValueError(f"QC $body source path exceeds 60 characters ({len(body_path)}): {body_path}")
        body_lines.append(f'$body "{item["body_name"]}" "{body_path}"')
    generated_qc = body_pattern.sub("\n".join(body_lines), qc_text, count=1)
    if "$splitmesh" not in generated_qc.lower():
        raise ValueError("generated QC unexpectedly lost $splitmesh 2048")
    output_qc.parent.mkdir(parents=True, exist_ok=True)
    output_qc.write_text(generated_qc, encoding="utf-8", newline="\n")

    report = {
        "status": "PASS_SVEN_COMPATIBLE_SMD_SPLIT",
        "source_smd": source_smd.relative_to(root).as_posix(),
        "source_smd_sha256": hashlib.sha256(source_smd.read_bytes()).hexdigest(),
        "source_qc": source_qc.relative_to(root).as_posix(),
        "generated_qc": output_qc.relative_to(root).as_posix(),
        "triangle_count_source": len(triangles),
        "triangle_count_split": sum(x["triangles"] for x in reports),
        "limits": {
            "vertices_per_piece": max_vertices,
            "normals_per_piece": max_normals,
            "triangles_per_piece": max_triangles,
            "bodyparts": max_parts,
        },
        "parts_count": len(reports),
        "max_vertices_actual": max(x["unique_vertices"] for x in reports),
        "max_normals_actual": max(x["unique_normals"] for x in reports),
        "max_triangles_actual": max(x["triangles"] for x in reports),
        "parts": reports,
    }
    if report["triangle_count_split"] != report["triangle_count_source"]:
        raise ValueError("split triangle count differs from source")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--source-smd", default="mesh/custom_player_highpoly_windows.smd")
    parser.add_argument("--source-qc", default="custom_player_windows.qc")
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--output-qc", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--max-vertices", type=int, default=2048)
    parser.add_argument("--max-normals", type=int, default=2048)
    parser.add_argument("--max-triangles", type=int, default=4080)
    parser.add_argument("--max-parts", type=int, default=64)
    args = parser.parse_args(argv)
    root = args.root.resolve()
    def anchored(p: Path) -> Path:
        return p if p.is_absolute() else root / p
    try:
        report = build_sven_compatible_split(
            anchored(Path(args.source_smd)), anchored(Path(args.source_qc)),
            anchored(args.output_dir), anchored(args.output_qc), anchored(args.report),
            root=root, max_vertices=args.max_vertices, max_normals=args.max_normals,
            max_triangles=args.max_triangles, max_parts=args.max_parts,
        )
    except Exception as exc:
        print(f"FAIL_SVEN_SMD_SPLIT: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({k: report[k] for k in (
        "status", "source_smd", "triangle_count_source", "triangle_count_split",
        "parts_count", "max_vertices_actual", "max_normals_actual", "max_triangles_actual",
    )}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
