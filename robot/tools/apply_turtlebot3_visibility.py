#!/usr/bin/env python3
from pathlib import Path
import re
import shutil
import sys

MODEL = Path('/workspace/robot/models/turtlebot3/gz_waffle.sdf.xacro')
BACKUP = MODEL.with_name('gz_waffle_before_visibility.sdf.xacro')
START = '<!-- DEMO_VISIBILITY_OVERLAY_START -->'
END = '<!-- DEMO_VISIBILITY_OVERLAY_END -->'

OVERLAY = r'''
      <!-- DEMO_VISIBILITY_OVERLAY_START -->
      <!-- Visual-only additions. No collision, inertia, sensor, joint, or plugin changes. -->
      <visual name="demo_safety_orange_top_cover">
        <pose>0 0 0.19 0 0 0</pose>
        <geometry>
          <box>
            <size>0.24 0.20 0.035</size>
          </box>
        </geometry>
        <material>
          <ambient>0.95 0.28 0.03 1</ambient>
          <diffuse>0.95 0.28 0.03 1</diffuse>
          <specular>0.30 0.30 0.30 1</specular>
        </material>
      </visual>

      <visual name="demo_graphite_front_panel">
        <pose>0.105 0 0.17 0 0 0</pose>
        <geometry>
          <box>
            <size>0.025 0.17 0.07</size>
          </box>
        </geometry>
        <material>
          <ambient>0.05 0.07 0.09 1</ambient>
          <diffuse>0.05 0.07 0.09 1</diffuse>
          <specular>0.20 0.20 0.20 1</specular>
        </material>
      </visual>

      <visual name="demo_cyan_status_beacon">
        <pose>-0.07 0 0.235 0 0 0</pose>
        <geometry>
          <cylinder>
            <radius>0.028</radius>
            <length>0.045</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.00 0.55 1.00 1</ambient>
          <diffuse>0.00 0.55 1.00 1</diffuse>
          <specular>0.70 0.70 0.70 1</specular>
          <emissive>0.00 0.18 0.40 1</emissive>
        </material>
      </visual>
      <!-- DEMO_VISIBILITY_OVERLAY_END -->
'''.strip('\n')


def find_link_end(text: str, link_name: str) -> int:
    start_match = re.search(rf'<link\s+name=["\']{re.escape(link_name)}["\']\s*>', text)
    if not start_match:
        raise RuntimeError(f'Could not find <link name="{link_name}"> in {MODEL}')
    token_re = re.compile(r'<link\b[^>]*>|</link>')
    depth = 0
    for match in token_re.finditer(text, start_match.start()):
        token = match.group(0)
        if token.startswith('</link'):
            depth -= 1
            if depth == 0:
                return match.start()
        else:
            depth += 1
    raise RuntimeError(f'Could not find closing </link> for {link_name}')


def main() -> int:
    if not MODEL.is_file():
        print(f'ERROR: model not found: {MODEL}', file=sys.stderr)
        return 1

    text = MODEL.read_text(encoding='utf-8')
    if START in text or END in text:
        print('Visibility overlay is already present; no changes made.')
        return 0

    if not BACKUP.exists():
        shutil.copy2(MODEL, BACKUP)
        print(f'Backup created: {BACKUP}')

    insert_at = find_link_end(text, 'base_link')
    updated = text[:insert_at] + '\n' + OVERLAY + '\n    ' + text[insert_at:]
    MODEL.write_text(updated, encoding='utf-8')
    print(f'Updated: {MODEL}')
    print('Added visual-only safety-orange cover, graphite panel, and cyan beacon.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
