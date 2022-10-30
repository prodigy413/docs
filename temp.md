~~~
data "aws_cloudfront_cache_policy" "CachingOptimized" {
  name = "Managed-CachingOptimized"
}
data "aws_cloudfront_cache_policy" "CachingDisabled" {
  name = "Managed-CachingDisabled"
}

output "optimized_id" {
  value = data.aws_cloudfront_cache_policy.CachingOptimized.id
}

output "disabled_id" {
  value = data.aws_cloudfront_cache_policy.CachingDisabled.id
}
~~~
