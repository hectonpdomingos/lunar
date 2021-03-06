# audit_aws_access_keys
#
# AWS console defaults the checkbox for creating access keys to enabled.
# This results in many access keys being generated unnecessarily.
# In addition to unnecessary credentials, it also generates unnecessary
# management work in auditing and rotating these keys.
#
# Requiring that additional steps be taken by the user after their profile has
# been created will give a stronger indication of intent that access keys are
# [a] necessary for their work and [b] once the access key is established on an
# account, that the keys may be in use somewhere in the organization.
#
# Note: Even if it is known the user will need access keys, require them to
# create the keys themselves or put in a support ticket to have the created
# as a separate step from user creation.
# 
# Refer to Section(s) 1.23 Page(s) 66-7 CIS AWS Foundations Benchmark v1.1.0
#.

audit_aws_access_keys () {
  aws iam generate-credential-report 2>&1 > /dev/null
  entries=`aws iam get-credential-report --query 'Content' --output text | $base_d | cut -d, -f1,4,9,11,14,16 | sed '1 d' |grep -v '<root_account>' |awk -F '\n' '{print $1}'`
  for entry in $entries; do
    aws_user=`echo "$entry" |cut -d, -f1`
    key1_use=`echo "$entry" |cut -d, -f3`
    key1_last=`echo "$entry" |cut -d, -f4`
    key2_use=`echo "$entry" |cut -d, -f5`
    key2_last=`echo "$entry" |cut -d, -f6`
    total=`expr $total + 1`
    if [ "$key1_use" = "true" ] && [ "$key1_last" = "N/A" ]; then
      insecure=`expr $insecure + 1`
      echo "Warning:   Account $aws_user has key access enabled but has not used their AWS API credentials consider removing keys [$insecure Warnings]"
    else
      secure=`expr $secure + 1`
      echo "Secure:    Account $aws_user has key access enabled and has used their AWS API credentials [$secure Passes]"
    fi
    total=`expr $total + 1`
    if [ "$key2_use" = "true" ] && [ "$key2_last" = "N/A" ]; then
      insecure=`expr $insecure + 1`
      echo "Warning:   Account $aws_user has key access enabled but has not used their AWS API credentials consider removing keys [$insecure Warnings]"
    else
      secure=`expr $secure + 1`
      echo "Secure:    Account $aws_user has key access enabled and has used their AWS API credentials [$secure Passes]"
    fi
  done
}

