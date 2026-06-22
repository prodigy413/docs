### Access AWS with CLI

- [Configuring IAM Identity Center authentication with the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [IAM Identity Center] > [Settings] > [Identity source]tab > Issuer URL
- https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72

```
$ aws configure sso
SSO session name (Recommended): my-sso
SSO start URL [None]: https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72
SSO region [None]: ap-northeast-1
SSO registration scopes [sso:account:access]: sso:account:access
Attempting to open your default browser.
If the browser does not open, open the following URL:

https://oidc.ap-northeast-1.amazonaws.com/authorize?response_type=code&client_id=6h6Hry2tfWPE5K6D9FS1a2FwLW5vcnRoZWFzdC0x&redirect_uri=http%3A%2F%2F127.0.0.1%3A38695%2Foauth%2Fcallback&state=550825fd-72f7-4e97-a547-f6c22564ac52&code_challenge_method=S256&scopes=sso%3Aaccount%3Aaccess&code_challenge=BIcVm1iBpkrJg1Tnmi-QhFg4AzSGWhFz3G5pn8Dreic
There are 2 AWS accounts available to you.
> Audit account, test01@great-obi.net (xxxxxxxx)
  Log Archive administrator, test02@great-obi.net (xxxxxxxxx)
Using the account ID xxxxxxxx
The only role available to you is: AWSAdministratorAccess
Using the role name "AWSAdministratorAccess"
Default client Region [None]: ap-northeast-1
CLI default output format (json if not specified) [None]: json
Profile name [AWSAdministratorAccess-xxxxxxxx]: audit
To use this profile, specify the profile name using --profile, as shown:

aws sts get-caller-identity --profile audit

$ aws configure sso
SSO session name (Recommended): my-sso
There are 2 AWS accounts available to you.
> Log Archive administrator, test02@great-obi.net (xxxxxxx)   
  Audit account, test01@great-obi.net (xxxxxxxxxx)    
Using the account ID xxxxxxxx
The only role available to you is: AWSAdministratorAccess
Using the role name "AWSAdministratorAccess"
Default client Region [None]: ap-northeast-1
CLI default output format (json if not specified) [None]: json
Profile name [AWSAdministratorAccess-xxxxxxxxx]: logs
To use this profile, specify the profile name using --profile, as shown:

aws sts get-caller-identity --profile logs

$ cat .aws/config 
[profile audit]
sso_session = my-sso
sso_account_id = xxxxxxx
sso_role_name = AWSAdministratorAccess
region = ap-northeast-1
output = json
[sso-session my-sso]
sso_start_url = https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72
sso_region = ap-northeast-1
sso_registration_scopes = sso:account:access
[profile logs]
sso_session = my-sso
sso_account_id = xxxxxxxxx
sso_role_name = AWSAdministratorAccess
region = ap-northeast-1
output = json

$ aws sso login --profile audit
Attempting to open your default browser.
If the browser does not open, open the following URL:

https://oidc.ap-northeast-1.amazonaws.com/authorize?response_type=code&client_id=6h6Hry2tfWPE5K6D9FS1a2FwLW5vcnRoZWFzdC0x&redirect_uri=http%3A%2F%2F127.0.0.1%3A40743%2Foauth%2Fcallback&state=3421aa14-1270-41bf-b7d0-71c9772f07a1&code_challenge_method=S256&scopes=sso%3Aaccount%3Aaccess&code_challenge=QG99SUhGiHfD5EV4I1J_-fic92envAPkSWnTUk4Lyok
Successfully logged into Start URL: https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72

$ aws s3 ls --profile audit
2026-03-20 20:50:56 aws-controltower-config-access-logs-424388263596-kpk-ykc
2026-03-20 20:51:14 aws-controltower-config-logs-424388263596-kpk-ykc

$ export AWS_PROFILE=audit

aws sso login --sso-session my-sso は

その sso-session の SSO access token を新しく取得・更新する
その sso-session を参照する全 profile が、そのログイン済みセッションを使える状態になる

$ aws sts get-caller-identity

aws sso logout

aws sso login --sso-session my-sso --use-device-code
