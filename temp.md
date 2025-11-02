~~~
ibmcloud account users -o json | jq '.[] | {User_ID: .userId, IBM_ID: .ibmUniqueId, Name: (.firstname + " " + .lastname)}'
~~~
