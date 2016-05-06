#!/usr/bin/env bash

set -eu

S3KEY="$S3_UPLOADER_KEY_ID"
S3SECRET="$S3_UPLOADER_ACCESS_KEY"
BUCKET="$S3_BUCKET"


function putS3
{
  path=$1
  aws_path="/"
  date=$(date +"%a, %d %b %Y %T %z")
  acl="x-amz-acl:public-read"
  object_name="$2"
  string="PUT\n\n\n$date\n$acl\n/$BUCKET$aws_path$object_name"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
  curl -X PUT -T "$path" --fail \
    -H "Host: $BUCKET.s3.amazonaws.com" \
    -H "Date: $date" \
    -H "$acl" \
    -H "Authorization: AWS ${S3KEY}:$signature" \
    "https://$BUCKET.s3.amazonaws.com$aws_path$object_name"
}

deleteS3() {
  aws_path="/"
  date=$(date +"%a, %d %b %Y %T %z")
  object_name="$1"
  string="DELETE\n\n\n$date\n/$BUCKET$aws_path$object_name"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
  curl -i -X DELETE \
    -H "Host: $BUCKET.s3.amazonaws.com" \
    -H "Date: $date" \
    -H "Authorization: AWS ${S3KEY}:$signature" \
    "https://$BUCKET.s3.amazonaws.com$aws_path$object_name"
  echo "curl -i -X DELETE -H Host: $BUCKET.s3.amazonaws.com -H Date: $date -H Authorization: AWS ${S3KEY}:$signature https://$BUCKET.s3.amazonaws.com$aws_path$object_name"
}

function copyS3() {
  date=$(date +"%a, %d %b %Y %T %z")
  acl="x-amz-acl:public-read"
  src="$1"
  dst="$2"
  string="PUT\n\n\n$date\n$acl\nx-amz-copy-source:/$BUCKET/$src\n/$BUCKET/$dst"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
  curl -X PUT --fail \
    -H "Host: $BUCKET.s3.amazonaws.com" \
    -H "Date: $date" \
    -H "$acl" \
    -H "x-amz-copy-source: /$BUCKET/$src" \
    -H "Authorization: AWS ${S3KEY}:$signature" \
    "https://$BUCKET.s3.amazonaws.com/$dst"
}

case $1 in
  put)
    putS3 $2 $3
    ;;
  delete)
    deleteS3 $2
    ;;
  copy)
    copyS3 $2 $3
    ;;
  *)
    echo "Unknown command '$1'"
    exit 1
    ;;
esac

