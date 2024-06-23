~~~bash
#!/bin/bash

# File to check
file="test.csv"

# Read the header and verify
header=$(head -n 1 "$file")
expected_header="namespace,kind,name,replicas,restart,status_check"

if [[ "$header" != "$expected_header" ]]; then
  echo "Header does not match the expected header"
  exit 1
fi

# Read the data lines
tail -n +2 "$file" | while IFS=',' read -r namespace kind name replicas restart status_check; do
  # Skip commented lines
  [[ $namespace == \#* ]] && continue
  
  # Check the kind column
  if [[ "$kind" != "deployment" && "$kind" != "statefulset" ]]; then
    echo "Invalid kind in line: $namespace,$kind,$name,$replicas,$restart,$status_check"
    exit 1
  fi

  # Check the replicas column
  if ! [[ "$replicas" =~ ^[0-9]+$ ]]; then
    echo "Invalid replicas in line: $namespace,$kind,$name,$replicas,$restart,$status_check"
    exit 1
  fi

  # Check the restart column
  if [[ "$restart" != "true" && "$restart" != "false" ]]; then
    echo "Invalid restart in line: $namespace,$kind,$name,$replicas,$restart,$status_check"
    exit 1
  fi

  # Check the status_check column
  if [[ "$status_check" != "true" && "$status_check" != "false" ]]; then
    echo "Invalid status_check in line: $namespace,$kind,$name,$replicas,$restart,$status_check"
    exit 1
  fi
done

echo "CSV file passed all checks"
~~~
