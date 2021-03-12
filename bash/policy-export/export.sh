# Make directory structure
mkdir -p {assignments,definitions,initiatives}

# List definitions
# az policy definition list --query [].id --output tsv
## Output could contain one of the following patterns:
## /providers/Microsoft.Authorization/policyDefinitions/[NAME]
## /subscriptions/[GUID]/providers/Microsoft.Authorization/policyDefinitions/[NAME]
## /providers/Microsoft.Management/managementGroups/[GUID]/providers/Microsoft.Authorization/policyDefinitions/[NAME]

# Export definitions
## Based on the above patterns, manipulate each string to run az policy definition show with the appropriate arguments
IFS=$'\t\n'
for i in $(az policy definition list --query [].id --output tsv); do
if [[ $i =~ ^\/providers\/Microsoft.Authorization\/policyDefinitions\/(.*) ]]
then
echo "`az policy definition show -n ${BASH_REMATCH[1]}`" > definitions/${BASH_REMATCH[1]};
elif [[ $i =~ ^/subscriptions/(.*)/providers/Microsoft.Authorization/policyDefinitions/(.*) ]]
then
echo "`az policy definition show -n ${BASH_REMATCH[2]} --subscription ${BASH_REMATCH[1]}`" > definitions/${BASH_REMATCH[2]};
elif [[ $i =~ ^/providers/Microsoft.Management/managementGroups/(.*)/providers/Microsoft.Authorization/policyDefinitions/(.*) ]]
then
echo "`az policy definition show -n ${BASH_REMATCH[2]} --management-group ${BASH_REMATCH[1]}`" > definitions/${BASH_REMATCH[2]};
fi
done

# List Initiatives
# az policy set-definition list --query [].id --output tsv

# Export Initiatives
IFS=$'\t\n'
for i in $(az policy set-definition list --query [].id --output tsv); do
if [[ $i =~ ^\/providers\/Microsoft.Authorization\/policySetDefinitions\/(.*) ]]
then
echo "`az policy set-definition show -n ${BASH_REMATCH[1]}`" > initiatives/${BASH_REMATCH[1]};
elif [[ $i =~ ^/subscriptions/(.*)/providers/Microsoft.Authorization/policySetDefinitions/(.*) ]]
then
echo "`az policy set-definition show -n ${BASH_REMATCH[2]} --subscription ${BASH_REMATCH[1]}`" > initiatives/${BASH_REMATCH[2]};
elif [[ $i =~ ^/providers/Microsoft.Management/managementGroups/(.*)/providers/Microsoft.Authorization/policySetDefinitions/(.*) ]]
then
echo "`az policy set-definition show -n ${BASH_REMATCH[2]} --management-group ${BASH_REMATCH[1]}`" > initiatives/${BASH_REMATCH[2]};
fi
done

# List Assignments
# az policy assignment list --disable-scope-strict-match --query [].name --output tsv

# Export Assignments
IFS=$'\t\n'
for i in $(az policy assignment list --disable-scope-strict-match --query '[].[name,scope]' | jq -c '.[]' | while read i; do echo ${i//[\[\]]/} | xargs echo; done); do
[[ $i =~ (.*),(.*) ]]
echo "`az policy assignment show -n ${BASH_REMATCH[1]} --scope ${BASH_REMATCH[2]}`" > assignments/${BASH_REMATCH[1]}
done

