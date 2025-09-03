from valmut_model import AdmissionReview, AdmissionResponse
async def parse_request(request):
    import json
    from fastapi.responses import JSONResponse

    raw_request_data = None
    try:
        raw_request_data = await request.json()
    except json.JSONDecodeError:
        return JSONResponse(
            status_code=400,
            content={
                "apiVersion": "admission.k8s.io/v1",
                "kind": "AdmissionReview",
                "response": {"uid": "unknown", "allowed": False, "status": {"message": "Received request with invalid JSON body"}}
            }
        )

    admission_review: Optional[AdmissionReview] = None
    try:
        admission_review = AdmissionReview.model_validate(raw_request_data)
        return admission_review
    except ValidationError as e:
        uid_from_request = raw_request_data.get('request', {}).get('uid', 'unknown')
        error_message = f"Validation failed: {e.errors()[0].get('msg', 'Unknown validation error')}"

        error_response_content = AdmissionReview(
            response=AdmissionResponse(
                uid=uid_from_request,
                allowed=False,
                status={
                    "message": error_message,
                    "code": 400
                }
            )
        ).model_dump(by_alias=True, exclude_none=True)
        return JSONResponse(status_code=400, content=error_response_content)
        
def to_snake_case(camel_str: str) -> str:
    import re
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', camel_str) # split and insert _
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower() 

from typing import Any
def convert_keys_to_snake_case(data: Any) -> Any: # recursive!
    if isinstance(data, dict):
        return {to_snake_case(k): convert_keys_to_snake_case(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [convert_keys_to_snake_case(elem) for elem in data]
    else:
        return data
        

def get_configmap_data(configmap_name):
    from kubernetes import client, config
    def get_current_namespace():
        namespace_path = "/var/run/secrets/kubernetes.io/serviceaccount/namespace"
        if os.path.exists(namespace_path):
            with open(namespace_path, "r") as f:
                return f.read().strip()
        return None

    namespace = get_current_namespace()
    if not namespace:
        print("Could not determine the current namespace. Are you running in a Pod?")
        return None

    print(f"Running in namespace: {namespace}")

    try:
        # Load the Kubernetes configuration for in-cluster access.
        config.load_incluster_config()
    except config.ConfigException:
        print("Could not configure Kubernetes client for in-cluster access.")
        return None

    v1 = client.CoreV1Api()
    try:
        # Attempt to read the specific ConfigMap.
        configmap = v1.read_namespaced_config_map(name=configmap_name, namespace=namespace)

        print(f"Found ConfigMap: {configmap.metadata.name}")
        return configmap.data

    except client.ApiException as e:
        # Check if the error is a 404 Not Found.
        if e.status == 404:
            print(f"ConfigMap '{configmap_name}' not found.")
            return None
        else:
            # Re-raise or handle other API errors.
            print(f"An unexpected error occurred: {e}")
            raise

