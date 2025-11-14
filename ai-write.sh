#!/usr/bin/env bash
cd "$(dirname "$0")"
export OPENAI_API_KEY=$(cat .secrets/openai_key)
export AMAZON_TAG=$(cat .secrets/amazon_tag)

# Generate post + image
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [
      {"role": "system", "content": "Write a 600-word tech post about home networking, Wi-Fi, or gadgets. Include 3 Amazon affiliate links using tag: '"$AMAZON_TAG"'. Use markdown. Start with # title. Then generate a DALL·E prompt for a featured image."},
      {"role": "user", "content": "Write today'\''s post and image prompt."}
    ],
    "max_tokens": 1400
  }')

TITLE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | sed -n '1p' | sed 's/^# //')
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -d '.' | tr ' ' '-' | cut -c1-50)
DATE=$(date +%Y-%m-%d)
POST=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | sed '/DALL·E prompt:/,$d')
PROMPT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | sed -n '/DALL·E prompt:/,$p' | tail -n +2)

echo "$POST" > "content/posts/$SLUG-$DATE.md"

# Generate image
IMAGE_URL=$(curl -s https://api.openai.com/v1/images/generations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"dall-e-3\", \"prompt\": \"$PROMPT\", \"n\": 1, \"size\": \"1024x1024\"}" | jq -r '.data[0].url')

echo "![$TITLE]($IMAGE_URL)" >> "content/posts/$SLUG-$DATE.md"

echo "Generated: $SLUG-$DATE.md + image"
./build.sh
git add -A
git commit -m "AI post + image: $TITLE"
git push
echo "Daily post + image published!"
