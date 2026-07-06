#!/usr/bin/env bash
# ------------------------------------------------------------------
# Deploy the Global View flight tracker to AWS — S3 + CloudFront.
#
#   ./deploy-aws.sh                 # first deploy (creates everything)
#   ./deploy-aws.sh my-bucket-name  # optional: choose the bucket name
#
# Re-running after you edit index.html re-uploads and refreshes the CDN.
# Cost: S3 stores one small file; CloudFront's always-free tier covers
# 1 TB/month of traffic — effectively $0 for personal use.
# ------------------------------------------------------------------
set -euo pipefail

BUCKET="${1:-}"
REGION="${AWS_REGION:-ap-southeast-1}"   # Singapore — closest mature region to Malaysia
HERE="$(cd "$(dirname "$0")" && pwd)"
FILE="$HERE/index.html"

command -v aws >/dev/null || { echo "AWS CLI not found. Install with:  brew install awscli   then run:  aws configure"; exit 1; }
aws sts get-caller-identity >/dev/null 2>&1 || { echo "No AWS credentials configured. Run:  aws configure"; exit 1; }
[ -f "$FILE" ] || { echo "index.html not found next to this script."; exit 1; }

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$BUCKET" ]; then
  BUCKET="global-view-tracker-${ACCOUNT_ID: -4}-$(date +%y%m%d)"
fi

echo "==> Bucket: $BUCKET  (region: $REGION)"
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" >/dev/null
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION" >/dev/null
  fi
  echo "    created"
fi

echo "==> Uploading index.html"
aws s3 cp "$FILE" "s3://$BUCKET/index.html" \
  --content-type "text/html; charset=utf-8" \
  --cache-control "public, max-age=300" >/dev/null

# Reuse the distribution if this script created one before
DIST_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Origins.Items[0].DomainName=='$BUCKET.s3.$REGION.amazonaws.com'].Id | [0]" \
  --output text 2>/dev/null || true)

if [ -n "$DIST_ID" ] && [ "$DIST_ID" != "None" ]; then
  echo "==> Reusing CloudFront distribution $DIST_ID — refreshing cache"
  aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*" >/dev/null
else
  echo "==> Creating CloudFront distribution (HTTPS — required for browser geolocation)"
  OAC_ID=$(aws cloudfront create-origin-access-control --origin-access-control-config \
    "Name=oac-$BUCKET,OriginAccessControlOriginType=s3,SigningBehavior=always,SigningProtocol=sigv4" \
    --query OriginAccessControl.Id --output text)

  CFG=$(mktemp)
  cat > "$CFG" <<JSON
{
  "CallerReference": "gv-$BUCKET-$(date +%s)",
  "Comment": "Global View flight tracker",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "PriceClass": "PriceClass_200",
  "Origins": { "Quantity": 1, "Items": [ {
    "Id": "s3origin",
    "DomainName": "$BUCKET.s3.$REGION.amazonaws.com",
    "OriginAccessControlId": "$OAC_ID",
    "S3OriginConfig": { "OriginAccessIdentity": "" }
  } ] },
  "DefaultCacheBehavior": {
    "TargetOriginId": "s3origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "Compress": true
  }
}
JSON
  DIST_ID=$(aws cloudfront create-distribution --distribution-config "file://$CFG" \
    --query 'Distribution.Id' --output text)
  rm -f "$CFG"

  echo "==> Granting CloudFront read access to the bucket"
  POLICY=$(mktemp)
  cat > "$POLICY" <<JSON
{ "Version": "2012-10-17", "Statement": [ {
  "Sid": "AllowCloudFrontRead",
  "Effect": "Allow",
  "Principal": { "Service": "cloudfront.amazonaws.com" },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::$BUCKET/*",
  "Condition": { "StringEquals": { "AWS:SourceArn": "arn:aws:cloudfront::$ACCOUNT_ID:distribution/$DIST_ID" } }
} ] }
JSON
  aws s3api put-bucket-policy --bucket "$BUCKET" --policy "file://$POLICY"
  rm -f "$POLICY"
fi

DOMAIN=$(aws cloudfront get-distribution --id "$DIST_ID" --query Distribution.DomainName --output text)
echo ""
echo "✅ Deployed:  https://$DOMAIN"
echo "   First deploy takes ~5–10 minutes to go live at the edge."
echo "   After editing index.html, just re-run this script."
