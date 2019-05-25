# 1. Create namespace for demo
kubectl create namespace webhook-example

# 2.1 Create key pair
# Service DNS discovery name is "mutate-server-svc.webhook-example.svc" 
openssl req -nodes -new -x509 -keyout ca.key -out ca.crt -subj "/CN=Admission Controller Webhook Demo CA"
openssl genrsa -out webhook-server-tls.key 2048
openssl req -new -key webhook-server-tls.key -subj "/CN=mutate-server-svc.webhook-example.svc" \
    | openssl x509 -req -CA ca.crt -CAkey ca.key -CAcreateserial -out webhook-server-tls.crt

# 2.2 Create TLS secret for service
kubectl -n webhook-example create secret tls webhook-certs \
    --cert "webhook-server-tls.crt" \
    --key "webhook-server-tls.key"

# 3. Create Mutator Server (Flask) as a Deployment and Service
kubectl apply -f deployment/webhook-mutate-deployment.yaml -n webhook-example

# 4. Register Mutator Server (Flask) as a Mutate Webhook to Kubernetes
export CA_PEM_BASE64="$(openssl base64 -A <"ca.crt")"
cat deployment/mutate-webhook-configuration.yaml | sed "s/{{CA_PEM_BASE64}}/$CA_PEM_BASE64/g" | kubectl apply -n webhook-example -f -

# 5. Clean files
rm -rf webhook-server-tls.* ca.*
