# Create secret encryption key
az keyvault key create --hsm-name [hsm-name] --name sek \
--kty RSA-HSM --ops encrypt decrypt \
--protection hsm --size [key-size]

# Encrypt secret with HSM key
az keyvault key encrypt --hsm-name [hsm-name] --name sek \
--algorithm RSA-OAEP --data-type plaintext \
--value [plaintext_secret]

# Store secret in keyvault vault
az keyvault secret set --name [secret-name] \
--vault-name [vault-name] \
--encoding base64 \
--value [ciphertext from above]

# Retrieve secret from keyvault vault
az keyvault secret show --name [secret-name] \
--vault-name [vault-name] --query value --output tsv

# Decrypt secret using key from managed HSM
az keyvault key decrypt --hsm-name [hsm-name] --name sek \
--algorithm RSA-OAEP --data-type plaintext \
--value \
`az keyvault secret show --name [secret-name] \
--vault-name [vault-name] --query value --output tsv`

# Create new SEK
az keyvault key create --hsm-name [hsm-name] --name sek-alt \
--kty RSA-HSM --ops encrypt decrypt \
--protection hsm --size [key-size]

# Encrypt secret with new HSM key
az keyvault key encrypt --hsm-name [hsm-name] --name sek-alt \
--algorithm RSA-OAEP --data-type plaintext \
--value [another_plaintext_secret]

# Store secret in keyvault vault
az keyvault secret set --name [secret-name] \
--vault-name [vault-name] \
--encoding base64 \
--value \
`az keyvault key encrypt --hsm-name [hsm-name] --name sek-alt \
--algorithm RSA-OAEP --data-type plaintext \
--value [another_plaintext_secret] \
--query result --output tsv`

# Decrypt secret using key from managed HSM
az keyvault key decrypt --hsm-name [hsm-name] --name sek-alt \
--algorithm RSA-OAEP --data-type plaintext \
--value \
`az keyvault secret show --name [secret-name] \
--vault-name [vault-name] --query value --output tsv`

