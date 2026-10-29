#!/usr/bin/env python3
"""Fail-closed validation for the Yorha V41 Windows StudioMDL workflow.
Uses only Python's standard library. It verifies source assets, UV transformation,
QC directives, animation references and the compiled GoldSrc MDL v10 structure.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import re
import struct
import sys
from pathlib import Path
from typing import Any

HEADER_SIZE = 244
MDL_VERSION = 10
MAX_BONES = 128
MAX_SEQUENCES = 256
MAX_BODYPARTS = 64
MAX_VERTEX_ROWS_PER_MODEL = 2048
EXPECTED_TRIANGLES = 99_998
EXPECTED_SEQUENCES = 208
EXPECTED_BONES = 90


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def i32(data: bytes, off: int) -> int:
    if off < 0 or off + 4 > len(data):
        raise ValueError(f'int32 offset out of bounds: {off}')
    return struct.unpack_from('<i', data, off)[0]


def u16(data: bytes, off: int) -> int:
    if off < 0 or off + 2 > len(data):
        raise ValueError(f'uint16 offset out of bounds: {off}')
    return struct.unpack_from('<H', data, off)[0]


def check_range(data: bytes, off: int, size: int, label: str, minimum: int = HEADER_SIZE) -> None:
    if off < minimum or size < 0 or off + size > len(data):
        raise ValueError(f'{label} table/data out of bounds: offset={off}, size={size}, file={len(data)}')


def parse_smd_nodes(path: Path) -> tuple[dict[int, str], dict[int, int]]:
    names: dict[int, str] = {}
    parents: dict[int, int] = {}
    in_nodes = False
    found_nodes = False
    with path.open('r', encoding='utf-8', errors='strict') as stream:
        for raw in stream:
            line = raw.strip()
            if line == 'nodes' and not found_nodes:
                in_nodes = True; found_nodes = True; continue
            if in_nodes and line == 'end':
                break
            if not in_nodes or not line:
                continue
            m = re.fullmatch(r'(-?\d+)\s+"(.*)"\s+(-?\d+)', line)
            if not m:
                raise ValueError(f'{path}: invalid node line: {line[:120]}')
            ident, name, parent = int(m.group(1)), m.group(2), int(m.group(3))
            if ident in names:
                raise ValueError(f'{path}: duplicate bone id {ident}')
            names[ident], parents[ident] = name, parent
    if not names:
        raise ValueError(f'{path}: empty or missing nodes section')
    if sorted(names) != list(range(len(names))):
        raise ValueError(f'{path}: bone IDs are not contiguous from zero')
    for ident, parent in parents.items():
        if parent >= len(names) or parent < -1 or parent == ident:
            raise ValueError(f'{path}: invalid parent {parent} for bone {ident}')
    return names, parents


def parse_smd_triangles(path: Path) -> tuple[int, int]:
    lines = path.read_text(encoding='utf-8', errors='strict').splitlines()
    try:
        i = next(n for n, line in enumerate(lines) if line.strip() == 'triangles') + 1
    except StopIteration as exc:
        raise ValueError(f'{path}: missing triangles section') from exc
    triangles = corners = 0
    while i < len(lines):
        material = lines[i].strip(); i += 1
        if material == 'end':
            break
        if not material:
            continue
        for _ in range(3):
            if i >= len(lines):
                raise ValueError(f'{path}: truncated triangle at {triangles}')
            row = lines[i].strip().split(); i += 1
            if len(row) != 9:
                raise ValueError(f'{path}: expected 9 fields for SMD vertex, got {len(row)} at triangle {triangles}')
            try:
                int(row[0]); [float(x) for x in row[1:]]
            except ValueError as exc:
                raise ValueError(f'{path}: nonnumeric SMD vertex at triangle {triangles}') from exc
            corners += 1
        triangles += 1
    return triangles, corners


def get_qc_sequences_and_refs(text: str) -> tuple[list[str], list[str]]:
    names = re.findall(r'(?im)^\s*\$sequence\s+"([^"]+)"', text)
    # Include only sequence animation SMD paths, rather than the reference body SMD.
    refs = re.findall(r'(?i)"(anims/[^"]+)"', text)
    refs = [x.replace('\\', '/') for x in refs]
    refs = [x if x.lower().endswith('.smd') else x + '.smd' for x in refs]
    refs = list(dict.fromkeys(refs))
    return names, refs


def check_bmp(path: Path, max_dimension: int = 1024) -> dict[str, Any]:
    data = path.read_bytes()
    if len(data) < 54 or data[:2] != b'BM':
        raise ValueError(f'{path}: not a BMP file')
    pixel_offset = struct.unpack_from('<I', data, 10)[0]
    dib_size = struct.unpack_from('<I', data, 14)[0]
    if dib_size < 40 or len(data) < 14 + dib_size:
        raise ValueError(f'{path}: unsupported/truncated BMP DIB header')
    width, height = struct.unpack_from('<ii', data, 18)
    planes, bpp = struct.unpack_from('<HH', data, 26)
    compression = struct.unpack_from('<I', data, 30)[0]
    colors_used = struct.unpack_from('<I', data, 46)[0]
    if width <= 0 or height == 0:
        raise ValueError(f'{path}: invalid BMP dimensions {width}x{height}')
    height = abs(height)
    if width > max_dimension or height > max_dimension:
        raise ValueError(f'{path}: texture exceeds max dimension {max_dimension}: {width}x{height}')
    if planes != 1 or bpp != 8 or compression != 0:
        raise ValueError(f'{path}: expected uncompressed 8-bit indexed BMP; got planes={planes}, bpp={bpp}, compression={compression}')
    palette_entries = colors_used or 256
    if palette_entries != 256:
        raise ValueError(f'{path}: expected 256-entry palette, got {palette_entries}')
    rowbytes = ((width * bpp + 31) // 32) * 4
    if pixel_offset + rowbytes * height > len(data):
        raise ValueError(f'{path}: pixel array truncated')
    return {'path': str(path), 'width': width, 'height': height, 'bits_per_pixel': bpp,
            'palette_entries': palette_entries, 'bytes': len(data), 'sha256': sha256(path)}


def validate_sources(root: Path) -> dict[str, Any]:
    qc_path = root / 'custom_player_windows.qc'
    source_smd = root / 'mesh/custom_player_highpoly.smd'
    win_smd = root / 'mesh/custom_player_highpoly_windows.smd'
    texture_path = root / 'textures_windows_1024/custom_player.bmp'
    for p in [qc_path, source_smd, win_smd, texture_path]:
        if not p.is_file():
            raise FileNotFoundError(f'required input missing: {p}')
    qc = qc_path.read_text(encoding='utf-8-sig', errors='strict')
    if re.search(r'(?im)^\s*\$(?:resizetexture|resizealltextures)\b', qc):
        raise ValueError('QC contains unsupported texture resize directives; use the pre-resized 1024 BMP')
    split = re.search(r'(?im)^\s*\$splitmesh\s+(\d+)\s*$', qc)
    if not split or int(split.group(1)) != 2048:
        raise ValueError('QC must contain $splitmesh 2048')
    model_command_positions = [m.start() for m in re.finditer(r'(?im)^\s*\$(?:body|bodygroup|sequence|attachment|hbox|controller)\b', qc)]
    if not model_command_positions or split.start() > min(model_command_positions):
        raise ValueError('$splitmesh must appear before $body/$sequence/$attachment/$hbox/$controller')
    if not re.search(r'(?im)^\s*\$modelname\s+"models/player/yorha/yorha\.mdl"\s*$', qc):
        raise ValueError('QC modelname must target models/player/yorha/yorha.mdl')
    if not re.search(r'(?im)^\s*\$cdtexture\s+"\./textures_windows_1024/"\s*$', qc):
        raise ValueError('QC must point at textures_windows_1024')
    body_refs = re.findall(r'(?im)^\s*\$body\s+"[^"]+"\s+"([^"]+)"', qc)
    if len(body_refs) != 1 or body_refs[0].replace('\\', '/') != 'mesh/custom_player_highpoly_windows':
        raise ValueError(f'Expected one reference body SMD, got {body_refs}')
    seq_names, anim_refs = get_qc_sequences_and_refs(qc)
    if len(seq_names) != EXPECTED_SEQUENCES or len(set(seq_names)) != EXPECTED_SEQUENCES:
        raise ValueError(f'Expected {EXPECTED_SEQUENCES} unique QC sequences, got {len(seq_names)}')
    if len(anim_refs) != 393:
        raise ValueError(f'Expected 393 unique animation SMD references, got {len(anim_refs)}')
    missing = [rel for rel in anim_refs if not (root / rel).is_file()]
    if missing:
        raise FileNotFoundError(f'{len(missing)} animation SMD references missing: {missing[:12]}')
    ref_nodes, ref_parents = parse_smd_nodes(source_smd)
    animation_parent_mismatches = []
    for rel in anim_refs:
        anim_nodes, anim_parents = parse_smd_nodes(root / rel)
        if anim_nodes != ref_nodes:
            raise ValueError(f'Animation skeleton bone inventory differs from reference: {rel}')
        if anim_parents != ref_parents:
            animation_parent_mismatches.append(rel)
    if animation_parent_mismatches:
        # FunnkyHD V2.0 documents automatic re-parenting while preserving world-space pose.
        raise ValueError(f'{len(animation_parent_mismatches)} animation SMD skeleton parent hierarchies differ; recheck retargeting before compiling. Examples: {animation_parent_mismatches[:8]}')
    win_nodes, win_parents = parse_smd_nodes(win_smd)
    if ref_nodes != win_nodes or ref_parents != win_parents:
        raise ValueError('Windows-corrected reference SMD changed bone names/parents')
    if len(win_nodes) != EXPECTED_BONES or len(win_nodes) > MAX_BONES:
        raise ValueError(f'Expected {EXPECTED_BONES} bones and at most {MAX_BONES}; got {len(win_nodes)}')
    src_lines = source_smd.read_text(encoding='utf-8', errors='strict').splitlines()
    win_lines = win_smd.read_text(encoding='utf-8', errors='strict').splitlines()
    if len(src_lines) != len(win_lines):
        raise ValueError('Source and corrected SMD line counts differ')
    section = ''; corners = 0
    for line_no, (a, b) in enumerate(zip(src_lines, win_lines), 1):
        st = a.strip()
        if st in ('nodes', 'skeleton', 'triangles'):
            section = st
        if section == 'triangles' and st and st != 'end':
            fa, fb = st.split(), b.strip().split()
            if len(fa) == 9:
                if len(fb) != 9:
                    raise ValueError(f'Corrected SMD invalid vertex row at line {line_no}')
                try:
                    va, vb = [float(x) for x in fa], [float(x) for x in fb]
                except ValueError as exc:
                    raise ValueError(f'Non-numeric UV row at line {line_no}') from exc
                if fa[0] != fb[0] or fa[1:8] != fb[1:8]:
                    raise ValueError(f'Correction changed bone/position/normal/U besides V at line {line_no}')
                if abs(vb[8] - (1.0 - va[8])) > 1.1e-7:
                    raise ValueError(f'Incorrect V flip at line {line_no}: {va[8]} -> {vb[8]}')
                corners += 1
            elif st != b.strip():
                raise ValueError(f'Non-vertex triangle data changed at line {line_no}')
        elif st != b.strip():
            raise ValueError(f'SMD non-UV content changed at line {line_no}')
    if corners != EXPECTED_TRIANGLES * 3:
        raise ValueError(f'Expected {EXPECTED_TRIANGLES * 3} triangle corners, got {corners}')
    tri_count, _ = parse_smd_triangles(win_smd)
    if tri_count != EXPECTED_TRIANGLES:
        raise ValueError(f'Expected {EXPECTED_TRIANGLES} source triangles, got {tri_count}')
    bmp = check_bmp(texture_path)
    if bmp['width'] != 1024 or bmp['height'] != 1024:
        raise ValueError(f'Expected 1024x1024 texture, got {bmp["width"]}x{bmp["height"]}')
    hboxes = len(re.findall(r'(?im)^\s*\$hbox\b', qc))
    controllers = len(re.findall(r'(?im)^\s*\$controller\b', qc))
    report = {
        'status': 'PASS_SOURCE_ASSETS', 'project': str(root), 'qc': qc_path.name,
        'qc_sha256': sha256(qc_path), 'source_mesh_sha256': sha256(source_smd),
        'windows_mesh_sha256': sha256(win_smd), 'texture': bmp,
        'bones': len(win_nodes), 'triangles': tri_count, 'vertex_corners': corners,
        'sequences': len(seq_names), 'unique_animation_smd_references': len(anim_refs),
        'missing_animation_smd_references': 0, 'animation_skeleton_hierarchies_checked': len(anim_refs), 'animation_skeleton_mismatches': 0, 'hitboxes': hboxes, 'controllers': controllers,
        'compiler_requirement': 'FunnkyHD StudioMDL V2.0 with functional $splitmesh; auto-downloaded from official GameBanana page if cache is absent'
    }
    return report


def validate_mdl(path: Path, *, profile: str = 'yorha', source_root: Path | None = None) -> dict[str, Any]:
    data = path.read_bytes()
    if len(data) < HEADER_SIZE:
        raise ValueError(f'MDL smaller than studiohdr_t: {len(data)}')
    if data[:4] != b'IDST':
        raise ValueError(f'bad MDL magic: {data[:4]!r}')
    version, declared = i32(data, 4), i32(data, 72)
    if version != MDL_VERSION or declared != len(data):
        raise ValueError(f'header mismatch: version={version}, declared={declared}, actual={len(data)}')
    bones, bone_idx = i32(data, 140), i32(data, 144)
    controllers, controller_idx = i32(data, 148), i32(data, 152)
    hitboxes, hitbox_idx = i32(data, 156), i32(data, 160)
    seqs, seq_idx = i32(data, 164), i32(data, 168)
    seqgroups, seqgroup_idx = i32(data, 172), i32(data, 176)
    textures, texture_idx, texture_data_idx = i32(data, 180), i32(data, 184), i32(data, 188)
    skinrefs, skinfamilies, skin_idx = i32(data, 192), i32(data, 196), i32(data, 200)
    bodyparts, bodypart_idx = i32(data, 204), i32(data, 208)
    if not 1 <= bones <= MAX_BONES:
        raise ValueError(f'invalid bone count {bones}')
    if not 1 <= seqs <= MAX_SEQUENCES:
        raise ValueError(f'invalid sequence count {seqs}')
    if not 1 <= bodyparts <= MAX_BODYPARTS:
        raise ValueError(f'invalid bodypart count {bodyparts}; max supported here is {MAX_BODYPARTS}')
    if not 1 <= textures <= 256:
        raise ValueError(f'invalid texture count {textures}')
    if seqgroups < 1:
        raise ValueError(f'invalid sequence group count {seqgroups}')
    check_range(data, bone_idx, bones * 112, 'bones')
    if controllers: check_range(data, controller_idx, controllers * 24, 'bone controllers')
    if hitboxes: check_range(data, hitbox_idx, hitboxes * 32, 'hitboxes')
    check_range(data, seq_idx, seqs * 176, 'sequences')
    check_range(data, seqgroup_idx, seqgroups * 104, 'sequence groups')
    check_range(data, texture_idx, textures * 80, 'textures')
    check_range(data, bodypart_idx, bodyparts * 76, 'bodyparts')
    if skinrefs < 1 or skinfamilies < 1 or skinrefs * skinfamilies > 100_000:
        raise ValueError(f'invalid skin table {skinrefs} x {skinfamilies}')
    check_range(data, skin_idx, skinrefs * skinfamilies * 2, 'skin refs')
    if profile == 'yorha':
        if bones != EXPECTED_BONES: raise ValueError(f'compiled model should have {EXPECTED_BONES} bones, got {bones}')
        if seqs != EXPECTED_SEQUENCES: raise ValueError(f'compiled model should have {EXPECTED_SEQUENCES} sequences, got {seqs}')
        if bodyparts < 2: raise ValueError('splitmesh probe was passed, but the Yorha model was not split into multiple visible bodyparts')
        if seqgroups != 1: raise ValueError(f'QC has no $sequencegroup directives; expected all animations in the main MDL, got {seqgroups} groups')

    # Validate the complete compiled bone table, not only the header count.
    bone_names=[]; bone_parents=[]; bone_controller_channels=[]
    for bone_no in range(bones):
        rec=bone_idx+bone_no*112
        name=data[rec:rec+32].split(b'\0',1)[0].decode('ascii','replace')
        parent=i32(data,rec+32)
        channels=struct.unpack_from('<6i',data,rec+40)
        rest=struct.unpack_from('<6f',data,rec+64)
        scales=struct.unpack_from('<6f',data,rec+88)
        if not name: raise ValueError(f'empty compiled bone name at index {bone_no}')
        if parent < -1 or parent >= bones or parent == bone_no: raise ValueError(f'invalid compiled bone parent {parent} for {name}')
        if any(ch < -1 or ch >= controllers for ch in channels): raise ValueError(f'invalid controller index on compiled bone {name}: {channels}')
        if any(not math.isfinite(v) for v in rest+scales): raise ValueError(f'non-finite rest pose/scale value for compiled bone {name}')
        if any(v < 0 for v in scales): raise ValueError(f'negative animation scale for compiled bone {name}: {scales}')
        bone_names.append(name); bone_parents.append(parent); bone_controller_channels.append(list(channels))
    if len(set(bone_names)) != bones: raise ValueError('compiled MDL bone names are not unique')
    for start_bone in range(bones):
        seen=set(); current=start_bone
        while current >= 0:
            if current in seen: raise ValueError(f'compiled MDL skeleton contains a parent cycle at bone {bone_names[current]}')
            seen.add(current); current=bone_parents[current]
    if profile == 'yorha':
        mdl_name=data[8:72].split(b'\0',1)[0].decode('ascii','replace').replace('\\','/').rsplit('/',1)[-1].lower()
        if mdl_name not in ('yorha.mdl','yorha'): raise ValueError(f'compiled MDL name must be yorha.mdl, got {mdl_name!r}')
    if profile == 'yorha' and source_root is not None:
        ref_names, ref_parents = parse_smd_nodes(source_root/'mesh/custom_player_highpoly_windows.smd')
        expected_names=[ref_names[i] for i in range(len(ref_names))]
        expected_parents=[ref_parents[i] for i in range(len(ref_parents))]
        if bone_names != expected_names: raise ValueError('compiled MDL bone order/names differ from the corrected reference SMD')
        if bone_parents != expected_parents: raise ValueError('compiled MDL bone hierarchy differs from the corrected reference SMD')

    # Hitboxes/controllers are gameplay data: validate their indices and numeric bounds.
    controller_records=[]
    for ci in range(controllers):
        rec=controller_idx+ci*24
        bone,typ=struct.unpack_from('<ii',data,rec)
        start,end=struct.unpack_from('<ff',data,rec+8)
        rest,index=struct.unpack_from('<ii',data,rec+16)
        if not 0 <= bone < bones: raise ValueError(f'controller {ci} references invalid bone {bone}')
        if typ not in (1,2,4,8,16,32): raise ValueError(f'controller {ci} has unsupported type flag {typ}')
        if not math.isfinite(start) or not math.isfinite(end) or end < start: raise ValueError(f'controller {ci} has invalid range {start}..{end}')
        if not 0 <= index <= 4: raise ValueError(f'controller {ci} has invalid channel index {index}')
        controller_records.append({'bone':bone,'type':typ,'start':start,'end':end,'index':index,'rest':rest})
    hitbox_records=[]
    for hi in range(hitboxes):
        rec=hitbox_idx+hi*32
        bone,group=struct.unpack_from('<ii',data,rec)
        mins=struct.unpack_from('<3f',data,rec+8); maxs=struct.unpack_from('<3f',data,rec+20)
        if not 0 <= bone < bones: raise ValueError(f'hitbox {hi} references invalid bone {bone}')
        if group < 0 or any(not math.isfinite(v) for v in mins+maxs): raise ValueError(f'hitbox {hi} has invalid group/bounds')
        if any(mins[k] > maxs[k] for k in range(3)): raise ValueError(f'hitbox {hi} has inverted bounds: {mins} .. {maxs}')
        hitbox_records.append({'bone':bone,'group':group,'mins':mins,'maxs':maxs})
    if profile == 'yorha' and (controllers != 5 or hitboxes != 35):
        raise ValueError(f'compiled gameplay tables changed unexpectedly: controllers={controllers}, hitboxes={hitboxes}')

    sequence_names=[]; frame_count=0; blends_total=0; max_frames=0
    for si in range(seqs):
        rec=seq_idx+si*176
        name=data[rec:rec+32].split(b'\0',1)[0].decode('ascii','replace')
        fps=struct.unpack_from('<f',data,rec+32)[0]
        ne, event_idx=struct.unpack_from('<ii',data,rec+48)
        nframes=i32(data,rec+56)
        nblends, anim_idx=struct.unpack_from('<ii',data,rec+120)
        seqgroup=i32(data,rec+156)
        if not name or not (fps > 0 and fps < 1000): raise ValueError(f'invalid sequence {si}: name={name!r}, fps={fps}')
        if not 1 <= nframes <= 512: raise ValueError(f'invalid frame count in {name}: {nframes}')
        if not 1 <= nblends <= 16: raise ValueError(f'invalid blend count in {name}: {nblends}')
        if not 0 <= seqgroup < seqgroups: raise ValueError(f'invalid sequence group {seqgroup} for {name}')
        # Require animation headers to point inside the file for sequences in the main group.
        if seqgroup == 0:
            check_range(data, anim_idx, bones * nblends * 12, f'animation headers for {name}')
            # Walk every active bone/channel RLE stream for every blend. This catches
            # offsets into the wrong table, truncated runs, and frame streams that cannot
            # supply the sequence's declared number of frames.
            for blend_no in range(nblends):
                blend_base=anim_idx+blend_no*bones*12
                for bone_no in range(bones):
                    anim_rec=blend_base+bone_no*12
                    for channel in range(6):
                        rel=u16(data,anim_rec+channel*2)
                        if rel == 0: continue
                        cursor=anim_rec+rel; produced=0; run_count=0
                        if cursor < HEADER_SIZE or cursor >= len(data):
                            raise ValueError(f'animation channel offset out of file in {name}: blend={blend_no}, bone={bone_no}, channel={channel}, offset={rel}')
                        while produced < nframes:
                            check_range(data,cursor,2,f'animation RLE run header {name}')
                            valid,total=data[cursor],data[cursor+1]; cursor+=2
                            if valid < 1 or total < valid or total < 1:
                                raise ValueError(f'invalid animation RLE counts {valid}/{total} in {name}, bone={bone_no}, channel={channel}')
                            check_range(data,cursor,valid*2,f'animation RLE values {name}')
                            values=struct.unpack_from('<'+'h'*valid,data,cursor)
                            if any(not -32768 <= value <= 32767 for value in values):
                                raise ValueError(f'invalid signed animation value in {name}')
                            cursor+=valid*2; produced+=total; run_count+=1
                            if run_count > nframes+2: raise ValueError(f'animation RLE stream has too many runs in {name}')
        elif seqgroup != 0:
            raise ValueError(f'sequence {name} references external sequence group {seqgroup}, but its sidecar has not been validated by this workflow')
        if ne:
            check_range(data, event_idx, ne * 76, f'events for {name}')
            for ei in range(ne):
                ev=i32(data,event_idx+ei*76)
                if not 0 <= ev < nframes: raise ValueError(f'event frame out of range in {name}: {ev}/{nframes}')
        sequence_names.append(name); frame_count += nframes; blends_total += nblends; max_frames=max(max_frames,nframes)
    if profile == 'yorha' and len(set(sequence_names)) != EXPECTED_SEQUENCES:
        raise ValueError('compiled sequence names are not unique')
    if profile == 'yorha' and source_root is not None:
        source_qc=(source_root/'custom_player_windows.qc').read_text(encoding='utf-8-sig',errors='strict')
        expected_sequence_names,_=get_qc_sequences_and_refs(source_qc)
        if sequence_names != expected_sequence_names:
            raise ValueError('compiled sequence names/order differ from the QC; one or more animations may have been dropped or renamed')

    texture_info=[]
    for ti in range(textures):
        rec=texture_idx+ti*80
        name=data[rec:rec+64].split(b'\0',1)[0].decode('ascii','replace')
        width,height,pixels_idx=struct.unpack_from('<iii',data,rec+68)
        if not (1 <= width <= 1024 and 1 <= height <= 1024):
            raise ValueError(f'texture exceeds Sven Co-op limit 1024: {name} {width}x{height}')
        check_range(data,pixels_idx,width*height+768,f'texture image {name}')
        texture_info.append({'name':name,'width':width,'height':height,'palette_entries':256,'pixel_offset':pixels_idx})

    models=[]; triangles_total=0; verts_total=0; norms_total=0; max_verts=0; max_norms=0; model_count=0
    for bi in range(bodyparts):
        bp=bodypart_idx+bi*76
        bp_name=data[bp:bp+64].split(b'\0',1)[0].decode('ascii','replace')
        nmodels,base,model_idx=struct.unpack_from('<iii',data,bp+64)
        if not 1 <= nmodels <= 64: raise ValueError(f'invalid model count in bodypart {bp_name}: {nmodels}')
        check_range(data,model_idx,nmodels*112,f'model descriptors for {bp_name}')
        for mi in range(nmodels):
            m=model_idx+mi*112
            name=data[m:m+64].split(b'\0',1)[0].decode('ascii','replace')
            nmesh,mesh_idx=struct.unpack_from('<ii',data,m+72)
            nverts,vertinfo,vert_idx=struct.unpack_from('<iii',data,m+80)
            nnorms,norminfo,norm_idx=struct.unpack_from('<iii',data,m+92)
            if not 0 <= nmesh <= 256: raise ValueError(f'invalid mesh count in {name}: {nmesh}')
            if not 0 <= nverts <= MAX_VERTEX_ROWS_PER_MODEL or not 0 <= nnorms <= MAX_VERTEX_ROWS_PER_MODEL:
                raise ValueError(f'{name} exceeds GoldSrc piece budget: vertices={nverts}, normals={nnorms}; each <= {MAX_VERTEX_ROWS_PER_MODEL}')
            check_range(data,mesh_idx,nmesh*20,f'mesh descriptors for {name}')
            if nverts:
                check_range(data,vertinfo,nverts,f'vertex bone ids {name}'); check_range(data,vert_idx,nverts*12,f'vertices {name}')
                if any(b >= bones for b in data[vertinfo:vertinfo+nverts]): raise ValueError(f'bad vertex bone index in {name}')
            if nnorms:
                check_range(data,norminfo,nnorms,f'normal bone ids {name}'); check_range(data,norm_idx,nnorms*12,f'normals {name}')
                if any(b >= bones for b in data[norminfo:norminfo+nnorms]): raise ValueError(f'bad normal bone index in {name}')
            model_tri=0
            for mj in range(nmesh):
                mr=mesh_idx+mj*20
                ntri,cmd_idx=i32(data,mr),i32(data,mr+4)
                check_range(data,cmd_idx,2,f'triangle command list {name}')
                declared_from_commands=0; cursor=cmd_idx; command_count=0
                while True:
                    command_count+=1
                    if command_count > max(100, ntri*4+100): raise ValueError(f'triangle command guard tripped in {name}')
                    count=struct.unpack_from('<h',data,cursor)[0]; cursor+=2
                    if count == 0: break
                    n=abs(count)
                    if n < 3: raise ValueError(f'invalid triangle command vertex count {count} in {name}')
                    check_range(data,cursor,n*8,f'triangle command vertices {name}')
                    for vi in range(n):
                        v_idx,n_idx=struct.unpack_from('<hh',data,cursor+vi*8)
                        if not 0 <= v_idx < nverts: raise ValueError(f'vertex index out of range in {name}: {v_idx}/{nverts}')
                        if not 0 <= n_idx < nnorms: raise ValueError(f'normal index out of range in {name}: {n_idx}/{nnorms}')
                    declared_from_commands += n-2; cursor += n*8
                    if cursor > len(data): raise ValueError(f'triangle commands leave file in {name}')
                if ntri != declared_from_commands: raise ValueError(f'{name} mesh triangles mismatch: header={ntri}, commands={declared_from_commands}')
                model_tri += ntri
            if profile == 'yorha' and model_tri > 4080:
                raise ValueError(f'{name} exceeds the FunnkyHD splitmesh triangle budget: {model_tri} > 4080')
            triangles_total += model_tri; verts_total += nverts; norms_total += nnorms; model_count += 1
            max_verts=max(max_verts,nverts); max_norms=max(max_norms,nnorms)
            models.append({'bodypart':bp_name,'model':name,'vertices':nverts,'normals':nnorms,'triangles':model_tri,'meshes':nmesh})
    if profile == 'yorha' and triangles_total != EXPECTED_TRIANGLES:
        raise ValueError(f'compiled triangle count mismatch: expected {EXPECTED_TRIANGLES}, got {triangles_total}')
    if profile == 'probe' and triangles_total != 2050:
        raise ValueError(f'splitmesh probe expected 2050 triangles, got {triangles_total}')
    if profile == 'probe' and bodyparts < 2:
        raise ValueError('compiler accepted $splitmesh text but did not split the 2050-triangle/over-2048-vertex probe')
    if profile == 'probe' and (bones != 1 or seqs != 1):
        raise ValueError(f'compiler probe inventory mismatch bones={bones}, sequences={seqs}')
    if profile == 'yorha' and (max_verts > 2048 or max_norms > 2048):
        raise ValueError('one or more generated body parts exceed maxverts=2048')
    return {
        'status':'PASS_MDL_V10_STRUCTURAL_VALIDATION','path':str(path),'bytes':len(data),'sha256':sha256(path),
        'magic':'IDST','version':version,'declared_length':declared,'bones':bones,'bone_controllers':controllers,'bone_names':bone_names,'bone_parents':bone_parents,'controller_records':controller_records,
        'hitboxes':hitboxes,'hitbox_records':hitbox_records,'sequences':seqs,'sequence_names':sequence_names,'frame_sum':frame_count,
        'blend_arrays':blends_total,'max_frames_per_sequence':max_frames,'sequence_groups':seqgroups,
        'textures':texture_info,'bodyparts':bodyparts,'model_descriptors':model_count,'triangles_total':triangles_total,
        'vertices_total':verts_total,'normals_total':norms_total,'max_vertices_per_piece':max_verts,
        'max_normals_per_piece':max_norms,'models':models,'runtime_test':'PENDING_HLMV_AND_SVEN_COOP'
    }


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument('--root',type=Path,required=True)
    ap.add_argument('--mode',choices=['sources','mdl','probe'],default='sources')
    ap.add_argument('--mdl',type=Path)
    ap.add_argument('--report',type=Path)
    a=ap.parse_args(); root=a.root.expanduser().resolve(strict=True)
    if a.mode == 'sources': result=validate_sources(root)
    else:
        if not a.mdl: ap.error('--mdl is required for mode mdl/probe')
        result=validate_mdl(a.mdl.expanduser().resolve(strict=True),profile='probe' if a.mode=='probe' else 'yorha',source_root=root if a.mode=='mdl' else None)
    result['mode']=a.mode
    report_path=a.report.expanduser().resolve() if a.report else None
    if report_path:
        report_path.parent.mkdir(parents=True,exist_ok=True)
        report_path.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2,ensure_ascii=False))
    return 0

if __name__ == '__main__':
    try: raise SystemExit(main())
    except Exception as exc:
        print(f'FAIL: {type(exc).__name__}: {exc}',file=sys.stderr)
        raise SystemExit(2)
