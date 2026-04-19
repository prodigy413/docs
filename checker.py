import csv
import subprocess
import sys
import shutil
import os

# Variables
CSV_FILE = "users.csv"
REQUIRED_HEADER = ["firstname", "lastname", "username", "group"]
REQUIRED_CMDS = ["python3", "aws", "terraform"]


def run_aws_cmd(cmd):
    """Execute a subprocess command and return the result. Exit the script on error."""
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return res
    except Exception as e:
        print(f"Error: Command execution failed. {e}")
        sys.exit(1)


def main():
    # Check commands
    for cmd in REQUIRED_CMDS:
        if not shutil.which(cmd):
            print(f"Error: Command '{cmd}' not found in PATH.")
            sys.exit(1)

    # Check CSV file existence
    if not os.path.exists(CSV_FILE):
        print(f"Error: CSV file '{CSV_FILE}' not found.")
        sys.exit(1)

    # Retrieve Identity Store ID
    # Extract IdentityStoreId from AWS SSO Instance
    instance_res = run_aws_cmd([
        "aws", "sso-admin", "list-instances", 
        "--query", "Instances[0].IdentityStoreId", 
        "--output", "text"
    ])
    
    identity_store_id = instance_res.stdout.strip()
    if instance_res.returncode != 0 or not identity_store_id or identity_store_id == "None":
        print(f"Error: Failed to retrieve Identity Store ID. {instance_res.stderr.strip()}")
        sys.exit(1)

    # Read and check CSV
    with open(CSV_FILE, mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader, None)

        # Check header (order and names)
        if header != REQUIRED_HEADER:
            print(f"Error: CSV header must be exactly {REQUIRED_HEADER}")
            sys.exit(1)

        for row in reader:
            if not row: continue # Skip empty lines
            if len(row) != 4:
                print(f"Error: Invalid row format at {row}")
                sys.exit(1)

            firstname, lastname, username, group = row

            # Check for extra spaces
            for val in row:
                if val != val.strip():
                    print(f"Error: Extra spaces detected in value '{val}'")
                    sys.exit(1)

            # Check if group exists (error if not)
            group_filter = f'{{"UniqueAttribute":{{"AttributePath":"DisplayName","AttributeValue":"{group}"}}}}'
            group_res = run_aws_cmd([
                "aws", "identitystore", "get-group-id",
                "--identity-store-id", identity_store_id,
                "--alternate-identifier", group_filter
            ])
            if group_res.returncode != 0:
                print(f"Error: Group '{group}' does not exist in IAM Identity Center.")
                sys.exit(1)

            # Check if user exists (error if already exists)
            user_filter = f'{{"UniqueAttribute":{{"AttributePath":"UserName","AttributeValue":"{username}"}}}}'
            user_res = run_aws_cmd([
                "aws", "identitystore", "get-user-id",
                "--identity-store-id", identity_store_id,
                "--alternate-identifier", user_filter
            ])
            if user_res.returncode == 0:
                print(f"Error: User '{username}' already exists.")
                sys.exit(1)


if __name__ == "__main__":
    main()
