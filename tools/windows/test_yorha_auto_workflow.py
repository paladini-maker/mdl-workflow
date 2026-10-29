#!/usr/bin/env python3
"""Regression tests for the Yorha source gate and GoldSrc MDL validator."""
from __future__ import annotations
import importlib.util
import re
import struct
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name('validate_yorha_auto_workflow.py')
spec = importlib.util.spec_from_file_location('yorha_validator', SCRIPT)
validator = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(validator)
ROOT = SCRIPT.resolve().parents[2]


def build_minimal_test_mdl(triangle_counts: list[int], animation_stream: str = 'none') -> bytes:
    """Build a minimal structurally valid IDST v10 fixture for validator regression tests.
    This fixture is only a parser test, never a substitute for StudioMDL output.
    """
    header_size = validator.HEADER_SIZE
    data = bytearray(b'\0' * header_size)
    data[0:4] = b'IDST'
    struct.pack_into('<i', data, 4, 10)
    data[8:72] = b'validator_test.mdl\0' + b'\0' * (64 - len('validator_test.mdl') - 1)
    # Bone table: one root bone, 112 bytes.
    bone_index = len(data)
    bone = bytearray(112)
    bone[:32] = b'root\0' + b'\0' * 27
    struct.pack_into('<ii', bone, 32, -1, 0)
    struct.pack_into('<6i', bone, 40, *([-1] * 6))
    struct.pack_into('<6f', bone, 64, 0, 0, 0, 0, 0, 0)
    struct.pack_into('<6f', bone, 88, 1, 1, 1, 1, 1, 1)
    data.extend(bone)
    controller_index = len(data)
    hitbox_index = len(data)
    # One sequence descriptor and one default sequence group.
    seq_index = len(data); data.extend(b'\0' * 176)
    seqgroup_index = len(data)
    group = bytearray(104); group[:32] = b'default\0' + b'\0' * 24; data.extend(group)
    # Bodypart table placeholder.
    bodypart_index = len(data); data.extend(b'\0' * (76 * len(triangle_counts)))
    model_records = len(data); data.extend(b'\0' * (112 * len(triangle_counts)))
    model_descs=[]
    for part_idx, tri_count in enumerate(triangle_counts):
        nv = nn = tri_count * 3
        vertinfo_idx = len(data); data.extend(bytes([0]) * nv)
        data.extend(b'\0' * ((-len(data)) % 4))
        norminfo_idx = len(data); data.extend(bytes([0]) * nn)
        data.extend(b'\0' * ((-len(data)) % 4))
        vert_idx = len(data)
        for i in range(nv): data.extend(struct.pack('<3f', float(i % 31), float(i // 31), 0.0))
        data.extend(b'\0' * ((-len(data)) % 4))
        norm_idx = len(data)
        for _ in range(nn): data.extend(struct.pack('<3f', 0.0, 0.0, 1.0))
        data.extend(b'\0' * ((-len(data)) % 4))
        mesh_index = len(data); data.extend(b'\0' * 20)
        tri_index = len(data)
        for t in range(tri_count):
            data.extend(struct.pack('<h', 3))
            base=t*3
            for j in range(3): data.extend(struct.pack('<4h', base+j, base+j, 0, 0))
        data.extend(struct.pack('<h',0)); data.extend(b'\0' * ((-len(data)) % 4))
        struct.pack_into('<5i',data,mesh_index,tri_count,tri_index,0,nn,norm_idx)
        model = bytearray(112); model[:64] = f'part{part_idx:02d}'.encode().ljust(64,b'\0')
        struct.pack_into('<if10i',model,64,0,float(20),1,mesh_index,nv,vertinfo_idx,vert_idx,nn,norminfo_idx,norm_idx,0,0)
        model_descs.append(model)
    # Bodypart records and model descriptor pointers.
    for i,model in enumerate(model_descs):
        bp = bytearray(76); bp[:64]=f'body{i:02d}'.encode().ljust(64,b'\0')
        struct.pack_into('<iii',bp,64,1,1,model_records+i*112)
        data[bodypart_index+i*76:bodypart_index+(i+1)*76]=bp
        data[model_records+i*112:model_records+(i+1)*112]=model
    # One indexed texture, 16x16 pixels + 256-color palette.
    texture_index = len(data); data.extend(b'\0'*80)
    skin_index = len(data); data.extend(struct.pack('<h',0)); data.extend(b'\0'*((-len(data)) % 4))
    pixel_index = len(data); data.extend(bytes(16*16)); data.extend(struct.pack('<H',256)); data.extend(bytes(768))
    texture=bytearray(80); texture[:64]=b'test.bmp\0'+b'\0'*(64-len('test.bmp')-1)
    struct.pack_into('<4i',texture,64,0,16,16,pixel_index)
    data[texture_index:texture_index+80]=texture
    # Minimal frame stream: one bone's six zero offsets, or a controlled animation RLE stream.
    animation_index = len(data)
    anim_header = bytearray(12)
    if animation_stream in ('valid', 'truncated', 'bad_counts'):
        struct.pack_into('<H', anim_header, 0, 12)
    data.extend(anim_header)
    if animation_stream == 'valid':
        data.extend(bytes((1, 1)))
        data.extend(struct.pack('<h', 0))
    elif animation_stream == 'bad_counts':
        data.extend(bytes((0, 1)))
    elif animation_stream not in ('none', 'truncated'):
        raise ValueError(f'unknown animation_stream fixture: {animation_stream}')
    seq=bytearray(176); seq[:32]=b'idle\0'+b'\0'*27
    struct.pack_into('<f',seq,32,10.0); struct.pack_into('<i',seq,36,1)
    struct.pack_into('<ii',seq,40,0,0); struct.pack_into('<ii',seq,48,0,0)
    struct.pack_into('<i',seq,56,1); struct.pack_into('<ii',seq,120,1,animation_index)
    struct.pack_into('<i',seq,156,0)
    data[seq_index:seq_index+176]=seq
    # Header absolute offsets/counts.
    struct.pack_into('<ii',data,140,1,bone_index)
    struct.pack_into('<ii',data,148,0,controller_index)
    struct.pack_into('<ii',data,156,0,hitbox_index)
    struct.pack_into('<ii',data,164,1,seq_index)
    struct.pack_into('<ii',data,172,1,seqgroup_index)
    struct.pack_into('<iii',data,180,1,texture_index,pixel_index)
    struct.pack_into('<iii',data,192,1,1,skin_index)
    struct.pack_into('<ii',data,204,len(triangle_counts),bodypart_index)
    struct.pack_into('<i',data,72,len(data))
    return bytes(data)


class WorkflowSourceTests(unittest.TestCase):
    def test_real_project_sources_pass_full_preflight(self):
        report=validator.validate_sources(ROOT)
        self.assertEqual(report['status'],'PASS_SOURCE_ASSETS')
        self.assertEqual(report['triangles'],99998)
        self.assertEqual(report['sequences'],208)
        self.assertEqual(report['unique_animation_smd_references'],393)
        self.assertEqual(report['animation_skeleton_mismatches'],0)
        self.assertEqual(report['texture']['width'],1024)

    def test_compiler_capability_probe_really_exceeds_2048_unique_vertices(self):
        probe_dir=SCRIPT.parent/'compiler_probe'
        qc=(probe_dir/'probe.qc').read_text(encoding='utf-8')
        self.assertLess(qc.index('$splitmesh 2048'),qc.index('$body'))
        tri,corners=validator.parse_smd_triangles(probe_dir/'body.smd')
        self.assertEqual(tri,2050)
        self.assertEqual(corners,6150)
        rows=(probe_dir/'body.smd').read_text(encoding='utf-8').splitlines()
        i=next(i for i,line in enumerate(rows) if line.strip()=='triangles')+1
        unique=set(); seen=0
        while i<len(rows) and rows[i].strip()!='end':
            i+=1
            for _ in range(3):
                fields=tuple(rows[i].strip().split()); i+=1
                unique.add(fields)
            seen+=1
        self.assertEqual(seen,2050)
        self.assertGreater(len(unique),2048)

    def test_powershell_workflow_delimiters_are_balanced(self):
        text=(SCRIPT.parent/'Invoke-YorhaBuild.ps1').read_text(encoding='utf-8')
        stack=[]; i=0; line=1; state='code'; pairs={')':'(',']':'[','}':'{'}; opening={'(':')','[':']','{':'}'}
        while i<len(text):
            ch=text[i]; nxt=text[i+1] if i+1<len(text) else ''
            if ch=='\n': line+=1
            if state=='code':
                if ch=='#': state='comment'
                elif ch=="'": state='single'
                elif ch=='"': state='double'
                elif ch in opening: stack.append((ch,line))
                elif ch in pairs:
                    self.assertTrue(stack and stack[-1][0]==pairs[ch], f'mismatched {ch} at PowerShell line {line}')
                    stack.pop()
            elif state=='comment':
                if ch=='\n': state='code'
            elif state=='single':
                if ch=="'":
                    if nxt=="'": i+=1
                    else: state='code'
            elif state=='double':
                if ch=='`': i+=1
                elif ch=='"': state='code'
            i+=1
        self.assertEqual(state,'code','unterminated PowerShell string/comment')
        self.assertEqual(stack,[],f'unclosed PowerShell delimiters: {stack[-4:]}')

    def test_windows_workflow_defaults_to_official_v2_and_fails_closed(self):
        ps=(SCRIPT.parent/'Invoke-YorhaBuild.ps1').read_text(encoding='utf-8')
        self.assertIn('funnkyhd-studiomdl_f6dee.7z',ps)
        self.assertIn('PASS_SPLITMESH_2050_TRIANGLE_FIXTURE',ps)
        self.assertIn('api_url=$script:ResolvedGameBananaApiUrl',ps)
        self.assertNotIn('api_url=$OfficialApiUrl',ps)
        self.assertIn('Get-FileHash',ps)
        self.assertIn('restaurará la salida anterior',ps)
        self.assertIn('only use official FunnkyHD StudioMDL V2.0 by default',ps)
        self.assertIn('https://www.7-zip.org/a/7zr.exe',ps)
        self.assertIn('Get-Portable7zr',ps)
        self.assertIn('Invoke-YorhaBuild.ps1', (ROOT/'compile_yorha_auto.bat').read_text(encoding='utf-8'))
        workflow=(ROOT/'.github/workflows/yorha-windows-auto-build.yml').read_text(encoding='utf-8')
        self.assertIn('runs-on: windows-latest',workflow)
        self.assertIn('validate_yorha_auto_workflow.py',workflow)
        self.assertNotIn('tools/FunnkyHD_StudioMDL_V2.0/**',workflow)

    def test_portable_extractor_cache_is_hash_verified(self):
        ps=(SCRIPT.parent/'Invoke-YorhaBuild.ps1').read_text(encoding='utf-8')
        self.assertIn("Get-Content -LiteralPath $extractorInfoPath -Raw | ConvertFrom-Json",ps)
        self.assertIn('$actualHash -eq [string]$extractorInfo.sha256',ps)
        self.assertIn("Remove-Item -LiteralPath $extractorInfoPath -Force",ps)

    def test_qc_uses_supported_v2_splitmesh_and_preindexed_texture_without_resize(self):
        qc=(ROOT/'custom_player_windows.qc').read_text(encoding='utf-8-sig')
        self.assertLess(qc.index('$splitmesh 2048'),qc.index('$body '))
        self.assertIn('$cdtexture "./textures_windows_1024/"',qc)
        self.assertNotRegex(qc,r'(?im)^\s*\$resizetexture\b')
        self.assertEqual(len(re.findall(r'(?im)^\s*\$sequence\s+"',qc)),208)

    def test_unpacker_bootstraps_from_official_7zip_if_no_extractor_is_installed(self):
        ps=(SCRIPT.parent/'Invoke-YorhaBuild.ps1').read_text(encoding='utf-8')
        self.assertIn('function Get-Portable7zr',ps)
        self.assertIn('https://www.7-zip.org/a/7zr.exe',ps)
        self.assertIn('PASS_OFFICIAL_7ZIP_PORTABLE_EXTRACTOR',ps)
        self.assertIn("& $extractor 't' $ArchivePath '-y'",ps)
        self.assertIn("& $extractor 'x' $ArchivePath",ps)

    def test_execution_status_does_not_claim_actual_windows_compile(self):
        report=__import__('json').loads((ROOT/'WORKFLOW_EXECUTION_STATUS_V41.json').read_text(encoding='utf-8'))
        self.assertEqual(report['status'],'SOURCE_PREFLIGHT_PASS__WINDOWS_COMPILE_PENDING')
        self.assertFalse(report['compiler_target']['binary_in_package'])
        self.assertEqual(report['checks_not_executed_here']['actual_yorha_mdl_compilation'],'PENDING_NATIVE_WINDOWS_OR_GITHUB_ACTIONS')

    def test_mdl_parser_passes_synthetic_multi_bodypart_fixture(self):
        mdl=build_minimal_test_mdl([513,513,512,512])
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/'synthetic-probe.mdl'; path.write_bytes(mdl)
            result=validator.validate_mdl(path,profile='probe')
            self.assertEqual(result['status'],'PASS_MDL_V10_STRUCTURAL_VALIDATION')
            self.assertEqual(result['bodyparts'],4)
            self.assertEqual(result['triangles_total'],2050)

    def test_mdl_parser_accepts_valid_compressed_animation_rle(self):
        mdl=build_minimal_test_mdl([513,513,512,512], animation_stream='valid')
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/'valid-animation-rle.mdl'; path.write_bytes(mdl)
            result=validator.validate_mdl(path,profile='probe')
            self.assertEqual(result['status'],'PASS_MDL_V10_STRUCTURAL_VALIDATION')

    def test_mdl_parser_rejects_truncated_animation_rle(self):
        mdl=build_minimal_test_mdl([513,513,512,512], animation_stream='truncated')
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/'truncated-animation-rle.mdl'; path.write_bytes(mdl)
            with self.assertRaisesRegex(ValueError,'animation channel offset|out of bounds|RLE'):
                validator.validate_mdl(path,profile='probe')

    def test_mdl_parser_rejects_zero_length_animation_rle_run(self):
        mdl=build_minimal_test_mdl([513,513,512,512], animation_stream='bad_counts')
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/'bad-animation-rle.mdl'; path.write_bytes(mdl)
            with self.assertRaisesRegex(ValueError,'animation RLE counts'):
                validator.validate_mdl(path,profile='probe')


    def test_github_deploy_script_has_balanced_powershell_delimiters(self):
        text=(ROOT/'Deploy-Yorha-GitHub.ps1').read_text(encoding='utf-8')
        stack=[]; i=0; line=1; state='code'; pairs={')':'(',']':'[','}':'{'}; opening={'(':')','[':']','{':'}'}
        while i<len(text):
            ch=text[i]; nxt=text[i+1] if i+1<len(text) else ''
            if ch=='\n': line+=1
            if state=='code':
                if ch=='#': state='comment'
                elif ch=="'": state='single'
                elif ch=='"': state='double'
                elif ch in opening: stack.append((ch,line))
                elif ch in pairs:
                    self.assertTrue(stack and stack[-1][0]==pairs[ch], f'mismatched {ch} at deploy-script line {line}')
                    stack.pop()
            elif state=='comment':
                if ch=='\n': state='code'
            elif state=='single':
                if ch=="'":
                    if nxt=="'": i+=1
                    else: state='code'
            elif state=='double':
                if ch=='`': i+=1
                elif ch=='"': state='code'
            i+=1
        self.assertEqual(state,'code','unterminated PowerShell string/comment in deploy script')
        self.assertEqual(stack,[],f'unclosed deploy-script delimiters: {stack[-4:]}')

    def test_github_deploy_defaults_to_private_and_does_not_force_push(self):
        text=(ROOT/'Deploy-Yorha-GitHub.ps1').read_text(encoding='utf-8')
        self.assertIn("[string]$Visibility = 'private'",text)
        self.assertIn("@('--private')",text)
        self.assertIn("@('push','--set-upstream','origin','main')",text)
        self.assertNotIn("'push','--force'",text)
        self.assertIn('No se modificó ni sobrescribió',text)

    def test_github_deploy_targets_existing_mdl_workflow_repo_and_preserves_visibility(self):
        text=(ROOT/'Deploy-Yorha-GitHub.ps1').read_text(encoding='utf-8-sig')
        self.assertIn("[string]$RepositoryName = 'mdl-workflow'",text)
        self.assertIn("'repo','view',$script:RepoFullName,'--json','visibility','--jq','.visibility'",text)
        self.assertIn('$script:ActualVisibility = $visibilityLookup.Output.Trim().ToLowerInvariant()',text)
        self.assertIn('visibility=$script:ActualVisibility',text)
        # Existing repo visibility is queried, never mutated by the script.
        self.assertNotIn("'repo','edit'",text)
        self.assertNotIn("'repo','set-default'",text)

    def test_github_deploy_requires_mdl_and_structural_evidence(self):
        text=(ROOT/'Deploy-Yorha-GitHub.ps1').read_text(encoding='utf-8')
        self.assertIn("'YORHA_AUTO_BUILD_REPORT.json'",text)
        self.assertIn("'yorha-mdl-structural-validation.json'",text)
        self.assertIn('PASS_COMPILE_ARTIFACT_AND_STRUCTURAL_REPORT_DOWNLOADED',text)
        self.assertIn("'--log-failed'",text)
        self.assertIn('github-actions-failed.log',text)

    def test_mdl_parser_rejects_single_part_probe(self):
        mdl=build_minimal_test_mdl([2050])
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/'unsplit.mdl'; path.write_bytes(mdl)
            with self.assertRaisesRegex(ValueError,'exceeds GoldSrc piece budget'):
                validator.validate_mdl(path,profile='probe')

if __name__=='__main__':
    unittest.main(verbosity=2)
