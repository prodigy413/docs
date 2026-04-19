# Pythonスクリプトの実行 (事前チェック)
resource "terraform_data" "run_script" {
  provisioner "local-exec" {
    command = "python3 checker.py"
  }

  triggers_replace = {
    always_run = timestamp()
  }
}

# Variable
locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  user_data         = csvdecode(file("${path.module}/users.csv"))
}

# Retrieve existing group IDs
data "aws_identitystore_group" "this" {
  for_each          = { for u in local.user_data : u.group => u... }
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.key
    }
  }

  depends_on = [terraform_data.run_script]
}

# Create users
resource "aws_identitystore_user" "this" {
  for_each          = { for u in local.user_data : u.username => u }
  identity_store_id = local.identity_store_id

  display_name = "${each.value.firstname} ${each.value.lastname}"
  user_name    = each.value.username

  name {
    given_name  = each.value.firstname
    family_name = each.value.lastname
  }

  emails {
    primary = true
    value   = each.value.username
  }

  depends_on = [terraform_data.run_script]
}

# Assign users to groups
resource "aws_identitystore_group_membership" "this" {
  for_each          = { for u in local.user_data : u.username => u }
  identity_store_id = local.identity_store_id

  group_id  = data.aws_identitystore_group.this[each.value.group].id
  member_id = aws_identitystore_user.this[each.key].user_id

  depends_on = [terraform_data.run_script]
}

# Get user lists
resource "terraform_data" "verify_groups_sequentially" {
  depends_on = [aws_identitystore_group_membership.this]

  provisioner "local-exec" {
    command = <<EOT
      %{for g_name, g_obj in data.aws_identitystore_group.this~}
      echo "=========================================================="
      echo "GROUP: ${g_name}"
      echo "----------------------------------------------------------"

      # Get member IDs
      USER_IDS=$(aws identitystore list-group-memberships \
        --identity-store-id ${local.identity_store_id} \
        --group-id ${g_obj.id} \
        --query "GroupMemberships[].MemberId.UserId" \
        --output text)

      if [ -z "$USER_IDS" ] || [ "$USER_IDS" = "None" ]; then
        echo "No members found in this group."
      else
        echo "Users:"
        # Retrieve details of each user sequentially (order is preserved because of the loop in the shell)
        for id in $USER_IDS; do
          aws identitystore describe-user \
            --identity-store-id ${local.identity_store_id} \
            --user-id $id \
            --query "UserName" \
            --output text
        done
      fi

      echo "=========================================================="
      echo ""
      %{endfor~}
EOT
  }
}
