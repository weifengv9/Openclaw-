# 模块二：用克隆声音做出一条完整短视频

请帮我做出一条可发布的短视频——配音、字幕、画面全部对齐。

## 前提

- 当前环境 .env 里已配置 MINIMAX_API_KEY
- 如果 .env 中有 VOICE_ID 就用克隆声音，没有就用 MiniMax 默认系统音色 `male-qn-qingse`
- 当前已有可用的 Remotion 视频项目
- 不要让我手动操作服务器，直接以"做出可发布的成品视频"为目标推进
- 能自动修复的问题先自动修复，只有无法解决时才来问我
- 如果 requests 库没装，先 `pip install requests` 再继续

## 输入

我会给你一段文案（300-500字的口播脚本）。如果我没给，你先帮我写一段45-60秒的口播脚本，要求：开头3秒必须抓人，口语化，结尾带互动引导。

## 执行流程

### Step 1：检查环境

```bash
cd ~/.openclaw/workspace/projects/video-pipeline 2>/dev/null || cd ~/.openclaw/workspace
source .env 2>/dev/null

echo "--- 环境检查 ---"
python3 --version
[ -n "$MINIMAX_API_KEY" ] && echo "✅ MINIMAX_API_KEY 已配置" || echo "❌ 缺少 MINIMAX_API_KEY"
[ -n "$VOICE_ID" ] && echo "✅ VOICE_ID: $VOICE_ID" || echo "⚠️ 未配置 VOICE_ID，将使用默认音色"
which ffmpeg >/dev/null 2>&1 && echo "✅ ffmpeg 可用" || echo "❌ 缺少 ffmpeg"
which npx >/dev/null 2>&1 && echo "✅ npx 可用" || echo "❌ 缺少 npx"
[ -f "package.json" ] && echo "✅ 项目目录存在" || echo "❌ 未找到 Remotion 项目"
[ -d "node_modules" ] && echo "✅ node_modules 已安装" || echo "⚠️ node_modules 缺失，需要先 npm install"

# 检查中文字体（封面需要）
ZHFONT=$(fc-list :lang=zh family 2>/dev/null | head -1)
[ -n "$ZHFONT" ] && echo "✅ 中文字体: $ZHFONT" || echo "⚠️ 未找到中文字体，封面可能乱码"

# 检查 Emoji 字体（视频画面中的大号 emoji 需要）
EMOJIFONT=$(fc-list | grep -i emoji | head -1)
[ -n "$EMOJIFONT" ] && echo "✅ Emoji 字体: $(echo $EMOJIFONT | cut -d: -f2)" || echo "⚠️ 未找到 Emoji 字体，视频中 emoji 会显示为方块"
```

如果缺少关键项，**自动修复**：
- node_modules 缺失 → 执行 `npm install`
- 中文字体缺失 → 执行 `apt-get install -y fonts-noto-cjk 2>/dev/null || yum install -y google-noto-cjk-fonts 2>/dev/null`，装完执行 `fc-cache -fv`
- **Emoji 字体缺失** → 执行 `apt-get install -y fonts-noto-color-emoji 2>/dev/null || yum install -y google-noto-emoji-color-fonts google-noto-emoji-fonts 2>/dev/null`，装完执行 `fc-cache -fv`。**这一步很重要**：Remotion 用 Chrome headless 渲染，如果系统没有 emoji 字体，所有 emoji 会渲染成打叉的方块。
- ffmpeg 缺失 → 执行 `apt-get install -y ffmpeg 2>/dev/null || yum install -y ffmpeg 2>/dev/null`

修复后重新检查，全部通过再继续。

### Step 2：确认文案

- 如果我给了文案，直接用
- 如果没给，先写3个选题让我选，然后写脚本
- 脚本要求：45-60秒（约300-400字），开头3秒必须抓人，口语化，结尾带互动引导

把最终脚本写入文件：

```bash
mkdir -p out
cat << 'EOF' > out/tts-input.txt
（最终确认的脚本内容）
EOF
```

### Step 3：逐句 TTS 生成配音 + 精确时间戳

**核心原理**：把脚本按标点切成短句，每句单独调 MiniMax TTS API，拿到每句的精确时长（毫秒级），拼接后字幕时间轴天然完美对齐。

```python
# 保存为 out/tts-generate.py 并执行：python3 out/tts-generate.py
import json, os, re, time
import requests

# 读配置
with open(".env") as f:
    env = {}
    for line in f:
        if "=" in line and not line.startswith("#"):
            k, v = line.strip().split("=", 1)
            env[k] = v

api_key = env.get("MINIMAX_API_KEY", "")
voice_id = env.get("VOICE_ID", "male-qn-qingse")

if not api_key:
    print("❌ 缺少 MINIMAX_API_KEY，请配置 .env")
    exit(1)

# 读脚本
with open("out/tts-input.txt") as f:
    text = f.read().strip()

# 按中文标点和换行切句
sentences = [s.strip() for s in re.split(r'[，。！？、；\n]+', text) if s.strip()]
print(f"🎙️ 共 {len(sentences)} 句，voice_id: {voice_id}，开始逐句生成...")

timestamps = []
current_time = 0.0
seg_files = []
tmpdir = "out/tts-segments"
os.makedirs(tmpdir, exist_ok=True)

for i, sent in enumerate(sentences):
    print(f"  [{i+1}/{len(sentences)}] {sent[:20]}...")

    payload = {
        "model": "speech-2.6-hd",
        "text": sent,
        "voice_setting": {"voice_id": voice_id, "speed": 1.15},
        "language_boost": "Chinese",
        "audio_setting": {"format": "mp3", "sample_rate": 32000}
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    # 带重试（限流、网络抖动）
    resp_data = None
    for attempt in range(5):
        try:
            resp = requests.post(
                "https://api.minimaxi.com/v1/t2a_v2",
                headers=headers, json=payload, timeout=30
            )
            resp_data = resp.json()
        except Exception as e:
            print(f"  ⚠️ 请求失败: {e}，{3*(attempt+1)}秒后重试...")
            time.sleep(3 * (attempt + 1))
            continue

        status = resp_data.get("base_resp", {}).get("status_code", -1)
        if status == 0:
            break
        elif status == 1002:  # 限流
            wait = 3 * (attempt + 1)
            print(f"  ⚠️ 限流，等待 {wait} 秒...")
            time.sleep(wait)
            continue
        else:
            print(f"  ❌ API错误: {resp_data.get('base_resp',{}).get('status_msg','未知')}")
            break
    else:
        print(f"  ❌ 第{i+1}句重试5次仍失败，跳过")
        continue

    if not resp_data or resp_data.get("base_resp", {}).get("status_code") != 0:
        continue

    # 保存音频片段（MiniMax 返回 hex 编码的音频）
    audio_hex = resp_data["data"]["audio"]
    seg_path = os.path.join(tmpdir, f"seg_{i:03d}.mp3")
    with open(seg_path, "wb") as f:
        f.write(bytes.fromhex(audio_hex))
    seg_files.append(seg_path)

    # 获取精确时长（毫秒）
    duration_ms = resp_data["extra_info"]["audio_length"]
    duration_s = duration_ms / 1000.0

    timestamps.append({
        "text": sent,
        "start": round(current_time, 3),
        "end": round(current_time + duration_s, 3),
        "duration": round(duration_s, 3)
    })
    current_time += duration_s

# 保存时间戳
with open("out/timestamps.json", "w") as f:
    json.dump(timestamps, f, ensure_ascii=False, indent=2)
print(f"✅ 时间戳已保存: out/timestamps.json (总时长 {current_time:.1f}s)")

# 生成 ffmpeg 拼接列表
with open(os.path.join(tmpdir, "concat.txt"), "w") as f:
    for seg in seg_files:
        f.write(f"file '{os.path.basename(seg)}'\n")

print(f"✅ 共生成 {len(seg_files)} 个音频片段，准备拼接")
```

拼接音频：

```bash
cd out/tts-segments && ffmpeg -y -f concat -safe 0 -i concat.txt -c copy ../narration.mp3 && cd ../..
echo "✅ 配音已生成: out/narration.mp3"
```

### Step 4：生成字幕数据

基于 timestamps.json 生成字幕数组。**关键**：先读一下你当前 Remotion 项目里已有的字幕数据文件（如果有的话），看看它的格式（字段名、数据结构），然后按相同格式生成。如果项目里没有已有字幕文件，就用下面的默认格式：

```python
# 保存为 out/gen-subtitles.py 并执行
import json, re

with open("out/timestamps.json") as f:
    timestamps = json.load(f)

FPS = 30

def clean_text(text):
    """去掉所有标点符号，字幕只显示纯文字"""
    text = re.sub(r'[，。！？、：；""''……——\.\!\?\,\:\;]', '', text)
    text = text.strip()
    return text

subtitles = []
for ts in timestamps:
    cleaned = clean_text(ts["text"])
    if not cleaned:
        continue
    subtitles.append({
        "text": cleaned,
        "startFrame": round(ts["start"] * FPS),
        "endFrame": round(ts["end"] * FPS)
    })

with open("src/data/subtitles.ts", "w") as f:
    f.write("export const subtitles = ")
    f.write(json.dumps(subtitles, ensure_ascii=False, indent=2))
    f.write(";\n")

print(f"✅ 字幕数据已生成: src/data/subtitles.ts ({len(subtitles)} 条)")
```

### Step 5：生成画面场景数据

基于时间戳生成场景数据。**关键**：先读一下你当前 Remotion 项目里 `src/data/` 目录下已有的场景数据文件，看它的字段名和数据结构，然后按相同格式生成新数据。如果项目里没有，就用下面的默认格式：

**关于 Emoji（重要）**：
- 每个场景都应该配一个与内容相关的 emoji，作为画面中的视觉装饰元素
- emoji 在视频中会被**放大到非常醒目的尺寸**（fontSize 400px，占画面宽度约 37%），居中显示在画面中央偏上的位置，带弹入动画
- 这不是小装饰，是视觉焦点——所以选 emoji 要选那种大号显示好看的、和内容强相关的
- emoji 是纯 Unicode 字符，Remotion 的 Chrome headless 会用系统 emoji 字体渲染（所以 Step 1 必须确保装了 emoji 字体）
- 在场景数据中用 `doodle` 字段存 emoji 字符

```python
# 保存为 out/gen-scenes.py 并执行
import json

with open("out/timestamps.json") as f:
    timestamps = json.load(f)

FPS = 30

# 深色配色轮换
COLORS = [
    {"bg": "#111318", "accent": "#00FF88"},
    {"bg": "#0D1117", "accent": "#58A6FF"},
    {"bg": "#1A0A2E", "accent": "#BD93F9"},
    {"bg": "#0F0F0F", "accent": "#FF6B6B"},
    {"bg": "#111318", "accent": "#FFD93D"},
]

# 为每个场景选一个跟内容相关的 emoji
# 这里用通用池轮换，实际生成时你应该根据每个场景的文字内容选更贴切的 emoji
EMOJI_POOL = ['🔥', '💡', '🚀', '🤖', '💰', '🎯', '⚡', '🧠', '📱', '✨',
              '💪', '🔧', '📊', '🎬', '🌟', '😱', '👀', '🎵', '📦', '🏆']

scenes = []
i = 0
scene_idx = 0
while i < len(timestamps):
    # 每3-5秒一个场景切换（约2-3句合并）
    group = []
    group_start = timestamps[i]["start"]
    while i < len(timestamps) and (timestamps[i]["end"] - group_start) < 5.0:
        group.append(timestamps[i])
        i += 1
    if not group:
        group = [timestamps[i]]
        i += 1

    start_time = group[0]["start"]
    end_time = group[-1]["end"]
    full_text = "".join([t["text"] for t in group])
    color = COLORS[scene_idx % len(COLORS)]

    scenes.append({
        "id": f"scene-{scene_idx+1}",
        "startFrame": round(start_time * FPS),
        "endFrame": round(end_time * FPS),
        "text": full_text,
        "doodle": EMOJI_POOL[scene_idx % len(EMOJI_POOL)],  # 大号 emoji 装饰
        "backgroundColor": color["bg"],
        "textColor": "#FFFFFF",
        "accentColor": color["accent"],
    })
    scene_idx += 1

with open("src/data/scenes-data.ts", "w") as f:
    f.write("export const scenes = ")
    f.write(json.dumps(scenes, ensure_ascii=False, indent=2))
    f.write(";\n")

total_frames = round(timestamps[-1]["end"] * FPS)
print(f"✅ 场景数据已生成: src/data/scenes-data.ts ({len(scenes)} 个场景, {total_frames} 帧)")
```

**生成后请检查**：每个场景的 `doodle` emoji 是否跟该场景的文字内容相关。如果不够贴切，手动替换成更合适的 emoji。好的 emoji 选择能显著提升视频的视觉吸引力。

### Step 6：复制音频到项目目录

```bash
mkdir -p public/audio
cp out/narration.mp3 public/audio/narration.mp3
echo "✅ 音频已复制到 public/audio/"
```

### Step 7：确保 Remotion Composition 正确

检查当前项目的 Remotion 入口文件（通常是 `src/Root.tsx` 或 `src/index.tsx`），确认：
1. 有一个 Composition 能渲染上面生成的数据
2. 宽度 1080，高度 1920（9:16 竖屏）
3. FPS 30
4. 总帧数 = timestamps.json 最后一条的 end 乘以 30（取整）

如果需要修改 Composition 的 durationInFrames 或注册新 Composition，自动完成。

记住当前可用的 Composition ID，后面渲染要用。

**关于 emoji 渲染**：检查 Remotion 组件代码，确认它能读取场景数据中的 `doodle` 字段并渲染 emoji。emoji 的显示要求：
- **fontSize 至少 300-400px**（占画面宽度 30-40%），这是视觉焦点不是小装饰
- 居中显示在画面中央偏上位置
- 如果组件还没有处理 `doodle` 字段的逻辑，需要在渲染组件中添加一个 `<div>` 来显示它，示例样式：`{ position: 'absolute', left: '50%', top: '35%', transform: 'translate(-50%, -50%)', fontSize: 400, zIndex: 15, filter: 'drop-shadow(4px 4px 8px rgba(0,0,0,0.3))' }`

### Step 8：渲染视频

```bash
# 先确认 TypeScript 编译通过
npx tsc --noEmit 2>&1 | head -20

# 获取当前 Composition ID（从上一步确认的）
COMP_ID="你确认的CompositionID"

# 渲染
NODE_OPTIONS='--max-old-space-size=4096' npx remotion render \
  "$COMP_ID" out/output.mp4 \
  --codec=h264 --concurrency=1 \
  --chrome-flags='--disable-dev-shm-usage --disable-gpu --no-sandbox'

echo "✅ 视频渲染完成: out/output.mp4"
```

**注意**：
- 如果你的 Remotion 版本需要指定入口文件，改成 `npx remotion render --entry-point src/index.ts "$COMP_ID" out/output.mp4 ...`
- tsc 编译错误 → 检查生成的 .ts 文件是否匹配项目类型定义，自动修复后重试
- 内存不够被 kill → 分段渲染：加 `--frames=0-999` 渲染前1000帧，再渲染剩余帧，最后用 ffmpeg 拼接
- 渲染前如果有残留 Chrome 进程占内存 → `pkill -f chrome-headless 2>/dev/null` 清理后重试

### Step 9：生成封面

用 ffmpeg 在深色背景上叠加大字标题。

**标题拆行规则**：
- 超过7个字的标题拆成2行
- 按语义拆，不要把一个词拆开（比如"人工智能"不能拆成"人工"和"智能"在不同行）
- 第一行白色，第二行绿色（#00FF88）
- 封面尺寸 1080×1920（和视频一致）

```bash
TITLE="视频标题"

# 找中文字体
FONT_FILE=$(fc-match "Noto Sans CJK SC:style=Bold" --format="%{file}\n" 2>/dev/null)
if [ -z "$FONT_FILE" ] || [ ! -f "$FONT_FILE" ]; then
  FONT_FILE=$(fc-list :lang=zh file | head -1 | tr -d ' ')
  FONT_FILE="${FONT_FILE%:}"
fi

if [ -z "$FONT_FILE" ] || [ ! -f "$FONT_FILE" ]; then
  echo "❌ 找不到中文字体文件，请先安装中文字体"
  echo "   Ubuntu/Debian: apt-get install -y fonts-noto-cjk"
  echo "   CentOS/RHEL:   yum install -y google-noto-cjk-fonts"
  exit 1
fi

echo "使用字体: $FONT_FILE"
```

用 Python 按语义拆行，再调 ffmpeg：

```python
import subprocess, sys

title = "视频标题"  # 替换
font_file = "上面拿到的字体路径"  # 替换

# 按语义拆行（不切断词）
if len(title) <= 7:
    line1, line2 = title, ""
else:
    # 尝试在中英文交界处拆
    best_split = len(title) // 2
    for i in range(max(2, best_split - 2), min(len(title) - 1, best_split + 3)):
        # 前后字符类型不同就是好的分割点
        c1 = title[i-1]
        c2 = title[i]
        if (ord(c1) < 128) != (ord(c2) < 128):
            best_split = i
            break
    line1 = title[:best_split]
    line2 = title[best_split:]

# ffmpeg 生成封面
filter_parts = [
    f"drawtext=fontfile='{font_file}':text='{line1}':fontcolor=white:fontsize=110:x=(w-tw)/2:y=700:shadowcolor=black:shadowx=3:shadowy=3"
]
if line2:
    filter_parts.append(
        f"drawtext=fontfile='{font_file}':text='{line2}':fontcolor=0x00FF88:fontsize=110:x=(w-tw)/2:y=850:shadowcolor=black:shadowx=3:shadowy=3"
    )
filter_str = ",".join(filter_parts)

cmd = f'ffmpeg -y -f lavfi -i "color=c=0x111318:s=1080x1920:d=1" -vframes 1 -vf "{filter_str}" out/cover.jpg'
subprocess.run(cmd, shell=True, check=True)
print("✅ 封面已生成: out/cover.jpg")
```

### Step 10：生成发布文案

基于最终脚本内容，生成：
- 3个可选标题（短、有冲击力、适合视频号/抖音）
- 1段简介（2-3句话）
- 5个标签（#开头）

### Step 11：最终返回

一次性返回：

- ✅ / ❌ 是否成功
- 📹 视频文件路径
- 🎨 封面图路径
- 📝 3个标题
- 📄 简介
- 🏷️ 5个标签
- ⏱️ 视频时长
- 🔊 使用的 voice_id
- 是否可以直接发布

## 执行要求

- 以"做出第一条视频"为最高优先级
- 能自动修复的问题先自动修复
- **生成数据前必须先读已有的数据文件看格式**：读 `src/data/` 目录下已有的 .ts 文件，看字段名和结构，按相同格式生成，确保 Remotion 组件能正确导入
- 每一步执行完直接继续下一步，不要停下来等我确认
- 不要回显完整的 API Key
- 字幕、画面、配音三者的时间轴必须对齐——因为是逐句 TTS 拿到精确时长，时间轴天然对齐
