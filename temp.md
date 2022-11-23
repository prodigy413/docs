~~~
#!/bin/bash

groups=(

    )

roles=(

    )

policies=(

)

echo "##############################"
echo "IAM Group"
echo -e "##############################\n"
for group in ${groups[@]}; do
    echo -e "\n<< GroupName >>"
    echo ${group}
    echo -e "\n<< AttachedPolicy >>"
    aws iam list-attached-group-policies --query AttachedPolicies[].PolicyName --group-name ${group}
    echo "------------------------------------------------------------"
    echo "------------------------------------------------------------"
done

echo "##############################"
echo "IAM Role"
echo -e "##############################\n"
for role in ${roles[@]}; do
    echo -e "\n<< RoleName >>"
    echo ${role}
    echo -e "\n<< Description >>"
    aws iam get-role --query Role.Description --role-name ${role}
    echo -e "\n<< AssumeRole >>"
    aws iam get-role --query Role.AssumeRolePolicyDocument --role-name ${role}
    echo -e "\n<< AttachedPolicy >>"
    aws iam list-attached-role-policies --query AttachedPolicies[].PolicyName --role-name ${role}
    echo "------------------------------------------------------------"
    echo "------------------------------------------------------------"
done

echo "##############################"
echo "IAM Policy"
echo -e "##############################\n"
for policy in ${policies[@]}; do
    echo -e "\n<< PolicyName >>"
    echo ${policy}
    #polyicy_arn=$(aws iam list-policies --query Policies[].Arn | grep -i ${policy})
    polyicy_arn=$(aws iam list-policies --scope Local --output text --query 'Policies[?PolicyName==`'${policy}'`].Arn')
    # Remove quotations and commas
    #polyicy_arn="${polyicy_arn//[\",]}"
    echo -e "\n<< Description >>"
    aws iam get-policy --query Policy.Description --policy-arn ${polyicy_arn}
    echo -e "\n<< PolicyDocument >>"
    polyicy_version=$(aws iam get-policy --query Policy.DefaultVersionId --policy-arn ${polyicy_arn} --output text)
    aws iam get-policy-version --no-cli-pager --query PolicyVersion.Document --version-id ${polyicy_version} --policy-arn ${polyicy_arn}
    echo "------------------------------------------------------------"
    echo "------------------------------------------------------------"
done

~~~
