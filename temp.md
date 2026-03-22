```
AWS Direct Connectについて以下説明をお願いします。
- Transit VIFはAWS TGWを利用するときに必要なVIFですか。
- VPNを利用する場合はTGWが必要ですか。
- VPCが4つくらいの場合はTGWなしでDXGWだけでいいですか。
- AWS Direct ConnectはVIFやDXGWだけでなくオンプレからAWSへダイレクトアクセスする全体の構成を意味しますか。
```

```
$ aws configure sso
SSO session name (Recommended): my-sso
SSO start URL [None]: https://identitycenter.amazonaws.com/ssoins-24532523
SSO region [None]: ap-northeast-1
SSO registration scopes [sso:account:access]: sso:account:access
Attempting to open your default browser.
If the browser does not open, open the following URL:

https://oidc.ap-northeast-1.amazonaws.com/authorize?response_type=code&client_id=6h6Hry2tfWPE5K6D9FS123123123.0.0.1%3A38695%2Foauth%2Fcallback&state=550825fd-72f7-4e97-a547-f6c22564ac52&code_challenge_method=S256&sc123123123hallenge=BIcVm1iBpkrJg1Tnmi-QhFg4AzSGWhFz3G5pn8Dreic
There are 2 AWS accounts available to you.
> Audit account, test01@great-obi.net (1234)
  Log Archive administrator, test02@great-obi.net (5678)
Using the account ID 424388263596
The only role available to you is: AWSAdministratorAccess
Using the role name "AWSAdministratorAccess"
Default client Region [None]: ap-northeast-1
CLI default output format (json if not specified) [None]: json
Profile name [AWSAdministratorAccess-424388263596]: audit
To use this profile, specify the profile name using --profile, as shown:

aws sts get-caller-identity --profile audit

$ aws configure sso
SSO session name (Recommended): my-sso
There are 2 AWS accounts available to you.
> Log Archive administrator, test02@great-obi.net (1234)   
  Audit account, test01@great-obi.net (5678)    
Using the account ID 12334
The only role available to you is: AWSAdministratorAccess
Using the role name "AWSAdministratorAccess"
Default client Region [None]: ap-northeast-1
CLI default output format (json if not specified) [None]: json
Profile name [AWSAdministratorAccess-1234]: logs
To use this profile, specify the profile name using --profile, as shown:

aws sts get-caller-identity --profile logs

$ cat .aws/config 
[profile audit]
sso_session = my-sso
sso_account_id = 5678
sso_role_name = AWSAdministratorAccess
region = ap-northeast-1
output = json
[sso-session my-sso]
sso_start_url = https://identitycenter.amazonaws.com/ssoins-7dddddd
sso_region = ap-northeast-1
sso_registration_scopes = sso:account:access
[profile logs]
sso_session = my-sso
sso_account_id = 1234
sso_role_name = AWSAdministratorAccess
region = ap-northeast-1
output = json

$ aws sso login --profile audit
Attempting to open your default browser.
If the browser does not open, open the following URL:

https://oidc.ap-northeast-1.amazonaws.com/authorize?response_type=code&client_id=6h6Hry2tfWPE5K6D9FS1a2FwLW5vcnRoZWFzdC0x&redirect_uri=http%xxxxxxxxxxth%2Fcallback&state=3421aa14-1270-41bf-b7d0-71c9772f07a1&code_challenge_methoxxxxxxss&code_challenge=QG99SUhGiHfD5EV4I1J_-fic92envAPkSWnTUk4Lyok
Successfully logged into Start URL: https://identitycenter.amazonaws.com/ssoins-xxxxxxxx

$ aws s3 ls --profile audit
2026-03-20 20:50:56 aws-controltower-config-access-logs-1234-kpk-ykc
2026-03-20 20:51:14 aws-controltower-config-logs-1234-kpk-ykc

$ export AWS_PROFILE=audit

$ aws s3 ls
2026-03-20 20:50:56 aws-controltower-config-access-logs-41234-kpk-ykc
2026-03-20 20:51:14 aws-controltower-config-logs-1234-kpk-ykc

$ ls -l .aws/sso/cache/
total 8
-rw------- 1 aws-org aws-org 3675 Mar 21 22:07 0ad374308c5a4e22f723adf10145eafad7c4031c.json
-rw------- 1 aws-org aws-org 3110 Mar 21 21:57 9e5623eba43e9d2c21bc2e2007ab05a45be31847.json

$ cat .aws/sso/cache/0ad374308c5a4e22f723adf10145eafad7c4031c.json | jq '{expiresAt, registrationExpiresAt, startUrl, region}'
{
  "expiresAt": "2026-03-21T14:07:02Z",
  "registrationExpiresAt": "2026-06-19T12:57:43Z",
  "startUrl": "https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72",
  "region": "ap-northeast-1"
}

aws sso login --sso-session my-sso は

その sso-session の SSO access token を新しく取得・更新する
その sso-session を参照する全 profile が、そのログイン済みセッションを使える状態になる

aws sso logout
```
