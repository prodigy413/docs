# Azure AD and cognito

<https://aws.amazon.com/blogs/security/how-to-set-up-amazon-cognito-for-federated-authentication-using-azure-ad/>
<https://qiita.com/kei1-dev/items/a0870c26da51dbaa6580>

### Cognito

- Amazon Cognito > [User pools] > [Create user pool]
- Check [Federated identity providers], [Email], [SAML] > [Next]
- In step5 Connect federated identity providers, click [Skip for now]
- Prepare information for Azure AD setup
 - Identifier (Entity ID) format: urn:amazon:cognito:sp:<yourUserPoolID>
 - ex) urn:amazon:cognito:sp:ap-southeast-2_nYYYyyYyYy
 - Reply URL: https://<yourDomainPrefix>.auth.<aws-region>.amazoncognito.com/saml2/idpresponse
 - ex) https://example-corp-prd.auth.ap-southeast-2.amazoncognito.com/saml2/idpresponse

### Azure AD

- Choose AD
- Choose [Enterprise applications]
- Choose [New application]
- Choose [Create your own application]
- Set name and choose [Integrate any other application you don't find in the gallery (Non-gallery)] > [Create]
- [Single sign-on] > [SAML]
- Basic SAML Configuration > [Edit] > use Identifier and eply URL > [Save]
- In the Attributes & Claims section, choose [Edit] > [Add a group claim]
- Select [Groups assigned to the application] > [Save]

### Cognito

- User pool > [Sign-in experience] > [Add identity provider]
- [SAML] > set provider name
- User pool attribute: email
- SAML attribute: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
