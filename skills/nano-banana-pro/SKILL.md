---
name: nano-banana-pro
description: Generate and edit images using Google Gemini's Nano Banana Pro model. Use whenever assets are needed — game sprites, characters, landing page images, icons, illustrations, backgrounds, logos, marketing visuals, etc.
---

# Nano Banana Pro — Image Generation Skill

Generate production-quality images using Google's Gemini `gemini-3-pro-image-preview` model. This skill handles text-to-image generation, image editing, and multi-turn iterative refinement.

## When to Use

Use this skill whenever the user needs visual assets:
- Game assets (sprites, characters, items, backgrounds, tilesets)
- Landing page hero images, illustrations, section graphics
- Icons, logos, brand visuals
- Marketing materials (banners, social media graphics, posters)
- UI mockup assets, placeholder images
- Any image described in a prompt

## API Key

The API key must be set as the environment variable `GEMINI_API_KEY`.

If it's not set, ask the user to provide it:
```
export GEMINI_API_KEY="your-key-here"
```

## Image Storage

All generated images are saved to `/home/renas/nano-banana/`. This is the single source of truth for all generations.

**Directory structure:**
```
~/nano-banana/
├── characters/       # Named characters for consistency across generations
├── game-assets/      # Sprites, tilesets, items, backgrounds
├── marketing/        # Landing pages, banners, social media
├── icons/            # App icons, logos, brand marks
├── misc/             # Everything else
```

Always save to the appropriate subdirectory. Create it if it doesn't exist.

## Character Consistency

When generating a character that needs to appear consistently across multiple images:

1. **First generation:** Save the character image to `~/nano-banana/characters/<character-name>.png`
2. **Subsequent generations:** Before generating, check `~/nano-banana/characters/` for existing character images. If found, include the reference image in the API request (using the image editing flow) alongside the new prompt, so the model maintains visual consistency.
3. **Reference prompt pattern:** When referencing a character, prepend the prompt with: `"Use the provided reference image as the character. Maintain the same face, hair, clothing, and proportions. "` followed by the actual scene/pose description.

Always check `~/nano-banana/characters/` before generating any character-related image to see if a reference already exists.

## Workflow

### Step 1: Understand the Request

Determine from the user's request:
- **What** to generate (subject, style, mood)
- **Aspect ratio** — pick the best fit from: `1:1`, `3:4`, `4:3`, `9:16`, `16:9`, `21:9`
- **Resolution** — default to `2K`, use `4K` only when the user explicitly needs high-res
- **Output path** — save to the appropriate subdirectory under `~/nano-banana/`, or to a user-specified path if they provide one
- **Character references** — check `~/nano-banana/characters/` for any existing characters that should appear in this image

### Step 2: Craft the Prompt

Write a detailed, descriptive image generation prompt. Good prompts include:
- Subject and composition
- Art style (e.g., "pixel art", "watercolor", "3D render", "flat vector", "photorealistic")
- Color palette and lighting
- Mood and atmosphere
- Any text to render in the image

If the user's request is vague, enhance it with sensible creative defaults but stay true to their intent.

### Step 3: Generate the Image

Use `curl` via Bash to call the Gemini API:

```bash
curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{"parts": [{"text": "YOUR_PROMPT_HERE"}]}],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"],
      "imageConfig": {
        "aspectRatio": "ASPECT_RATIO",
        "imageSize": "RESOLUTION"
      }
    }
  }' \
  -o /tmp/gemini_response.json
```

### Step 4: Extract and Save the Image

Parse the response and save the base64-encoded image to a file:

```bash
python3 -c "
import json, base64, sys

with open('/tmp/gemini_response.json') as f:
    data = json.load(f)

parts = data['candidates'][0]['content']['parts']
for part in parts:
    if 'inlineData' in part:
        img_data = base64.b64decode(part['inlineData']['data'])
        with open('OUTPUT_PATH', 'wb') as img:
            img.write(img_data)
        print(f'Image saved to OUTPUT_PATH')
        break
    if 'inline_data' in part:
        img_data = base64.b64decode(part['inline_data']['data'])
        with open('OUTPUT_PATH', 'wb') as img:
            img.write(img_data)
        print(f'Image saved to OUTPUT_PATH')
        break
else:
    # No image found — print text parts for debugging
    for part in parts:
        if 'text' in part:
            print('API text response:', part['text'])
    sys.exit(1)
"
```

### Step 5: Show the Result

After saving, use the `Read` tool to display the image to the user. Then ask if they want adjustments.

## Image Editing (Modify an Existing Image)

To edit an existing image, include it as base64 in the request alongside a text prompt describing the edit:

```bash
python3 -c "
import json, base64

# Read source image
with open('SOURCE_IMAGE_PATH', 'rb') as f:
    img_b64 = base64.b64encode(f.read()).decode()

# Determine mime type
path = 'SOURCE_IMAGE_PATH'
mime = 'image/png' if path.endswith('.png') else 'image/jpeg' if path.endswith(('.jpg', '.jpeg')) else 'image/webp'

payload = {
    'contents': [{'parts': [
        {'inlineData': {'mimeType': mime, 'data': img_b64}},
        {'text': 'EDIT_PROMPT_HERE'}
    ]}],
    'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        'imageConfig': {
            'aspectRatio': 'ASPECT_RATIO',
            'imageSize': 'RESOLUTION'
        }
    }
}

with open('/tmp/gemini_request.json', 'w') as f:
    json.dump(payload, f)

print('Request payload written.')
"
```

Then send it:

```bash
curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @/tmp/gemini_request.json \
  -o /tmp/gemini_response.json
```

Then extract and save using the same Step 4 process.

## Aspect Ratio Guide

Pick the best aspect ratio based on use case:

| Use Case | Ratio |
|---|---|
| App icons, avatars, profile pics | `1:1` |
| Mobile screens, stories, portraits | `9:16` |
| Desktop hero images, banners | `16:9` |
| Ultrawide banners, cinematic | `21:9` |
| Posters, cards, product shots | `3:4` |
| Landscape photos, thumbnails | `4:3` |
| Game sprites, tiles | `1:1` |

## File Naming

Use descriptive, kebab-case filenames:
- `hero-astronaut-watercolor.png`
- `game-character-knight-idle.png`
- `landing-gradient-abstract.png`

Always use `.png` extension (the API returns PNG).

## Error Handling

- If the API returns an error, print the full response body for debugging.
- If the API key is rejected (401/403), inform the user it may need to be updated in the skill file.
- If the response has no image parts, print the text parts — the model may have refused the prompt due to safety filters. Inform the user and suggest rephrasing.
- If `curl` fails (network error), retry once before reporting.

## Multi-Turn Refinement

If the user wants to iterate on an image:
1. Re-read the previously generated image
2. Include it in a new request with the refinement prompt (use the image editing flow)
3. Save the result alongside or replacing the original

## Batch Generation

If the user needs multiple related assets (e.g., "generate 5 game item icons"), generate them sequentially, naming them with an index suffix: `item-sword-01.png`, `item-shield-02.png`, etc.

## Important Notes

- Always clean up temporary files (`/tmp/gemini_response.json`, `/tmp/gemini_request.json`) after extraction.
- The model supports accurate text rendering — use it for infographics, menus, diagrams.
- For game assets that need transparency, instruct the prompt to use "transparent background" or "on a solid color background" for easy removal.
- Default resolution is `2K` which balances quality and speed. Use `4K` only when asked.
