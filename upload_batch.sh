#!/bin/bash

cd /tmp/arch-scada-merged-upload
git config user.email "tim@plant.local"
git config user.name "Tim"

# Get all files from our master into a temp file (using local-master remote in THIS repo)
git ls-tree -r --name-only local-master/master > /tmp/all_files.txt
TOTAL=$(wc -l < /tmp/all_files.txt)
echo "Total files to upload: $TOTAL"

BATCH_SIZE=30
BATCH_NUM=0
START=1

while [ $START -le $TOTAL ]; do
  END=$((START + BATCH_SIZE - 1))
  if [ $END -gt $TOTAL ]; then
    END=$TOTAL
  fi
  
  BATCH_NUM=$((BATCH_NUM + 1))
  COUNT=$((END - START + 1))
  echo "=== Batch $BATCH_NUM: lines $START-$END ($COUNT files) ==="
  
  # Get the files for this batch
  BATCH_FILES=$(sed -n "${START},${END}p" /tmp/all_files.txt)
  
  # Checkout files from local-master/master
  echo "$BATCH_FILES" | xargs git checkout local-master/master -- 2>&1 | grep -v "^$" | head -5
  
  git add -A
  if git diff --cached --quiet; then
    echo "No changes in batch $BATCH_NUM, skipping"
    START=$((END + 1))
    continue
  fi
  
  git commit -m "chore: add files batch $BATCH_NUM" -q
  echo "Committed batch $BATCH_NUM"
  
  echo "Pushing batch $BATCH_NUM..."
  git push origin main 2>&1 | tail -5
  
  START=$((END + 1))
  sleep 1
done

echo "=== Done. All $TOTAL files uploaded in $BATCH_NUM batches ==="
