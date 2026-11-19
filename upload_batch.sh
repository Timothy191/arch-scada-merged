#!/bin/bash

cd /tmp/arch-scada-merged-upload
git config user.email "tim@plant.local"
git config user.name "Tim"

# Get the starting point - how many files already committed
ALREADY=$(git ls-tree -r --name-only HEAD | wc -l)
echo "Already committed: $ALREADY files"

# Get all files from our master
git ls-tree -r --name-only local-master/master > /tmp/all_files.txt
TOTAL=$(wc -l < /tmp/all_files.txt)
echo "Total files to upload: $TOTAL"

BATCH_SIZE=100
BATCH_NUM=0
START=$((ALREADY + 1))

while [ $START -le $TOTAL ]; do
  END=$((START + BATCH_SIZE - 1))
  if [ $END -gt $TOTAL ]; then
    END=$TOTAL
  fi
  
  BATCH_NUM=$((BATCH_NUM + 1))
  COUNT=$((END - START + 1))
  echo "=== Batch $BATCH_NUM: lines $START-$END ($COUNT files) ==="
  
  BATCH_FILES=$(sed -n "${START},${END}p" /tmp/all_files.txt)
  
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
  git push origin main 2>&1 | tail -3
  
  START=$((END + 1))
  sleep 1
done

echo "=== Done. All $TOTAL files uploaded in $BATCH_NUM batches ==="
