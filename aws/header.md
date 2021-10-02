### Apache httpd.conf

~~~conf
Header set X-XSS-Protection "1; mode=block"
Header set X-Content-Type-Options nosniff
Header append X-Frame-Options SAMEORIGIN
Header set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
~~~

### CloudFront Lambda@Edge
- CloudFrontのキャッシュにヒットしたときはViewer Responseが、キャッシュミスした場合はOrigin Responseが、それぞれトリガーとして動くようになっている
- Link<br>https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-cloudfront-trigger-events.html

~~~python
def lambda_handler(event, context):
    response = event['Records'][0]['cf']['response']

    if int(response['status']) == 200:
        response['headers']['strict-transport-security'] = [{'key': 'Strict-Transport-Security', 'value': 'max-age= 63072000; includeSubdomains; preload'}]
        response['headers']['x-content-type-options'] = [{'key': 'X-Content-Type-Options', 'value': 'nosniff'}]
        response['headers']['x-frame-options'] = [{'key': 'X-Frame-Options', 'value': 'SAMEORIGIN'}]
        response['headers']['x-xss-protection'] = [{'key': 'X-XSS-Protection', 'value': '1; mode=block'}]

    return response
~~~
