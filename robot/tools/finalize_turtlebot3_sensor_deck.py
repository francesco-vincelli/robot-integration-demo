#!/usr/bin/env python3
from pathlib import Path
import re
import shutil
import sys

MODEL = Path('/workspace/robot/models/turtlebot3/gz_waffle.sdf.xacro')
BACKUP = MODEL.with_name('gz_waffle_before_sensor_deck.sdf.xacro')

GRAPHITE_VISUAL = 'demo_graphite_front_panel'
MOUNT_START = '<!-- DEMO_SENSOR_DECK_MOUNTS_START -->'
MOUNT_END = '<!-- DEMO_SENSOR_DECK_MOUNTS_END -->'

MOUNTS = r'''
      <!-- DEMO_SENSOR_DECK_MOUNTS_START -->
      <!-- Visual-only mounting posts for the raised orange sensor deck. -->
      <visual name="demo_mount_front_left">
        <pose>0.075 0.070 0.116 0 0 0</pose>
        <geometry><box><size>0.025 0.025 0.070</size></box></geometry>
        <material>
          <ambient>0.05 0.07 0.09 1</ambient>
          <diffuse>0.05 0.07 0.09 1</diffuse>
          <specular>0.20 0.20 0.20 1</specular>
        </material>
      </visual>

      <visual name="demo_mount_front_right">
        <pose>0.075 -0.070 0.116 0 0 0</pose>
        <geometry><box><size>0.025 0.025 0.070</size></box></geometry>
        <material>
          <ambient>0.05 0.07 0.09 1</ambient>
          <diffuse>0.05 0.07 0.09 1</diffuse>
          <specular>0.20 0.20 0.20 1</specular>
        </material>
      </visual>

      <visual name="demo_mount_rear_left">
        <pose>-0.075 0.070 0.116 0 0 0</pose>
        <geometry><box><size>0.025 0.025 0.070</size></box></geometry>
        <material>
          <ambient>0.05 0.07 0.09 1</ambient>
          <diffuse>0.05 0.07 0.09 1</diffuse>
          <specular>0.20 0.20 0.20 1</specular>
        </material>
      </visual>

      <visual name="demo_mount_rear_right">
        <pose>-0.075 -0.070 0.116 0 0 0</pose>
        <geometry><box><size>0.025 0.025 0.070</size></box></geometry>
        <material>
          <ambient>0.05 0.07 0.09 1</ambient>
          <diffuse>0.05 0.07 0.09 1</diffuse>
          <specular>0.20 0.20 0.20 1</specular>
        </material>
      </visual>
      <!-- DEMO_SENSOR_DECK_MOUNTS_END -->
'''.strip('\n')


def remove_named_visual(text: str, name: str) -> tuple[str, int]:
    pattern = re.compile(
        rf'\s*<visual\s+name=["\']{re.escape(name)}["\']\s*>.*?</visual>\s*',
        re.S,
    )
    return pattern.subn('\n', text)


def replace_visual_pose(text: str, visual_name: str, pose: str) -> tuple[str, int]:
    pattern = re.compile(
        rf'(<visual\s+name=["\']{re.escape(visual_name)}["\']\s*>\s*<pose>).*?(</pose>)',
        re.S,
    )
    return pattern.subn(rf'\g<1>{pose}\g<2>', text, count=1)


def find_link_end(text: str, link_name: str) -> int:
    start = re.search(rf'<link\s+name=["\']{re.escape(link_name)}["\']\s*>', text)
    if not start:
        raise RuntimeError(f'Could not find link {link_name!r}')
    token_re = re.compile(r'<link\b[^>]*>|</link>')
    depth = 0
    for match in token_re.finditer(text, start.start()):
        if match.group(0).startswith('</link'):
            depth -= 1
            if depth == 0:
                return match.start()
        else:
            depth += 1
    raise RuntimeError(f'Could not find closing tag for link {link_name!r}')


def main() -> int:
    if not MODEL.is_file():
        print(f'ERROR: missing model: {MODEL}', file=sys.stderr)
        return 1

    text = MODEL.read_text(encoding='utf-8')
    if 'demo_safety_orange_top_cover' not in text or 'demo_cyan_status_beacon' not in text:
        print('ERROR: visibility overlay is missing. Apply the earlier visibility update first.', file=sys.stderr)
        return 2

    if not BACKUP.exists():
        shutil.copy2(MODEL, BACKUP)
        print(f'Backup created: {BACKUP}')

    # Keep the visible raised deck and beacon at the tested final values.
    text, cover_count = replace_visual_pose(
        text, 'demo_safety_orange_top_cover', '0 0 0.145 0 0 0'
    )
    text, beacon_count = replace_visual_pose(
        text, 'demo_cyan_status_beacon', '-0.07 0 0.185 0 0 0'
    )

    # Remove the single hanging panel, which looked accidental.
    text, panel_count = remove_named_visual(text, GRAPHITE_VISUAL)

    # Replace any previous mounts as one block, otherwise insert into base_link.
    mount_pattern = re.compile(
        rf'\s*{re.escape(MOUNT_START)}.*?{re.escape(MOUNT_END)}\s*', re.S
    )
    text, old_mount_count = mount_pattern.subn('\n', text)
    insert_at = find_link_end(text, 'base_link')
    text = text[:insert_at] + '\n' + MOUNTS + '\n    ' + text[insert_at:]

    MODEL.write_text(text, encoding='utf-8')
    print(f'Updated: {MODEL}')
    print(f'Orange cover pose updated: {bool(cover_count)}')
    print(f'Cyan beacon pose updated: {bool(beacon_count)}')
    print(f'Graphite hanging panel removed: {bool(panel_count)}')
    print('Four visual-only graphite mounting posts installed.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
