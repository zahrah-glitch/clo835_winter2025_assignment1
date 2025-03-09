Create a local Kubernetes cluster with Kind.

Verify the node is ready:

kubectl get nodes

kubectl describe node assignment2-control-plane


Load Docker Images into Kind

kind load docker-image mysql:latest --name assignment2

kind load docker-image webapp:latest --name assignment2


Create Namespaces

kubectl apply -f namespace.yaml

kubectl get ns


Deploy MySQL Pod & Service

kubectl apply -f mysql-pod.yaml
kubectl get pods -n mysql-ns

kubectl apply -f mysql-service.yaml

kubectl get services -n mysql-ns

Deploy Web Application Pod

kubectl apply -f web-app-pod.yaml

kubectl get pods -n webapp-ns

# Forward port to access web app

kubectl port-forward -n webapp-ns pod/webapp-pod 8080:8080 --address 0.0.0.0 &

curl localhost:8080

Check logs to verify the app is running:

kubectl logs -n webapp-ns pod/webapp-pod

Deploy ReplicaSets

kubectl apply -f mysql-rs.yaml

kubectl get rs -n mysql-ns



kubectl apply -f web-app-rs.yaml

kubectl get rs -n webapp-ns

Note: If a pod already exists with the same label, the ReplicaSet will adopt it!
Create Deployments

kubectl apply -f mysql-deployment.yaml

kubectl get deployments -n mysql-ns


kubectl apply -f web-app-deployment.yaml

kubectl get deployments -n webapp-ns

Deployments automatically create and manage their own ReplicaSets, independent of the ones manually created earlier.


Expose Web Application with NodePort (30000)

kubectl apply -f web-app-service.yaml

kubectl get svc -n webapp-ns

Test the service:

curl localhost:30000

Or open the browser:

http://localhost:30000

Update Application & Rollout New Version

Change app title or make updates

Push the changes to GitHub

Pull the latest changes in your local environment

Build & Load the New Docker Image

docker build -t webapp:v2.0 .

docker images

kind load docker-image webapp:v2.0 --name assignment2

Update Deployment with New Image

kubectl set image deployment/webapp-deployment webapp-container=webapp:v2.0 -n webapp-ns --record

kubectl rollout status deployment.apps/webapp-deployment -n webapp-ns


Verify the Update

kubectl get pods -n webapp-ns -o custom-columns="NAME:.metadata.name,IMAGE:.spec.containers[*].image"

kubectl rollout history deployment/webapp-deployment -n webapp-ns

Test the Updated Application

Access the app in the browser:

http://localhost:30000

Or use curl:
curl localhost:30000
