# Deploying Global View to AWS (cheapest setup)

The app is a single static `index.html` — flight data is fetched **directly by each
visitor's browser** from free, keyless APIs (airplanes.live + hexdb.io). So there is
**no backend to pay for**: no EC2, no Lambda, no database.

## Architecture

```
Visitor ──HTTPS──> CloudFront (CDN, free TLS) ──OAC──> S3 (private bucket, index.html)
   └──────────────> api.airplanes.live / hexdb.io  (live flight data, free)
```

CloudFront matters for two reasons: it gives you **HTTPS** (the browser Geolocation
API that centres the globe on your country only works on HTTPS), and its always-free
tier (1 TB traffic + 10M requests/month) means the site costs effectively nothing.

## One-time setup

```bash
brew install awscli          # install the AWS CLI
aws configure                # paste an access key for your AWS account
                             # region: ap-southeast-1 works well from Malaysia
```

## Deploy

```bash
cd "$HOME/Downloads/Earth "
./deploy-aws.sh
```

The script prints your site URL (`https://xxxxx.cloudfront.net`). The first deploy
takes ~5–10 minutes to propagate; after that, edits go live by re-running the same
script (it re-uploads and invalidates the CDN cache).

## Monthly cost

| Item | Cost |
|---|---|
| S3 storage (one ~90 KB file) | < $0.01 |
| S3 requests | < $0.01 (CloudFront caches) |
| CloudFront traffic/requests | $0 within the always-free tier |
| TLS certificate (`*.cloudfront.net`) | $0 |
| **Total** | **≈ $0 – 0.02 / month** |

Optional: a custom domain adds a Route 53 hosted zone ($0.50/month) plus a free ACM
certificate — say the word and the script can be extended for it.

## Tear down

```bash
# disable + delete the distribution (get the ID from the AWS console or the script output)
aws cloudfront get-distribution-config --id DIST_ID          # note the ETag, set Enabled=false, update, wait, then:
aws cloudfront delete-distribution --id DIST_ID --if-match ETAG
aws s3 rb s3://YOUR_BUCKET --force
```

## Notes

- airplanes.live asks heavy users to be reasonable (~1 request/second). The app polls
  once per 8 s for a tracked flight and once per 12 s for area traffic — well within
  that, and each **visitor** makes their own requests, so there's nothing to proxy.
- If the site ever gets big traffic, the next step would be a tiny CloudFront
  Function or Lambda@Edge proxy with shared caching of the ADS-B responses — not
  needed at personal scale, and it would add cost.
