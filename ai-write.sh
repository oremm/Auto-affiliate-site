#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

export OPENAI_API_KEY=$(cat .secrets/openai_key)
export AMAZON_TAG=$(cat .secrets/amazon_tag)

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
   "messages": [
     {
       "role": "system",
"content": "Write a 600-word tech post about home networking, Wi-Fi, or gadgets. Include exactly 3 Amazon product links, and ALWAYS format them as full URLs in this exact form: https://www.amazon.com/dp/ASIN?tag='"$AMAZON_TAG"'. Do not use bare domains like www.amazon.com or amazon.com without https:// and do not use shorteners like amzn.to. Use markdown. Start with # title. Write in a natural human blogger voice and do not mention AI, ChatGPT, language models, or that this text is generated. At the end, add a line starting with DALL·E prompt: followed by a single-line prompt for an illustration.",
     },
     {
       "role": "user",
       "content": "Write today'\''s post and image prompt."
     }
   ],
   "model": "gpt-4o-mini",
   "max_tokens": 1400
  }')

CONTENT=$(echo "$RESPONSE" | jq -r ".choices[0].message.content")

TITLE=$(echo "$CONTENT" | sed -n "1p" | sed "s/^# //")

SLUG=$(echo "$TITLE" \
  | tr "[:upper:]" "[:lower:]" \
  | tr -cd "a-z0-9 - " \
  | tr " " "-" \
  | tr -s "-" \
  | sed "s/^-//" | sed "s/-$//" \
  | cut -c1-50)

DATE=$(date +%Y-%m-%d)

POST=$(echo "$CONTENT" | sed "/DALL·E prompt:/,\$d")
PROMPT=$(echo "$CONTENT" | sed -n "/DALL·E prompt:/,\$p" | tail -n +2)

POST_FILE="content/posts/${SLUG}-${DATE}.md"
echo "$POST" > "$POST_FILE"

IMAGE_URL=$(curl -s https://api.openai.com/v1/images/generations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"dall-e-3\", \"prompt\": \"$PROMPT\", \"n\": 1, \"size\": \"1024x1024\"}" \
  | jq -r ".data[0].url")

echo "" >> "$POST_FILE"
echo "![${TITLE}](${IMAGE_URL})" >> "$POST_FILE"

echo "Generated: ${SLUG}-${DATE}.md + image"

./build.sh
git add -A
git commit -m "Post + image: $TITLE" || echo "No changes to commit."
git push
echo "Daily post + image published!"
