set -e -v
STEPCERTPATH=$HOME/.step/certs
export STEP_PROVISIONER=${STEP_PROVISIONER:-"github-actions"}
export STEP_NOT_AFTER=${STEP_NOT_AFTER:-"1h"}
OIDC_CLIENT_ID=${OIDC_CLIENT_ID:-"api://SmallstepCAProvisioner"}

curl -LO https://dl.smallstep.com/cli/docs-cli-install/latest/step-cli_amd64.deb
sudo dpkg -i step-cli_amd64.deb
step ca bootstrap
TOKEN=$(curl -s -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=${OIDC_CLIENT_ID}" | jq -r .value)
curl -sLO https://token.actions.githubusercontent.com/.well-known/jwks
echo $TOKEN | step crypto jwt verify \
--jwks jwks \
--aud ${OIDC_CLIENT_ID} \
--iss "https://token.actions.githubusercontent.com"
SUBSCRIBER=$(echo $TOKEN | step crypto jwt inspect --insecure | jq -r .payload.sub)
mkdir -p ${STEPCERTPATH}
step ca certificate $SUBSCRIBER ${STEPCERTPATH}/my.crt ${STEPCERTPATH}/my.key --token "$TOKEN"
step certificate inspect ${STEPCERTPATH}/my.crt

CERTIFICATEAUTHORITY_BASE64=$(cat ${HOME}/.step/certs/root_ca.crt | base64 -w0)
CERTIFICATE_BASE64=$(cat ${STEPCERTPATH}/my.crt | base64 -w0)
PRIVATEKEY_BASE64=$(cat ${STEPCERTPATH}/my.key | base64 -w0)
mkdir -p $HOME/.kube
cat << EOF > $HOME/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CERTIFICATEAUTHORITY_BASE64}
    server: ${CLUSTER_URL}
name: ${CONTEXT}
contexts:
- context:
    cluster: ${CONTEXT}
    user: ${CONTEXT}
name: ${CONTEXT}
current-context: ${CONTEXT}
kind: Config
preferences: {}
users:
- name: ${CONTEXT}
user:
    client-certificate-data: ${CERTIFICATE_BASE64}
    client-key-data: ${PRIVATEKEY_BASE64}
EOF
